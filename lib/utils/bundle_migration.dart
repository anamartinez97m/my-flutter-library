import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

/// Utility class to migrate old-style bundles to new architecture
class BundleMigration {
  /// Migrate all old-style bundles to new individual book system
  /// 
  /// This method:
  /// 1. Finds all bundles with old-style data (bundle_titles, bundle_pages, etc.)
  /// 2. Creates individual book records for each book in the bundle
  /// 3. Clears the old bundle fields
  /// 4. Preserves all existing data and relationships
  static Future<MigrationResult> migrateAllBundles() async {
    final result = MigrationResult();
    
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      
      // Find all old-style bundles
      final oldBundles = await db.rawQuery('''
        SELECT * FROM book 
        WHERE is_bundle = 1 
        AND (bundle_titles IS NOT NULL OR bundle_pages IS NOT NULL OR bundle_authors IS NOT NULL)
      ''');
      
      debugPrint('🔄 Found ${oldBundles.length} old-style bundles to migrate');
      result.totalBundles = oldBundles.length;
      
      for (var bundleMap in oldBundles) {
        try {
          final bundle = Book.fromMap(bundleMap);
          await _migrateSingleBundle(db, repository, bundle, result);
          result.successfulMigrations++;
        } catch (e) {
          debugPrint('❌ Error migrating bundle ${bundleMap['book_id']}: $e');
          result.failedMigrations++;
          result.errors.add('Bundle ${bundleMap['book_id']}: $e');
        }
      }
      
      debugPrint('✅ Migration complete: ${result.successfulMigrations} successful, ${result.failedMigrations} failed');
      
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      result.errors.add('Migration failed: $e');
    }
    
