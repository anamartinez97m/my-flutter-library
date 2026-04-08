import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backup frequency options for auto backup.
enum BackupFrequency { off, daily, weekly, monthly }

class BackupService {
  static final BackupService instance = BackupService._internal();
  BackupService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Cloud paths (manual single-shot backup, unchanged) ---
  String _manualBackupPath(String uid) => 'users/$uid/backups/my_library.db';
  String _manualMetadataPath(String uid) => 'users/$uid/backups/metadata.json';
  String _manualSettingsPath(String uid) => 'users/$uid/backups/settings.json';

  // --- Cloud paths (auto versioned backups) ---
  String _autoBackupDir(String uid) => 'users/$uid/auto_backups';
  String _autoBackupDbPath(String uid, String ts) =>
      'users/$uid/auto_backups/backup_$ts.db';
  String _autoBackupMetadataPath(String uid, String ts) =>
      'users/$uid/auto_backups/backup_${ts}_metadata.json';
  String _autoBackupSettingsPath(String uid, String ts) =>
      'users/$uid/auto_backups/backup_${ts}_settings.json';

  // SharedPreferences keys to include in backup
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
    // Auto backup
    'auto_backup_frequency',
    // Price settings
    'show_price_statistics',
    'currency_symbol',
    // Quick stats
    'quick_stats_keys',
  ];

  // SharedPreferences keys for auto backup
  static const String prefAutoBackupFrequency = 'auto_backup_frequency';
  static const String prefLastAutoBackupTimestamp =
      'last_auto_backup_timestamp';

  // Legacy key for migration
  static const String _legacyPrefAutoDailyBackup = 'auto_daily_backup_enabled';

  static const int _maxAutoBackups = 5;

  // =====================================================================
  // HELPERS
  // =====================================================================

  /// Get the local auto_backups directory.
  Future<Directory> _getLocalAutoBackupDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/auto_backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Generate a timestamp string safe for filenames.
  String _generateTimestamp() {
    return DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
  }

  /// Read the current backup frequency from SharedPreferences.
  /// Handles migration from the old bool key.
  Future<BackupFrequency> getBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();

    // Check new key first
    final freqStr = prefs.getString(prefAutoBackupFrequency);
    if (freqStr != null) {
      return _parseFrequency(freqStr);
    }

    // Migrate from old bool key
    final legacyEnabled = prefs.getBool(_legacyPrefAutoDailyBackup);
    if (legacyEnabled == true) {
      await prefs.setString(prefAutoBackupFrequency, 'daily');
      await prefs.remove(_legacyPrefAutoDailyBackup);
      return BackupFrequency.daily;
    }

    return BackupFrequency.off;
  }

  BackupFrequency _parseFrequency(String value) {
    switch (value) {
      case 'daily':
        return BackupFrequency.daily;
      case 'weekly':
        return BackupFrequency.weekly;
      case 'monthly':
        return BackupFrequency.monthly;
      default:
        return BackupFrequency.off;
    }
  }

  String frequencyToString(BackupFrequency freq) {
    switch (freq) {
      case BackupFrequency.off:
        return 'off';
      case BackupFrequency.daily:
        return 'daily';
      case BackupFrequency.weekly:
        return 'weekly';
      case BackupFrequency.monthly:
        return 'monthly';
    }
  }

  /// How many hours must pass before the next auto backup.
  int _frequencyHours(BackupFrequency freq) {
    switch (freq) {
      case BackupFrequency.off:
        return 0;
      case BackupFrequency.daily:
        return 24;
      case BackupFrequency.weekly:
        return 24 * 7;
      case BackupFrequency.monthly:
        return 24 * 30;
    }
  }

  /// Collect SharedPreferences into a JSON-encodable map.
  Future<Map<String, dynamic>> _collectSettings() async {
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
    return settings;
  }

  /// Restore SharedPreferences from a settings map.
  Future<void> _restoreSettings(Map<String, dynamic> settings) async {
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
  }

  /// Read the DB bytes by copying to a temp file (avoids closing the DB).
  Future<_DbSnapshot> _snapshotDatabase() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    final dbPath = db.path;

    // Get book count while DB is open
    final repository = BookRepository(db);
    final allBooks = await repository.getAllBooks();
    final bookCount = allBooks.length;

    // Copy to temp file so we read a consistent snapshot without closing DB
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/backup_snapshot_${DateTime.now().millisecondsSinceEpoch}.db';
    final tempFile = await File(dbPath).copy(tempPath);
    final bytes = await tempFile.readAsBytes();

    // Clean up temp
    try {
      await tempFile.delete();
    } catch (_) {}

    return _DbSnapshot(bytes: bytes, bookCount: bookCount);
  }

  /// Get the book count from the most recent local auto backup metadata.
  Future<int?> _getLastLocalBackupBookCount() async {
    try {
      final backupDir = await _getLocalAutoBackupDir();
      final metadataFiles = backupDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('_metadata.json'))
          .toList();

      if (metadataFiles.isEmpty) return null;

      // Sort by name (timestamps are sortable)
      metadataFiles.sort((a, b) => b.path.compareTo(a.path));

      final latest = metadataFiles.first;
      final jsonStr = await latest.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return data['bookCount'] as int?;
    } catch (e) {
      debugPrint('Error reading last local backup metadata: $e');
      return null;
    }
  }

  // =====================================================================
  // MANUAL CLOUD BACKUP (unchanged behavior, but no longer closes DB)
  // =====================================================================

  Future<bool> uploadBackup(String uid) async {
    try {
      final snapshot = await _snapshotDatabase();
      final bytes = snapshot.bytes;
      final bookCount = snapshot.bookCount;

      // Upload DB to Firebase Storage
      final ref = _storage.ref().child(_manualBackupPath(uid));
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
      final metadataRef = _storage.ref().child(_manualMetadataPath(uid));
      await metadataRef.putString(
        jsonEncode(metadata),
        metadata: SettableMetadata(contentType: 'application/json'),
      );

      // Upload settings JSON
      final settings = await _collectSettings();
      final settingsRef = _storage.ref().child(_manualSettingsPath(uid));
      await settingsRef.putString(
        jsonEncode(settings),
        metadata: SettableMetadata(contentType: 'application/json'),
      );

      debugPrint(
        'Cloud backup uploaded successfully ($bookCount books, ${bytes.length} bytes)',
      );
      return true;
    } catch (e) {
      debugPrint('Error uploading cloud backup: $e');
      return false;
    }
  }

  Future<bool> downloadBackup(String uid) async {
    try {
      // Check if backup exists
      final ref = _storage.ref().child(_manualBackupPath(uid));

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
      await _downloadCloudSettings(uid);

      debugPrint('Cloud backup restored successfully (${bytes.length} bytes)');
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('No cloud backup found for this user');
        return false;
      }
      debugPrint('Error downloading cloud backup: $e');
      try {
        await DatabaseHelper.instance.database;
      } catch (_) {}
      return false;
    } catch (e) {
      debugPrint('Error downloading cloud backup: $e');
      try {
        await DatabaseHelper.instance.database;
      } catch (_) {}
      return false;
    }
  }

  Future<Map<String, dynamic>?> getBackupMetadata(String uid) async {
    try {
      final ref = _storage.ref().child(_manualMetadataPath(uid));

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
      await _storage.ref().child(_manualBackupPath(uid)).delete();
      await _storage.ref().child(_manualMetadataPath(uid)).delete();
      try {
        await _storage.ref().child(_manualSettingsPath(uid)).delete();
      } catch (_) {}
      debugPrint('Cloud backup deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting cloud backup: $e');
      return false;
    }
  }

  /// Download and restore SharedPreferences from manual cloud backup.
  Future<void> _downloadCloudSettings(String uid) async {
    try {
      final ref = _storage.ref().child(_manualSettingsPath(uid));

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
      await _restoreSettings(settings);

      debugPrint('Settings restored successfully (${settings.length} keys)');
    } catch (e) {
      debugPrint('Error downloading settings: $e');
    }
  }

  // =====================================================================
  // AUTO BACKUP (local + cloud, versioned, with rotation)
  // =====================================================================

  /// Perform an automatic backup if enabled and enough time has passed.
  /// Runs in the background without blocking the UI.
  /// [uid] can be null if user is not signed in (local-only backup).
  Future<bool> performAutoBackupIfNeeded(String? uid) async {
    try {
      final freq = await getBackupFrequency();
      if (freq == BackupFrequency.off) {
        debugPrint('Auto backup: disabled');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastTimestamp = prefs.getString(prefLastAutoBackupTimestamp);
      if (lastTimestamp != null) {
        final lastBackup = DateTime.tryParse(lastTimestamp);
        if (lastBackup != null) {
          final hoursSince = DateTime.now().difference(lastBackup).inHours;
          final requiredHours = _frequencyHours(freq);
          if (hoursSince < requiredHours) {
            debugPrint(
              'Auto backup: skipped (last backup $hoursSince hours ago, need $requiredHours)',
            );
            return false;
          }
        }
      }

      debugPrint('Auto backup: starting...');
      final success = await _performAutoBackup(uid, force: false);
      if (success) {
        await prefs.setString(
          prefLastAutoBackupTimestamp,
          DateTime.now().toIso8601String(),
        );
        debugPrint('Auto backup: completed successfully');
      } else {
        debugPrint('Auto backup: failed or skipped');
      }
      return success;
    } catch (e) {
      debugPrint('Auto backup error: $e');
      return false;
    }
  }

  /// Force an immediate backup (local + cloud) regardless of frequency/timing.
  /// Used after "Delete Everything" to save the empty DB intentionally.
  /// [uid] can be null if user is not signed in (local-only backup).
  Future<bool> performBackupNow(String? uid) async {
    try {
      debugPrint('Forced backup: starting...');
      final success = await _performAutoBackup(uid, force: true);
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          prefLastAutoBackupTimestamp,
          DateTime.now().toIso8601String(),
        );
        debugPrint('Forced backup: completed successfully');
      }
      return success;
    } catch (e) {
      debugPrint('Forced backup error: $e');
      return false;
    }
  }

  /// Core auto backup logic: saves to local + cloud (if uid provided).
  /// [force] bypasses the empty-backup protection.
  Future<bool> _performAutoBackup(String? uid, {required bool force}) async {
    try {
      final snapshot = await _snapshotDatabase();
      final bytes = snapshot.bytes;
      final bookCount = snapshot.bookCount;

      // Empty backup protection (unless forced)
      if (!force && bookCount == 0) {
        final lastCount = await _getLastLocalBackupBookCount();
        if (lastCount != null && lastCount > 0) {
          debugPrint(
            'Auto backup: SKIPPED — previous backup had $lastCount books but current DB is empty',
          );
          return false;
        }
      }

      final ts = _generateTimestamp();
      final settings = await _collectSettings();
      final metadataMap = {
        'timestamp': DateTime.now().toIso8601String(),
        'dbVersion': 37,
        'bookCount': bookCount,
        'sizeBytes': bytes.length,
      };
      final metadataJson = jsonEncode(metadataMap);
      final settingsJson = jsonEncode(settings);

      // --- Save locally (always) ---
      await _saveLocalAutoBackup(ts, bytes, metadataJson, settingsJson);
      await _rotateLocalBackups();

      // --- Save to cloud (if signed in) ---
      if (uid != null) {
        await _saveCloudAutoBackup(uid, ts, bytes, metadataJson, settingsJson);
        await _rotateCloudBackups(uid);
      }

      debugPrint(
        'Auto backup saved: $bookCount books, ${bytes.length} bytes, ts=$ts',
      );
      return true;
    } catch (e) {
      debugPrint('Error performing auto backup: $e');
      return false;
    }
  }

  // --- Local auto backup ---

  Future<void> _saveLocalAutoBackup(
    String ts,
    Uint8List bytes,
    String metadataJson,
    String settingsJson,
  ) async {
    final dir = await _getLocalAutoBackupDir();
    await File('${dir.path}/backup_$ts.db').writeAsBytes(bytes, flush: true);
    await File('${dir.path}/backup_${ts}_metadata.json')
        .writeAsString(metadataJson, flush: true);
    await File('${dir.path}/backup_${ts}_settings.json')
        .writeAsString(settingsJson, flush: true);
    debugPrint('Local auto backup saved: backup_$ts');
  }

  Future<void> _rotateLocalBackups() async {
    try {
      final dir = await _getLocalAutoBackupDir();
      final dbFiles = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db'))
          .toList();

      if (dbFiles.length <= _maxAutoBackups) return;

      // Sort ascending by name (oldest first)
      dbFiles.sort((a, b) => a.path.compareTo(b.path));

      final toRemove = dbFiles.length - _maxAutoBackups;
      for (var i = 0; i < toRemove; i++) {
        final dbFile = dbFiles[i];
        final baseName =
            dbFile.path.replaceAll('.db', '');
        await dbFile.delete();
        try {
          await File('${baseName}_metadata.json').delete();
        } catch (_) {}
        try {
          await File('${baseName}_settings.json').delete();
        } catch (_) {}
        debugPrint('Rotated out local backup: ${dbFile.path}');
      }
    } catch (e) {
      debugPrint('Error rotating local backups: $e');
    }
  }

  // --- Cloud auto backup ---

  Future<void> _saveCloudAutoBackup(
    String uid,
    String ts,
    Uint8List bytes,
    String metadataJson,
    String settingsJson,
  ) async {
    final dbRef = _storage.ref().child(_autoBackupDbPath(uid, ts));
    await dbRef.putData(
      bytes,
      SettableMetadata(contentType: 'application/x-sqlite3'),
    );

    final metaRef = _storage.ref().child(_autoBackupMetadataPath(uid, ts));
    await metaRef.putString(
      metadataJson,
      metadata: SettableMetadata(contentType: 'application/json'),
    );

    final settingsRef = _storage.ref().child(_autoBackupSettingsPath(uid, ts));
    await settingsRef.putString(
      settingsJson,
      metadata: SettableMetadata(contentType: 'application/json'),
    );

    debugPrint('Cloud auto backup saved: backup_$ts');
  }

  Future<void> _rotateCloudBackups(String uid) async {
    try {
      final dirRef = _storage.ref().child(_autoBackupDir(uid));
      final result = await dirRef.listAll();

      // Find all .db files
      final dbItems = result.items
          .where((item) => item.name.endsWith('.db'))
          .toList();

      if (dbItems.length <= _maxAutoBackups) return;

      // Sort ascending by name (oldest first)
      dbItems.sort((a, b) => a.name.compareTo(b.name));

      final toRemove = dbItems.length - _maxAutoBackups;
      for (var i = 0; i < toRemove; i++) {
        final dbItem = dbItems[i];
        final baseName = dbItem.name.replaceAll('.db', '');
        await dbItem.delete();
        try {
          await _storage
              .ref()
              .child('${_autoBackupDir(uid)}/${baseName}_metadata.json')
              .delete();
        } catch (_) {}
        try {
          await _storage
              .ref()
              .child('${_autoBackupDir(uid)}/${baseName}_settings.json')
              .delete();
        } catch (_) {}
        debugPrint('Rotated out cloud backup: ${dbItem.name}');
      }
    } catch (e) {
      debugPrint('Error rotating cloud backups: $e');
    }
  }
}

/// Internal helper to hold a DB snapshot.
class _DbSnapshot {
  final Uint8List bytes;
  final int bookCount;
  _DbSnapshot({required this.bytes, required this.bookCount});
}
