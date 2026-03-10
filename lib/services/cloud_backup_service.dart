import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudBackupService {
  static final CloudBackupService instance = CloudBackupService._internal();
  CloudBackupService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _backupPath(String uid) => 'users/$uid/backups/my_library.db';
  String _metadataPath(String uid) => 'users/$uid/backups/metadata.json';
  String _settingsPath(String uid) => 'users/$uid/backups/settings.json';

  // SharedPreferences keys to include in cloud backup
  static const List<String> _settingsKeys = [
    // Theme
    'theme_mode',
    'light_theme_variant',
    'dark_theme_variant',
    'custom_light_primary',
    'custom_light_secondary',
    'custom_light_tertiary',
    'custom_dark_primary',
    'custom_dark_secondary',
    'custom_dark_tertiary',
    // Language
    'language_code',
    // Sort
    'default_sort_by',
    'default_sort_ascending',
    // TBR limit
    'tbr_limit',
    // Home filters & card fields
    'enabled_filters',
    'enabled_card_fields',
    // Reading reminders
    'reading_reminder_enabled',
    'reading_reminder_hour',
    'reading_reminder_minute',
    'reading_reminder_all_books',
  ];

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

      // Upload settings JSON
      await _uploadSettings(uid);

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

      // Restore settings from cloud
      await _downloadSettings(uid);

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
      // Also delete settings file
      try {
        await _storage.ref().child(_settingsPath(uid)).delete();
      } catch (_) {
        // Settings file may not exist for older backups
      }
      debugPrint('Cloud backup deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting cloud backup: $e');
      return false;
    }
  }

  /// Collect relevant SharedPreferences and upload as JSON
  Future<void> _uploadSettings(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> settings = {};

      for (final key in _settingsKeys) {
        final value = prefs.get(key);
        if (value != null) {
          if (value is List<String>) {
            settings[key] = {'type': 'StringList', 'value': value};
          } else if (value is bool) {
            settings[key] = {'type': 'bool', 'value': value};
          } else if (value is int) {
            settings[key] = {'type': 'int', 'value': value};
          } else if (value is double) {
            settings[key] = {'type': 'double', 'value': value};
          } else if (value is String) {
            settings[key] = {'type': 'String', 'value': value};
          }
        }
      }

      final settingsRef = _storage.ref().child(_settingsPath(uid));
      await settingsRef.putString(
        jsonEncode(settings),
        metadata: SettableMetadata(contentType: 'application/json'),
      );

      debugPrint('Settings uploaded successfully (${settings.length} keys)');
    } catch (e) {
      debugPrint('Error uploading settings: $e');
      // Non-fatal: backup still succeeds without settings
    }
  }

  /// Download and restore SharedPreferences from cloud JSON
  Future<void> _downloadSettings(String uid) async {
    try {
      final ref = _storage.ref().child(_settingsPath(uid));

      // Check if settings file exists
      try {
        await ref.getMetadata();
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found') {
          debugPrint('No cloud settings found (older backup)');
          return;
        }
        rethrow;
      }

      final bytes = await ref.getData();
      if (bytes == null || bytes.isEmpty) return;

      final jsonString = utf8.decode(bytes);
      final settings = jsonDecode(jsonString) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();

      for (final entry in settings.entries) {
        final key = entry.key;
        final data = entry.value as Map<String, dynamic>;
        final type = data['type'] as String;
        final value = data['value'];

        switch (type) {
          case 'String':
            await prefs.setString(key, value as String);
            break;
          case 'bool':
            await prefs.setBool(key, value as bool);
            break;
          case 'int':
            await prefs.setInt(key, value as int);
            break;
          case 'double':
            await prefs.setDouble(key, (value as num).toDouble());
            break;
          case 'StringList':
            await prefs.setStringList(
              key,
              (value as List<dynamic>).cast<String>(),
            );
            break;
        }
      }

      debugPrint('Settings restored successfully (${settings.length} keys)');
    } catch (e) {
      debugPrint('Error downloading settings: $e');
      // Non-fatal: restore still succeeds without settings
    }
  }
}