    return result;
  }
  
  /// Migrate a single bundle to new architecture
  static Future<void> _migrateSingleBundle(
    dynamic db,
    BookRepository repository,
    Book bundle,
    MigrationResult result,
  ) async {
    if (bundle.bookId == null) return;
    
    debugPrint('📚 Migrating bundle: ${bundle.name} (ID: ${bundle.bookId})');
    
    // Check if already migrated (has individual books)
    final existingBundleBooks = await repository.getBundleBooks(bundle.bookId!);
    if (existingBundleBooks.isNotEmpty) {
      debugPrint('⏭️  Bundle ${bundle.bookId} already migrated, skipping');
      result.skippedMigrations++;
      return;
    }
    
    // Parse old bundle data
    List<String?>? titles;
    List<String?>? authors;
    List<int?>? pages;
    List<int?>? years;
    List<String?>? sagaNumbers;
    
    // Parse titles
    if (bundle.bundleTitles != null && bundle.bundleTitles!.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(bundle.bundleTitles!);
        titles = parsed.map((t) => t as String?).toList();
      } catch (e) {
        debugPrint('⚠️  Error parsing titles: $e');
      }
    }
    
    // Parse authors
    if (bundle.bundleAuthors != null && bundle.bundleAuthors!.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(bundle.bundleAuthors!);
        authors = parsed.map((a) => a as String?).toList();
      } catch (e) {
        debugPrint('⚠️  Error parsing authors: $e');
      }
    }
    
    // Parse pages
    if (bundle.bundlePages != null && bundle.bundlePages!.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(bundle.bundlePages!);
        pages = parsed.map((p) => p as int?).toList();
      } catch (e) {
        debugPrint('⚠️  Error parsing pages: $e');
      }
    }
    
    // Parse publication years
    if (bundle.bundlePublicationYears != null && bundle.bundlePublicationYears!.isNotEmpty) {
      try {
        final List<dynamic> parsed = jsonDecode(bundle.bundlePublicationYears!);
        years = parsed.map((y) => y as int?).toList();
      } catch (e) {
        debugPrint('⚠️  Error parsing years: $e');
      }
    }
    
    // Parse saga numbers from bundleNumbers string
    if (bundle.bundleNumbers != null && bundle.bundleNumbers!.isNotEmpty) {
      sagaNumbers = _parseSagaNumbers(bundle.bundleNumbers!);
    }
    
    // Determine how many books to create
    final count = bundle.bundleCount ?? 
                  titles?.length ?? 
                  pages?.length ?? 
                  years?.length ?? 
                  0;
    
    if (count == 0) {
      debugPrint('⚠️  Bundle ${bundle.bookId} has no books, skipping');
      result.skippedMigrations++;
      return;
    }
    
    debugPrint('📖 Creating $count individual books for bundle ${bundle.bookId}');
    
    // Create individual books
    for (int i = 0; i < count; i++) {
      final individualBook = Book(
        bookId: null,
        name: (titles != null && i < titles.length && titles[i] != null && titles[i]!.isNotEmpty)
            ? titles[i]
            : 'Book ${i + 1}',
        isbn: null, // Individual books don't have ISBN
        asin: null,
        saga: bundle.saga,
        nSaga: (sagaNumbers != null && i < sagaNumbers.length) ? sagaNumbers[i] : null,
        sagaUniverse: bundle.sagaUniverse,
        pages: (pages != null && i < pages.length) ? pages[i] : null,
        originalPublicationYear: (years != null && i < years.length) ? years[i] : null,
        loaned: bundle.loaned,
        statusValue: 'No', // Default status for migrated books
        editorialValue: bundle.editorialValue,
        languageValue: bundle.languageValue,
        placeValue: bundle.placeValue,
        formatValue: bundle.formatValue,
        formatSagaValue: bundle.formatSagaValue,
        createdAt: DateTime.now().toIso8601String(),
        author: (authors != null && i < authors.length && authors[i] != null && authors[i]!.isNotEmpty)
            ? authors[i]
            : bundle.author,
        genre: bundle.genre,
        dateReadInitial: null,
        dateReadFinal: null,
        readCount: 0,
        myRating: null,
        myReview: null,
        isBundle: false, // Individual books are not bundles
        bundleCount: null,
        bundleNumbers: null,
        bundleStartDates: null,
        bundleEndDates: null,
        bundlePages: null,
        bundlePublicationYears: null,
        bundleTitles: null,
        bundleAuthors: null,
        tbr: false,
        isTandem: false,
        originalBookId: null,
        notificationEnabled: false,
        notificationDatetime: null,
        bundleParentId: bundle.bookId, // Link to parent bundle
      );
      
      final createdBookId = await repository.addBook(individualBook);
      result.individualBooksCreated++;
      debugPrint('  ✓ Created individual book: ${individualBook.name}');
      
      // Migrate reading sessions for this bundle book index
      await _migrateReadingSessions(db, bundle.bookId!, i, createdBookId);
    }
    
    // Clear old bundle fields from parent book
    await db.update(
      'book',
      {
        'bundle_titles': null,
        'bundle_authors': null,
        'bundle_pages': null,
        'bundle_publication_years': null,
        'bundle_numbers': null,
        'bundle_start_dates': null,
        'bundle_end_dates': null,
      },
      where: 'book_id = ?',
      whereArgs: [bundle.bookId],
    );
    
    // Delete ALL old bundle reading sessions from parent (they're now on individual books)
    await db.delete(
      'book_read_dates',
      where: 'book_id = ? AND bundle_book_index IS NOT NULL',
      whereArgs: [bundle.bookId],
    );
    
    debugPrint('✅ Bundle ${bundle.bookId} migrated successfully (with reading sessions)');
  }
  
  /// Migrate reading sessions from parent bundle to individual book
  static Future<void> _migrateReadingSessions(
    dynamic db,
    int parentBookId,
    int bundleIndex,
    int individualBookId,
  ) async {
    try {
      // Get all read_dates for this bundle book index
      final readDates = await db.query(
        'book_read_dates',
        where: 'book_id = ? AND bundle_book_index = ?',
        whereArgs: [parentBookId, bundleIndex],
      );
      
      if (readDates.isEmpty) {
        return;
      }
      
      debugPrint('    📅 Migrating ${readDates.length} reading session(s) for bundle book $bundleIndex');
      
      // Copy reading sessions to individual book
      for (final readDate in readDates) {
        await db.insert('book_read_dates', {
          'book_id': individualBookId,
          'date_started': readDate['date_started'],
          'date_finished': readDate['date_finished'],
          'bundle_book_index': null, // Individual books don't have bundle index
        });
      }
      
      // Delete old reading sessions from parent
      await db.delete(
        'book_read_dates',
        where: 'book_id = ? AND bundle_book_index = ?',
        whereArgs: [parentBookId, bundleIndex],
      );
      
      debugPrint('    ✓ Reading sessions migrated');
    } catch (e) {
      debugPrint('    ⚠️  Error migrating reading sessions: $e');
    }
  }
  
  /// Parse saga numbers from bundle numbers string
  static List<String?> _parseSagaNumbers(String numbersStr) {
    final List<String?> result = [];
    
    if (numbersStr.contains('-')) {
      // Range format: "1-3"
      final parts = numbersStr.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0].trim());
        final end = int.tryParse(parts[1].trim());
        if (start != null && end != null) {
          for (int i = start; i <= end; i++) {
            result.add(i.toString());
          }
        }
      }
    } else if (numbersStr.contains(',')) {
      // Comma-separated format: "1, 2, 3"
      final parts = numbersStr.split(',');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          result.add(trimmed);
        }
      }
    } else {
      // Single number
      result.add(numbersStr.trim());
    }
    
    return result;
  }
  
  /// Check if migration is needed
  static Future<bool> isMigrationNeeded() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM book 
        WHERE is_bundle = 1 
        AND (bundle_titles IS NOT NULL OR bundle_pages IS NOT NULL OR bundle_authors IS NOT NULL)
      ''');
      
      final count = result.first['count'] as int;
      return count > 0;
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      return false;
    }
  }
  
  /// Get migration statistics
  static Future<MigrationStats> getMigrationStats() async {
    final stats = MigrationStats();
    
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Count old-style bundles
      final oldBundles = await db.rawQuery('''
        SELECT COUNT(*) as count FROM book 
        WHERE is_bundle = 1 
        AND (bundle_titles IS NOT NULL OR bundle_pages IS NOT NULL OR bundle_authors IS NOT NULL)
      ''');
      stats.oldStyleBundles = oldBundles.first['count'] as int;
      
      // Count new-style bundles
      final newBundles = await db.rawQuery('''
        SELECT COUNT(*) as count FROM book 
        WHERE is_bundle = 1 
        AND bundle_titles IS NULL 
        AND bundle_pages IS NULL 
        AND bundle_authors IS NULL
      ''');
      stats.newStyleBundles = newBundles.first['count'] as int;
      
      // Count individual bundle books
      final individualBooks = await db.rawQuery('''
        SELECT COUNT(*) as count FROM book 
        WHERE bundle_parent_id IS NOT NULL
      ''');
      stats.individualBundleBooks = individualBooks.first['count'] as int;
      
    } catch (e) {
      debugPrint('Error getting migration stats: $e');
    }
    
    return stats;
  }
}

/// Result of migration operation
class MigrationResult {
  int totalBundles = 0;
  int successfulMigrations = 0;
  int failedMigrations = 0;
  int skippedMigrations = 0;
  int individualBooksCreated = 0;
  List<String> errors = [];
  
  bool get hasErrors => errors.isNotEmpty;
  bool get isComplete => totalBundles == (successfulMigrations + failedMigrations + skippedMigrations);
  
  @override
  String toString() {
    return '''
Migration Result:
  Total bundles: $totalBundles
  Successful: $successfulMigrations
  Failed: $failedMigrations
  Skipped: $skippedMigrations
  Individual books created: $individualBooksCreated
  Errors: ${errors.length}
''';
  }
}

/// Statistics about bundle migration status
class MigrationStats {
  int oldStyleBundles = 0;
  int newStyleBundles = 0;
  int individualBundleBooks = 0;
  
  bool get needsMigration => oldStyleBundles > 0;
  
  @override
  String toString() {
    return '''
Migration Statistics:
  Old-style bundles: $oldStyleBundles
  New-style bundles: $newStyleBundles
  Individual bundle books: $individualBundleBooks
  Migration needed: ${needsMigration ? 'Yes' : 'No'}
''';
  }
}
