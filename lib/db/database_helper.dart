import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathToDb = join(dbPath, 'my_library.db');

    return await openDatabase(
      pathToDb,
      version: 14,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create all tables matching the SQL script
    await db.execute('''
      CREATE TABLE IF NOT EXISTS status (
        status_id INTEGER PRIMARY KEY AUTOINCREMENT,
        value VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS author (
        author_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS editorial (
        editorial_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS genre (
        genre_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS language (
        language_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS place (
        place_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS format (
        format_id INTEGER PRIMARY KEY AUTOINCREMENT,
        value VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS format_saga (
        format_id INTEGER PRIMARY KEY AUTOINCREMENT,
        value VARCHAR(50) NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS book (
        book_id INTEGER PRIMARY KEY AUTOINCREMENT,
        status_id VARCHAR(50) NOT NULL,
        name VARCHAR(50) NOT NULL DEFAULT 'unknown',
        editorial_id VARCHAR(50),
        saga VARCHAR(50),
        n_saga VARCHAR(50),
        saga_universe VARCHAR(100),
        format_saga_id VARCHAR(50),
        isbn VARCHAR(50),
        asin VARCHAR(50),
        pages INTEGER,
        original_publication_year INTEGER,
        loaned BOOLEAN,
        language_id VARCHAR(50),
        place_id VARCHAR(50),
        format_id VARCHAR(50),
        created_at TEXT DEFAULT (datetime('now')),
        date_read_initial TEXT,
        date_read_final TEXT,
        read_count INTEGER DEFAULT 0,
        my_rating REAL,
        my_review TEXT,
        is_bundle BOOLEAN DEFAULT 0,
        bundle_count INTEGER,
        bundle_numbers TEXT,
        bundle_start_dates TEXT,
        bundle_end_dates TEXT,
        bundle_pages TEXT,
        bundle_publication_years TEXT,
        bundle_titles TEXT,
        tbr BOOLEAN DEFAULT 0,
        is_tandem BOOLEAN DEFAULT 0,
        original_book_id INTEGER,
        FOREIGN KEY (status_id) REFERENCES status (status_id),
        FOREIGN KEY (original_book_id) REFERENCES book (book_id) ON DELETE SET NULL,
        FOREIGN KEY (editorial_id) REFERENCES editorial (editorial_id),
        FOREIGN KEY (language_id) REFERENCES language (language_id),
        FOREIGN KEY (place_id) REFERENCES place (place_id),
        FOREIGN KEY (format_id) REFERENCES format (format_id),
        FOREIGN KEY (format_saga_id) REFERENCES format_saga (format_id)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_book_isbn ON book (isbn)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_book_asin ON book (asin)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS books_by_author (
        books_by_author_id INTEGER PRIMARY KEY,
        author_id INTEGER,
        book_id INTEGER,
        FOREIGN KEY (author_id) REFERENCES author (author_id),
        FOREIGN KEY (book_id) REFERENCES book (book_id),
        UNIQUE (author_id, book_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS books_by_genre (
        books_by_genre_id INTEGER PRIMARY KEY,
        genre_id INTEGER,
        book_id INTEGER,
        FOREIGN KEY (genre_id) REFERENCES genre (genre_id),
        FOREIGN KEY (book_id) REFERENCES book (book_id),
        UNIQUE (genre_id, book_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS book_read_dates (
        read_date_id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        date_started TEXT,
        date_finished TEXT,
        bundle_book_index INTEGER,
        FOREIGN KEY (book_id) REFERENCES book (book_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_book_read_dates_book_id ON book_read_dates (book_id)
    ''');

    // Insert default status values if table is empty
    final statusCount = await db.rawQuery('SELECT COUNT(*) as count FROM status');
    if (statusCount.first['count'] == 0) {
      await db.insert('status', {'value': 'No'});
      await db.insert('status', {'value': 'Yes'});
      await db.insert('status', {'value': 'Started'});
      await db.insert('status', {'value': 'TBReleased'});
    }
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute(
        'ALTER TABLE book ADD COLUMN date_read_initial TEXT',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN date_read_final TEXT',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN read_count INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN my_rating REAL',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN my_review TEXT',
      );
    }
    if (oldVersion < 3) {
      // Add bundle columns for version 3
      await db.execute(
        'ALTER TABLE book ADD COLUMN is_bundle BOOLEAN DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN bundle_count INTEGER',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN bundle_numbers TEXT',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN bundle_start_dates TEXT',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN bundle_end_dates TEXT',
      );
    }
    if (oldVersion < 4) {
      // Add bundle_pages column for version 4
      await db.execute(
        'ALTER TABLE book ADD COLUMN bundle_pages TEXT',
      );
    }
    if (oldVersion < 5) {
      // Add asin column for version 5
      await db.execute(
        'ALTER TABLE book ADD COLUMN asin VARCHAR(50)',
      );
      // Add index for asin
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_book_asin ON book (asin)',
      );
    }
    if (oldVersion < 6) {
      // Add saga_universe column for version 6
      await db.execute(
        'ALTER TABLE book ADD COLUMN saga_universe VARCHAR(100)',
      );
    }
    if (oldVersion < 7) {
      // Add tbr and is_tandem columns for version 7
      await db.execute(
        'ALTER TABLE book ADD COLUMN tbr BOOLEAN DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE book ADD COLUMN is_tandem BOOLEAN DEFAULT 0',
      );
    }
    if (oldVersion < 8) {
      // Add bundle_publication_years column for version 8
      await db.execute(
        'ALTER TABLE book ADD COLUMN bundle_publication_years TEXT',
      );
    }
    if (oldVersion < 9) {
      // Add bundle_titles column for version 9
      await db.execute(
        'ALTER TABLE book ADD COLUMN bundle_titles TEXT',
      );
    }
    if (oldVersion < 10) {
      // Create book_read_dates table for version 10
      await db.execute('''
        CREATE TABLE IF NOT EXISTS book_read_dates (
          read_date_id INTEGER PRIMARY KEY AUTOINCREMENT,
          book_id INTEGER NOT NULL,
          date_started TEXT,
          date_finished TEXT,
          FOREIGN KEY (book_id) REFERENCES book (book_id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_book_read_dates_book_id ON book_read_dates (book_id)
      ''');
      
      // Migrate existing date_read_initial and date_read_final to new table
      final booksWithDates = await db.rawQuery('''
        SELECT book_id, date_read_initial, date_read_final
        FROM book
        WHERE (date_read_initial IS NOT NULL AND date_read_initial != '')
           OR (date_read_final IS NOT NULL AND date_read_final != '')
      ''');
      
      for (final book in booksWithDates) {
        final bookId = book['book_id'] as int;
        final dateStarted = book['date_read_initial'] as String?;
        final dateFinished = book['date_read_final'] as String?;
        
        // Only insert if at least one date exists
        if ((dateStarted != null && dateStarted.isNotEmpty) ||
            (dateFinished != null && dateFinished.isNotEmpty)) {
          await db.insert('book_read_dates', {
            'book_id': bookId,
            'date_started': dateStarted,
            'date_finished': dateFinished,
          });
        }
      }
      
      // Note: We keep the old columns for now for backward compatibility
      // They can be removed in a future version after ensuring all data is migrated
    }
    if (oldVersion < 11) {
      // Add bundle_book_index column for version 11
      await db.execute(
        'ALTER TABLE book_read_dates ADD COLUMN bundle_book_index INTEGER',
      );
    }
    if (oldVersion < 12) {
      // Add original_book_id column for version 12 (repeated books)
      await db.execute(
        'ALTER TABLE book ADD COLUMN original_book_id INTEGER REFERENCES book(book_id) ON DELETE SET NULL',
      );
      
      // Add "Repeated" status if it doesn't exist
      final repeatedExists = await db.rawQuery(
        "SELECT COUNT(*) as count FROM status WHERE value = 'Repeated'",
      );
      if (repeatedExists.first['count'] == 0) {
        await db.insert('status', {'value': 'Repeated'});
      }
      
      // Migrate existing bundle dates to book_read_dates table
      final bundleBooks = await db.query(
        'book',
        where: 'is_bundle = 1 AND (bundle_start_dates IS NOT NULL OR bundle_end_dates IS NOT NULL)',
      );
      
      for (var book in bundleBooks) {
        final bookId = book['book_id'] as int;
        final bundleCount = book['bundle_count'] as int?;
        
        if (bundleCount != null && bundleCount > 0) {
          try {
            // Parse start and end dates
            List<String?>? startDates;
            List<String?>? endDates;
            
            if (book['bundle_start_dates'] != null) {
              final startDatesJson = book['bundle_start_dates'] as String;
              final List<dynamic> parsed = jsonDecode(startDatesJson);
              startDates = parsed.map((d) => d as String?).toList();
            }
            
            if (book['bundle_end_dates'] != null) {
              final endDatesJson = book['bundle_end_dates'] as String;
              final List<dynamic> parsed = jsonDecode(endDatesJson);
              endDates = parsed.map((d) => d as String?).toList();
            }
            
            // Create read dates for each bundle book
            for (int i = 0; i < bundleCount; i++) {
              String? startDate;
              String? endDate;
              
              if (startDates != null && i < startDates.length && startDates[i] != null) {
                // Parse ISO date and convert to yyyy-mm-dd
                try {
                  final dt = DateTime.parse(startDates[i]!);
                  startDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                } catch (e) {
                  startDate = null;
                }
              }
              
              if (endDates != null && i < endDates.length && endDates[i] != null) {
                try {
                  final dt = DateTime.parse(endDates[i]!);
                  endDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                } catch (e) {
                  endDate = null;
                }
              }
              
              // Only insert if at least one date exists
              if (startDate != null || endDate != null) {
                await db.insert('book_read_dates', {
                  'book_id': bookId,
                  'date_started': startDate,
                  'date_finished': endDate,
                  'bundle_book_index': i,
                });
              }
            }
          } catch (e) {
            debugPrint('Error migrating bundle dates for book $bookId: $e');
          }
        }
      }
    }
    if (oldVersion < 13) {
      // Re-run migration for bundle dates (in case v12 didn't run properly)
      final bundleBooks = await db.query(
        'book',
        where: 'is_bundle = 1 AND (bundle_start_dates IS NOT NULL OR bundle_end_dates IS NOT NULL)',
      );
      
      for (var book in bundleBooks) {
        final bookId = book['book_id'] as int;
        
        // Check if already migrated
        final existing = await db.query(
          'book_read_dates',
          where: 'book_id = ? AND bundle_book_index IS NOT NULL',
          whereArgs: [bookId],
        );
        
        if (existing.isEmpty) {
          final bundleCount = book['bundle_count'] as int?;
          
          if (bundleCount != null && bundleCount > 0) {
            try {
              List<String?>? startDates;
              List<String?>? endDates;
              
              if (book['bundle_start_dates'] != null) {
                final startDatesJson = book['bundle_start_dates'] as String;
                final List<dynamic> parsed = jsonDecode(startDatesJson);
                startDates = parsed.map((d) => d as String?).toList();
              }
              
              if (book['bundle_end_dates'] != null) {
                final endDatesJson = book['bundle_end_dates'] as String;
                final List<dynamic> parsed = jsonDecode(endDatesJson);
                endDates = parsed.map((d) => d as String?).toList();
              }
              
              for (int i = 0; i < bundleCount; i++) {
                String? startDate;
                String? endDate;
                
                if (startDates != null && i < startDates.length && startDates[i] != null) {
                  try {
                    final dt = DateTime.parse(startDates[i]!);
                    startDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                  } catch (e) {
                    startDate = null;
                  }
                }
                
                if (endDates != null && i < endDates.length && endDates[i] != null) {
                  try {
                    final dt = DateTime.parse(endDates[i]!);
                    endDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                  } catch (e) {
                    endDate = null;
                  }
                }
                
                if (startDate != null || endDate != null) {
                  await db.insert('book_read_dates', {
                    'book_id': bookId,
                    'date_started': startDate,
                    'date_finished': endDate,
                    'bundle_book_index': i,
                  });
                }
              }
            } catch (e) {
              debugPrint('Error migrating bundle dates for book $bookId: $e');
            }
          }
        }
      }
    }
    if (oldVersion < 14) {
      // Migrate old date_read_initial and date_read_final to book_read_dates
      final regularBooks = await db.query(
        'book',
        where: '(is_bundle IS NULL OR is_bundle = 0) AND (date_read_initial IS NOT NULL OR date_read_final IS NOT NULL)',
      );
      
      for (var book in regularBooks) {
        final bookId = book['book_id'] as int;
        
        // Check if already migrated (no bundle_book_index means regular book)
        final existing = await db.query(
          'book_read_dates',
          where: 'book_id = ? AND bundle_book_index IS NULL',
          whereArgs: [bookId],
        );
        
        if (existing.isEmpty) {
          String? startDate;
          String? endDate;
          
          // Parse old date fields
          if (book['date_read_initial'] != null) {
            try {
              final dateStr = book['date_read_initial'] as String;
              final dt = DateTime.parse(dateStr);
              startDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            } catch (e) {
              startDate = null;
            }
          }
          
          if (book['date_read_final'] != null) {
            try {
              final dateStr = book['date_read_final'] as String;
              final dt = DateTime.parse(dateStr);
              endDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
            } catch (e) {
              endDate = null;
            }
          }
          
          // Only insert if at least one date exists
          if (startDate != null || endDate != null) {
            await db.insert('book_read_dates', {
              'book_id': bookId,
              'date_started': startDate,
              'date_finished': endDate,
              'bundle_book_index': null, // NULL for regular books
            });
          }
        }
      }
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
