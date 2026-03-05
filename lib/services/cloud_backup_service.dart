import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

class CloudBackupService {
  static final CloudBackupService instance = CloudBackupService._internal();
  CloudBackupService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _backupPath(String uid) => 'users/$uid/backups/my_library.db';
  String _metadataPath(String uid) => 'users/$uid/backups/metadata.json';

  Future<bool> uploadBackup(String uid) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final dbPath = db.path;

      // Get book count before closing
      final repository = BookRepository(db);
      final allBooks = await repository.getAllBooks();
      final bookCount = allBooks.length;

      // Close the database so the file is not locked
      await dbHelper.closeDatabase();

      // Read the .db file as bytes
      final dbFile = File(dbPath);
      final bytes = await dbFile.readAsBytes();

      // Upload to Firebase Storage
      final ref = _storage.ref().child(_backupPath(uid));
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'application/x-sqlite3'),
      );

      // Upload metadata JSON
      final metadata = {
        'timestamp': DateTime.now().toIso8601String(),
        'dbVersion': 37,
        'bookCount': bookCount,
        'sizeBytes': bytes.length,
      };
      final metadataRef = _storage.ref().child(_metadataPath(uid));
      await metadataRef.putString(
        jsonEncode(metadata),
        metadata: SettableMetadata(contentType: 'application/json'),
      );

      // Reopen the database
      await dbHelper.database;

      debugPrint(
        'Cloud backup uploaded successfully ($bookCount books, ${bytes.length} bytes)',
      );
      return true;
    } catch (e) {
      debugPrint('Error uploading cloud backup: $e');
      // Ensure database is reopened even on error
      try {
        await DatabaseHelper.instance.database;
      } catch (_) {}
      return false;
    }
  }

  Future<bool> downloadBackup(String uid) async {
    try {
      // Check if backup exists
      final ref = _storage.ref().child(_backupPath(uid));

      // Verify object exists before downloading to avoid noisy StorageException logs
      try {
        await ref.getMetadata();
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          debugPrint('No cloud backup found for this user');
          return false;
        }
        rethrow;
      }

      // Download the file bytes
      final bytes = await ref.getData();
      if (bytes == null || bytes.isEmpty) {
        debugPrint('Cloud backup: downloaded empty data');
        return false;
      }

      // Get current database path
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final dbPath = db.path;

      // Close the local database
      await dbHelper.closeDatabase();

      // Write downloaded bytes to the local database path (overwrite)
      final dbFile = File(dbPath);
      await dbFile.writeAsBytes(bytes, flush: true);

      // Reopen the database
      await dbHelper.database;

      debugPrint('Cloud backup restored successfully (${bytes.length} bytes)');
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('No cloud backup found for this user');
        return false;
      }
      debugPrint('Error downloading cloud backup: $e');
      // Ensure database is reopened even on error
      try {
        await DatabaseHelper.instance.database;
      } catch (_) {}
      return false;
    } catch (e) {
      debugPrint('Error downloading cloud backup: $e');
      // Ensure database is reopened even on error
      try {
        await DatabaseHelper.instance.database;
      } catch (_) {}
      return false;
    }
  }

  Future<Map<String, dynamic>?> getBackupMetadata(String uid) async {
    try {
      final ref = _storage.ref().child(_metadataPath(uid));

      // Verify object exists before downloading to avoid noisy StorageException logs
      try {
        await ref.getMetadata();
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          debugPrint('No cloud backup metadata found');
          return null;
        }
        rethrow;
      }

      final bytes = await ref.getData();
      if (bytes == null || bytes.isEmpty) return null;

      final jsonString = utf8.decode(bytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('No cloud backup metadata found');
        return null;
      }
      debugPrint('Error fetching backup metadata: $e');
      return null;
    } catch (e) {
      debugPrint('Error fetching backup metadata: $e');
      return null;
    }
  }

  Future<bool> deleteBackup(String uid) async {
    try {
      await _storage.ref().child(_backupPath(uid)).delete();
      await _storage.ref().child(_metadataPath(uid)).delete();
      debugPrint('Cloud backup deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting cloud backup: $e');
      return false;
    }
  }
}
