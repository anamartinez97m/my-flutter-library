import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

/// Utility class for migrating reading sessions from old bundle system to new individual books
class ReadingSessionMigration {
  /// Migrate all reading sessions from bundle parents to individual books
  static Future<MigrationResult> migrateAllReadingSessions() async {
    final result = MigrationResult();
    
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      
      // Find all bundles (both old and new style)
      final bundles = await db.query(
        'book',
        where: 'is_bundle = 1',
      );
      
      debugPrint('🔄 Found ${bundles.length} bundles to check for reading sessions');
      
      for (final bundleMap in bundles) {
        final bundleId = bundleMap['book_id'] as int;
        
        // Check if this bundle has old-style reading sessions
        final oldSessions = await db.query(
          'book_read_dates',
          where: 'book_id = ? AND bundle_book_index IS NOT NULL',
          whereArgs: [bundleId],
        );
        
        if (oldSessions.isEmpty) {
          debugPrint('  ⏭️  Bundle $bundleId has no old reading sessions to migrate');
          result.skippedBundles++;
          continue;
        }
        
        debugPrint('📚 Migrating reading sessions for bundle $bundleId (${oldSessions.length} sessions)');
        
        try {
          // Get individual books for this bundle
          final individualBooks = await repository.getBundleBooks(bundleId);
          
          if (individualBooks.isEmpty) {
            debugPrint('  ⚠️  Bundle $bundleId has no individual books - skipping');
            result.errors.add('Bundle $bundleId has old reading sessions but no individual books');
            result.failedBundles++;
            continue;
          }
          
          // Group old sessions by bundle_book_index
          final Map<int, List<Map<String, Object?>>> sessionsByIndex = {};
          for (final session in oldSessions) {
            final index = session['bundle_book_index'] as int;
            sessionsByIndex.putIfAbsent(index, () => []);
            sessionsByIndex[index]!.add(session);
          }
          
          // Migrate sessions to individual books
          int migratedCount = 0;
          for (final entry in sessionsByIndex.entries) {
            final index = entry.key;
            final sessions = entry.value;
            
            if (index >= individualBooks.length) {
              debugPrint('  ⚠️  Index $index out of range (${individualBooks.length} books)');
              continue;
            }
            
            final individualBook = individualBooks[index];
            debugPrint('  📖 Migrating ${sessions.length} session(s) for book ${index + 1}: ${individualBook.name}');
            
            for (final session in sessions) {
              // Copy session to individual book
              await db.insert('book_read_dates', {
                'book_id': individualBook.bookId,
                'date_started': session['date_started'],
                'date_finished': session['date_finished'],
                'bundle_book_index': null, // Individual books don't have bundle index
              });
              migratedCount++;
            }
          }
          
          // Delete old sessions from parent
          await db.delete(
            'book_read_dates',
            where: 'book_id = ? AND bundle_book_index IS NOT NULL',
            whereArgs: [bundleId],
          );
          
          debugPrint('  ✅ Migrated $migratedCount reading sessions for bundle $bundleId');
          result.successfulBundles++;
          result.totalSessionsMigrated += migratedCount;
          
        } catch (e) {
          debugPrint('  ❌ Error migrating bundle $bundleId: $e');
          result.errors.add('Bundle $bundleId: $e');
          result.failedBundles++;
        }
      }
      
      debugPrint('✅ Reading session migration complete!');
      debugPrint('   Successful: ${result.successfulBundles}');
      debugPrint('   Skipped: ${result.skippedBundles}');
      debugPrint('   Failed: ${result.failedBundles}');
      debugPrint('   Total sessions migrated: ${result.totalSessionsMigrated}');
      
    } catch (e) {
      debugPrint('❌ Fatal error during reading session migration: $e');
      result.errors.add('Fatal error: $e');
    }
    
    return result;
  }
  
  /// Check if there are any old-style reading sessions that need migration
  static Future<bool> needsMigration() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM book_read_dates 
        WHERE bundle_book_index IS NOT NULL
      ''');
      
      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      debugPrint('Error checking reading session migration status: $e');
      return false;
    }
  }
  
  /// Get statistics about reading sessions
  static Future<SessionStats> getStats() async {
    final stats = SessionStats();
    
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Count old-style sessions
      final oldSessions = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM book_read_dates 
        WHERE bundle_book_index IS NOT NULL
      ''');
      stats.oldStyleSessions = oldSessions.first['count'] as int;
      
      // Count bundles with old sessions
      final bundlesWithOldSessions = await db.rawQuery('''
        SELECT COUNT(DISTINCT book_id) as count 
        FROM book_read_dates 
        WHERE bundle_book_index IS NOT NULL
      ''');
      stats.bundlesWithOldSessions = bundlesWithOldSessions.first['count'] as int;
      
      // Count new-style sessions (on individual books)
      final newSessions = await db.rawQuery('''
        SELECT COUNT(*) as count 
        FROM book_read_dates rd
        JOIN book b ON rd.book_id = b.book_id
        WHERE b.bundle_parent_id IS NOT NULL
      ''');
      stats.newStyleSessions = newSessions.first['count'] as int;
      
    } catch (e) {
      debugPrint('Error getting reading session stats: $e');
    }
    
    return stats;
  }
}

/// Result of reading session migration
class MigrationResult {
  int successfulBundles = 0;
  int failedBundles = 0;
  int skippedBundles = 0;
  int totalSessionsMigrated = 0;
  List<String> errors = [];
  
  bool get hasErrors => errors.isNotEmpty;
  int get totalBundles => successfulBundles + failedBundles + skippedBundles;
}

/// Statistics about reading sessions
class SessionStats {
  int oldStyleSessions = 0;
  int bundlesWithOldSessions = 0;
  int newStyleSessions = 0;
  
  bool get needsMigration => oldStyleSessions > 0;
}
