import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/read_date.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/utils/csv_import_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class AdminCsvImportScreen extends StatefulWidget {
  const AdminCsvImportScreen({super.key});

  @override
  State<AdminCsvImportScreen> createState() => _AdminCsvImportScreenState();
}

class _AdminCsvImportScreenState extends State<AdminCsvImportScreen> {
  List<_BookImportItem> _importItems = [];
  bool _isLoading = false;
  int _currentIndex = 0;
  String? _currentFileIdentifier;
  String? _currentFilePath;
  final Set<String> _reviewedBookHashes = {};
  final Set<String> _ignoredBookHashes = {};

  @override
  void initState() {
    super.initState();
    _initReviewedBooksTable();
    _checkForCheckpoint();
  }

  /// Initialize the temporary table for tracking reviewed books
  Future<void> _initReviewedBooksTable() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS temp_reviewed_books (
          session_id TEXT NOT NULL,
          book_hash TEXT NOT NULL,
          reviewed_at INTEGER DEFAULT (strftime('%s', 'now')),
          PRIMARY KEY (session_id, book_hash)
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS temp_ignored_books (
          session_id TEXT NOT NULL,
          book_hash TEXT NOT NULL,
          ignored_at INTEGER DEFAULT (strftime('%s', 'now')),
          PRIMARY KEY (session_id, book_hash)
        )
      ''');
      debugPrint('Initialized temp_reviewed_books and temp_ignored_books tables');
    } catch (e) {
      debugPrint('Error initializing temporary tables: $e');
    }
  }

  /// Generate a unique hash for a book based on its identifying information
  String _generateBookHash(_BookImportItem item) {
    final book = item.book;
    // Use ISBN/ASIN if available, otherwise use title + author + saga
    if (book.isbn != null && book.isbn!.isNotEmpty) {
      return 'isbn_${book.isbn}';
    }
    if (book.asin != null && book.asin!.isNotEmpty) {
      return 'asin_${book.asin}';
    }
    final title = book.name ?? '';
    final author = book.author ?? '';
    final saga = book.saga ?? '';
    final nSaga = book.nSaga ?? '';
    return 'book_${title}_${author}_${saga}_${nSaga}'.toLowerCase();
  }

  /// Mark a book as reviewed in the database
  Future<void> _markBookAsReviewed(String bookHash) async {
    if (_currentFileIdentifier == null) return;
    
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'temp_reviewed_books',
        {
          'session_id': _currentFileIdentifier!,
          'book_hash': bookHash,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _reviewedBookHashes.add(bookHash);
    } catch (e) {
      debugPrint('Error marking book as reviewed: $e');
    }
  }

  /// Load previously reviewed books for this session
  Future<void> _loadReviewedBooks() async {
    if (_currentFileIdentifier == null) return;
    
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query(
        'temp_reviewed_books',
        columns: ['book_hash'],
        where: 'session_id = ?',
        whereArgs: [_currentFileIdentifier!],
      );
      
      _reviewedBookHashes.clear();
      for (final row in results) {
        _reviewedBookHashes.add(row['book_hash'] as String);
      }
      
      debugPrint('Loaded ${_reviewedBookHashes.length} reviewed books for session: $_currentFileIdentifier');
    } catch (e) {
      debugPrint('Error loading reviewed books: $e');
    }
  }

  /// Clear reviewed books for a specific session
  Future<void> _clearReviewedBooks() async {
    if (_currentFileIdentifier == null) return;
    
    try {
      final db = await DatabaseHelper.instance.database;
      final deletedCount = await db.delete(
        'temp_reviewed_books',
        where: 'session_id = ?',
        whereArgs: [_currentFileIdentifier!],
      );
      _reviewedBookHashes.clear();
      debugPrint('Cleared $deletedCount reviewed books for session: $_currentFileIdentifier');
    } catch (e) {
      debugPrint('Error clearing reviewed books: $e');
    }
  }
  
  /// Clear ALL reviewed books from all sessions (for debugging/cleanup)
  Future<void> _clearAllReviewedBooks() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final deletedCount = await db.delete('temp_reviewed_books');
      _reviewedBookHashes.clear();
      debugPrint('Cleared ALL $deletedCount reviewed books from all sessions');
    } catch (e) {
      debugPrint('Error clearing all reviewed books: $e');
    }
  }

  /// Mark a book as ignored in the database
  Future<void> _markBookAsIgnored(String bookHash) async {
    if (_currentFileIdentifier == null) return;
    
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'temp_ignored_books',
        {
          'session_id': _currentFileIdentifier!,
          'book_hash': bookHash,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _ignoredBookHashes.add(bookHash);
      debugPrint('✓ Marked book as ignored: $bookHash (session: $_currentFileIdentifier)');
    } catch (e) {
      debugPrint('❌ Error marking book as ignored: $e');
    }
  }

  /// Load previously ignored books for this session
  Future<void> _loadIgnoredBooks() async {
    if (_currentFileIdentifier == null) return;
    
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query(
        'temp_ignored_books',
        columns: ['book_hash'],
        where: 'session_id = ?',
        whereArgs: [_currentFileIdentifier!],
      );
      
      _ignoredBookHashes.clear();
      for (final row in results) {
        final hash = row['book_hash'] as String;
        _ignoredBookHashes.add(hash);
        debugPrint('  📋 Loaded ignored book: $hash');
      }
      
      debugPrint('✓ Loaded ${_ignoredBookHashes.length} ignored books for session: $_currentFileIdentifier');
    } catch (e) {
      debugPrint('❌ Error loading ignored books: $e');
    }
  }

  /// Generate a unique identifier for the file based on path, size, and modification time
  String _generateFileIdentifier(String filePath) {
    final file = File(filePath);
    final stat = file.statSync();
    return '${filePath}_${stat.size}_${stat.modified.millisecondsSinceEpoch}';
  }

  /// Check if there's a saved checkpoint
  Future<void> _checkForCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIdentifier = prefs.getString('csv_import_file_identifier');
    final savedPath = prefs.getString('csv_import_file_path');
    final savedIndex = prefs.getInt('csv_import_current_index');

    if (savedIdentifier != null && savedPath != null && savedIndex != null) {
      // Check if the file still exists
      final file = File(savedPath);
      if (await file.exists()) {
        if (mounted) {
          final resume = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Resume Import?'),
                  content: Text(
                    'Found a previous import session for:\n${savedPath.split('/').last}\n\nWould you like to resume from where you left off?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        // Clear checkpoint (reviewed books will be cleared after file is loaded)
                        await _clearCheckpoint();
                        Navigator.pop(context, false);
                      },
                      child: const Text('Start Fresh'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Resume'),
                    ),
                  ],
                ),
          );

          if (resume == true) {
            await _resumeFromCheckpoint(savedPath, savedIdentifier, savedIndex);
          }
        }
      } else {
        // File no longer exists, clear checkpoint
        await _clearCheckpoint();
      }
    }
  }

  /// Save checkpoint
  Future<void> _saveCheckpoint() async {
    if (_currentFilePath != null && _currentFileIdentifier != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'csv_import_file_identifier',
        _currentFileIdentifier!,
      );
      await prefs.setString('csv_import_file_path', _currentFilePath!);
      await prefs.setInt('csv_import_current_index', _currentIndex);
    }
  }

  /// Clear checkpoint
  Future<void> _clearCheckpoint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('csv_import_file_identifier');
    await prefs.remove('csv_import_file_path');
    await prefs.remove('csv_import_current_index');
  }

  /// Resume from checkpoint
  Future<void> _resumeFromCheckpoint(
    String filePath,
    String fileIdentifier,
    int startIndex,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Verify file identifier matches
      final currentIdentifier = _generateFileIdentifier(filePath);
      if (currentIdentifier != fileIdentifier) {
        throw Exception('File has been modified since last session');
      }

      // Parse the file
      await _parseCsvFile(filePath, startFromIndex: startIndex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _clearCheckpoint();
    }
  }

  Future<void> _selectAndParseCsv() async {
    try {
      // Pick CSV file - use FileType.any to allow selection from cloud storage
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select CSV file',
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      final fileName = file.name;
      
      if (!fileName.toLowerCase().endsWith('.csv')) {
        throw Exception('Please select a CSV file');
      }

      setState(() {
        _isLoading = true;
      });

      // Try to get file path, if not available use bytes
      String filePath;
      
      if (file.path == null || file.path!.isEmpty) {
        // Path not available (e.g., web or cloud storage), use bytes
        if (file.bytes != null) {
          // Create a temporary file from bytes
          final tempDir = await Directory.systemTemp.createTemp('csv_import');
          final tempFile = File('${tempDir.path}/$fileName');
          await tempFile.writeAsBytes(file.bytes!);
          filePath = tempFile.path;
        } else {
          throw Exception('Could not access file. Please try downloading it first.');
        }
      } else {
        filePath = file.path!;
      }

      await _parseCsvFile(filePath, clearReviewed: true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _parseCsvFile(String filePath, {int startFromIndex = 0, bool clearReviewed = false}) async {
    try {
      // Generate and save file identifier
      _currentFileIdentifier = _generateFileIdentifier(filePath);
      _currentFilePath = filePath;
      
      // Clear reviewed books if starting fresh
      if (clearReviewed) {
        debugPrint('Clearing reviewed books for fresh start...');
        await _clearReviewedBooks();
        debugPrint('Reviewed books cleared. Starting with clean slate.');
      }

      // Read and parse CSV
      String input = File(filePath).readAsStringSync();
      List<List<dynamic>> rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(input);

      if (rows.length == 1) {
        rows = const CsvToListConverter(
          eol: '\r\n',
          shouldParseNumbers: false,
        ).convert(input);
      }

      if (rows.isEmpty || rows.length < 2) {
        throw Exception(
          'CSV file must have at least a header and one data row',
        );
      }

      // Detect format
      final headers = rows[0];
      final csvFormat = CsvImportHelper.detectCsvFormat(headers);

      if (csvFormat == CsvFormat.unknown) {
        throw Exception('Unknown CSV format');
      }

      // Parse all books
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final List<_BookImportItem> items = [];

      // Start from the specified index (for resume functionality)
      for (int i = 1 + startFromIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty ||
            row.every(
              (cell) => cell == null || cell.toString().trim().isEmpty,
            )) {
          continue;
        }

        try {
          final book = CsvImportHelper.parseBookFromCsv(
            row,
            csvFormat,
            headers,
          );
          if (book == null) continue;

          // Map status
          final dbHelper = DatabaseHelper();
          final mappedStatus = await CsvImportHelper.mapStatusValue(
            book.statusValue,
            dbHelper,
          );

          // Trim all string fields before saving
          var bookWithMappedStatus = Book(
            bookId: book.bookId,
            name: book.name?.trim(),
            isbn: book.isbn?.trim(),
            asin: book.asin?.trim(),
            author: book.author?.trim(),
            saga: book.saga?.trim(),
            nSaga: book.nSaga?.trim(),
            formatSagaValue: book.formatSagaValue?.trim(),
            pages: book.pages,
            originalPublicationYear: book.originalPublicationYear,
            loaned:
                (book.loaned?.trim().isEmpty ?? true)
                    ? 'no'
                    : book.loaned!.trim(), // Default to 'no' if empty
            statusValue: mappedStatus?.trim(),
            editorialValue: book.editorialValue?.trim(),
            languageValue: book.languageValue?.trim(),
            placeValue: book.placeValue?.trim(),
            formatValue: book.formatValue?.trim(),
            createdAt: book.createdAt,
            genre: book.genre?.trim(),
            dateReadInitial: book.dateReadInitial?.trim(),
            dateReadFinal: book.dateReadFinal?.trim(),
            readCount: book.readCount,
            myRating: book.myRating,
            myReview: book.myReview?.trim(),
            isBundle: book.isBundle,
            bundleCount: book.bundleCount,
            bundleNumbers: book.bundleNumbers,
            bundleStartDates: book.bundleStartDates,
            bundleEndDates: book.bundleEndDates,
            bundlePages: book.bundlePages,
          );

          // Check for duplicates
          final duplicateIds = await repository.findDuplicateBooks(
            bookWithMappedStatus,
          );

          String importType;
          Book? existingBook;
          if (duplicateIds.isEmpty) {
            importType = 'NEW';
          } else if (duplicateIds.length == 1) {
            importType = 'UPDATE';
            // Fetch the existing book for comparison with proper JOINs
            final existingRows = await db.rawQuery(
              '''
              select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
                b.saga, b.n_saga, b.saga_universe, b.isbn, b.asin, l.name as languageValue, 
                p.name as placeValue, f.value as formatValue,
                fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
                b.pages, b.created_at, b.date_read_initial, b.date_read_final, 
                b.read_count, b.my_rating, b.my_review,
                b.is_bundle, b.bundle_count, b.bundle_numbers, b.bundle_start_dates, b.bundle_end_dates, b.bundle_pages,
                GROUP_CONCAT(DISTINCT a.name) as author,
                GROUP_CONCAT(DISTINCT g.name) as genre
              from book b 
              left join books_by_author bba on b.book_id = bba.book_id 
              left join author a on bba.author_id = a.author_id
              left join books_by_genre bbg on b.book_id = bbg.book_id 
              left join genre g on bbg.genre_id = g.genre_id
              left join status s on b.status_id = s.status_id 
              left join editorial e on b.editorial_id = e.editorial_id
              left join language l on b.language_id = l.language_id 
              left join place p on b.place_id = p.place_id  
              left join format f on b.format_id = f.format_id
              left join format_saga fs on b.format_saga_id = fs.format_id
              where b.book_id = ?
              group by b.book_id
            ''',
              [duplicateIds.first],
            );
            if (existingRows.isNotEmpty) {
              existingBook = Book.fromMap(existingRows.first);
              
              // Fetch read dates from book_read_dates table if dates are empty
              if ((existingBook.dateReadInitial == null || existingBook.dateReadInitial!.isEmpty) &&
                  (existingBook.dateReadFinal == null || existingBook.dateReadFinal!.isEmpty)) {
                final readDatesRows = await db.query(
                  'book_read_dates',
                  where: 'book_id = ? AND bundle_book_index IS NULL',
                  whereArgs: [duplicateIds.first],
                  orderBy: 'date_started ASC',
                  limit: 1,
                );
                if (readDatesRows.isNotEmpty) {
                  final firstReadDate = readDatesRows.first;
                  existingBook = Book(
                    bookId: existingBook.bookId,
                    name: existingBook.name,
                    isbn: existingBook.isbn,
                    asin: existingBook.asin,
                    author: existingBook.author,
                    saga: existingBook.saga,
                    nSaga: existingBook.nSaga,
                    sagaUniverse: existingBook.sagaUniverse,
                    formatSagaValue: existingBook.formatSagaValue,
                    pages: existingBook.pages,
                    originalPublicationYear: existingBook.originalPublicationYear,
                    loaned: existingBook.loaned,
                    statusValue: existingBook.statusValue,
                    editorialValue: existingBook.editorialValue,
                    languageValue: existingBook.languageValue,
                    placeValue: existingBook.placeValue,
                    formatValue: existingBook.formatValue,
                    createdAt: existingBook.createdAt,
                    genre: existingBook.genre,
                    dateReadInitial: firstReadDate['date_started'] as String?,
                    dateReadFinal: firstReadDate['date_finished'] as String?,
                    readCount: existingBook.readCount,
                    myRating: existingBook.myRating,
                    myReview: existingBook.myReview,
                    isBundle: existingBook.isBundle,
                    bundleCount: existingBook.bundleCount,
                    bundleNumbers: existingBook.bundleNumbers,
                    bundleStartDates: existingBook.bundleStartDates,
                    bundleEndDates: existingBook.bundleEndDates,
                    bundlePages: existingBook.bundlePages,
                  );
                }
              }

              // Merge: Keep old values when CSV has empty/null values
              bookWithMappedStatus = Book(
                bookId: bookWithMappedStatus.bookId,
                name:
                    bookWithMappedStatus.name?.isNotEmpty == true
                        ? bookWithMappedStatus.name
                        : existingBook.name,
                author:
                    bookWithMappedStatus.author?.isNotEmpty == true
                        ? bookWithMappedStatus.author
                        : existingBook.author,
                isbn:
                    bookWithMappedStatus.isbn?.isNotEmpty == true
                        ? bookWithMappedStatus.isbn
                        : existingBook.isbn,
                asin:
                    bookWithMappedStatus.asin?.isNotEmpty == true
                        ? bookWithMappedStatus.asin
                        : existingBook.asin,
                saga:
                    bookWithMappedStatus.saga?.isNotEmpty == true
                        ? bookWithMappedStatus.saga
                        : existingBook.saga,
                nSaga:
                    bookWithMappedStatus.nSaga?.isNotEmpty == true
                        ? bookWithMappedStatus.nSaga
                        : existingBook.nSaga,
                sagaUniverse:
                    bookWithMappedStatus.sagaUniverse?.isNotEmpty == true
                        ? bookWithMappedStatus.sagaUniverse
                        : existingBook.sagaUniverse,
                formatSagaValue:
                    bookWithMappedStatus.formatSagaValue?.isNotEmpty == true
                        ? bookWithMappedStatus.formatSagaValue
                        : existingBook.formatSagaValue,
                pages: bookWithMappedStatus.pages ?? existingBook.pages,
                originalPublicationYear:
                    bookWithMappedStatus.originalPublicationYear ??
                    existingBook.originalPublicationYear,
                loaned:
                    bookWithMappedStatus.loaned?.isNotEmpty == true
                        ? bookWithMappedStatus.loaned
                        : existingBook.loaned,
                statusValue:
                    bookWithMappedStatus.statusValue?.isNotEmpty == true
                        ? bookWithMappedStatus.statusValue
                        : existingBook.statusValue,
                editorialValue:
                    bookWithMappedStatus.editorialValue?.isNotEmpty == true
                        ? bookWithMappedStatus.editorialValue
                        : existingBook.editorialValue,
                languageValue:
                    bookWithMappedStatus.languageValue?.isNotEmpty == true
                        ? bookWithMappedStatus.languageValue
                        : existingBook.languageValue,
                placeValue:
                    bookWithMappedStatus.placeValue?.isNotEmpty == true
                        ? bookWithMappedStatus.placeValue
                        : existingBook.placeValue,
                formatValue:
                    bookWithMappedStatus.formatValue?.isNotEmpty == true
                        ? bookWithMappedStatus.formatValue
                        : existingBook.formatValue,
                createdAt:
                    existingBook
                        .createdAt, // Always keep original creation date
                genre:
                    bookWithMappedStatus.genre?.isNotEmpty == true
                        ? bookWithMappedStatus.genre
                        : existingBook.genre,
                dateReadInitial:
                    bookWithMappedStatus.dateReadInitial?.isNotEmpty == true
                        ? bookWithMappedStatus.dateReadInitial
                        : existingBook.dateReadInitial,
                dateReadFinal:
                    bookWithMappedStatus.dateReadFinal?.isNotEmpty == true
                        ? bookWithMappedStatus.dateReadFinal
                        : existingBook.dateReadFinal,
                readCount:
                    bookWithMappedStatus.readCount ?? existingBook.readCount,
                myRating:
                    bookWithMappedStatus.myRating ?? existingBook.myRating,
                myReview:
                    bookWithMappedStatus.myReview?.isNotEmpty == true
                        ? bookWithMappedStatus.myReview
                        : existingBook.myReview,
                isBundle:
                    bookWithMappedStatus.isBundle ?? existingBook.isBundle,
                bundleCount:
                    bookWithMappedStatus.bundleCount ??
                    existingBook.bundleCount,
                bundleNumbers:
                    bookWithMappedStatus.bundleNumbers?.isNotEmpty == true
                        ? bookWithMappedStatus.bundleNumbers
                        : existingBook.bundleNumbers,
                bundleStartDates:
                    bookWithMappedStatus.bundleStartDates?.isNotEmpty == true
                        ? bookWithMappedStatus.bundleStartDates
                        : existingBook.bundleStartDates,
                bundleEndDates:
                    bookWithMappedStatus.bundleEndDates?.isNotEmpty == true
                        ? bookWithMappedStatus.bundleEndDates
                        : existingBook.bundleEndDates,
                bundlePages:
                    bookWithMappedStatus.bundlePages?.isNotEmpty == true
                        ? bookWithMappedStatus.bundlePages
                        : existingBook.bundlePages,
              );

              // Check if merged book is actually different from existing
              if (_booksAreIdentical(bookWithMappedStatus, existingBook)) {
                importType = 'DUPLICATE';
              }
            }
          } else {
            importType = 'DUPLICATE';
          }

          items.add(
            _BookImportItem(
              book: bookWithMappedStatus,
              importType: importType,
              duplicateIds: duplicateIds,
              shouldImport: true,
              existingBook: existingBook,
            ),
          );
        } catch (e) {
          debugPrint('Error parsing row $i: $e');
        }
      }

      // Load reviewed and ignored books for this session
      await _loadReviewedBooks();
      await _loadIgnoredBooks();
      
      debugPrint('Session ID: $_currentFileIdentifier');
      debugPrint('Loaded ${_reviewedBookHashes.length} reviewed book hashes from database');
      debugPrint('Loaded ${_ignoredBookHashes.length} ignored book hashes from database');
      
      // Filter out reviewed and ignored books
      int reviewedCount = 0;
      int ignoredCount = 0;
      final unreviewedItems = items.where((item) {
        final hash = _generateBookHash(item);
        final isReviewed = _reviewedBookHashes.contains(hash);
        final isIgnored = _ignoredBookHashes.contains(hash);
        if (isReviewed) {
          reviewedCount++;
          if (reviewedCount <= 5) {
            debugPrint('  ✓ Filtering out reviewed book: ${item.book.name} (hash: $hash)');
          }
        }
        if (isIgnored) {
          ignoredCount++;
          if (ignoredCount <= 5) {
            debugPrint('  🚫 Filtering out ignored book: ${item.book.name} (hash: $hash)');
          }
        }
        return !isReviewed && !isIgnored;
      }).toList();
      
      // Sort items: ISBN/ASIN matches first, then name matches, then rest
      unreviewedItems.sort((a, b) {
        // Determine match type for each item
        int getMatchPriority(_BookImportItem item) {
          final hasIsbn = item.book.isbn != null && item.book.isbn!.isNotEmpty;
          final hasAsin = item.book.asin != null && item.book.asin!.isNotEmpty;
          final hasName = item.book.name != null && item.book.name!.isNotEmpty;
          
          // Priority 1: Has ISBN or ASIN match (UPDATE or DUPLICATE with ISBN/ASIN)
          if ((hasIsbn || hasAsin) && (item.importType == 'UPDATE' || item.importType == 'DUPLICATE')) {
            return 1;
          }
          // Priority 2: Has name match (UPDATE or DUPLICATE without ISBN/ASIN)
          if (hasName && (item.importType == 'UPDATE' || item.importType == 'DUPLICATE')) {
            return 2;
          }
          // Priority 3: Everything else (NEW books)
          return 3;
        }
        
        final aPriority = getMatchPriority(a);
        final bPriority = getMatchPriority(b);
        
        return aPriority.compareTo(bPriority);
      });
      
      if (reviewedCount > 5) {
        debugPrint('  ... and ${reviewedCount - 5} more reviewed books');
      }
      if (ignoredCount > 5) {
        debugPrint('  ... and ${ignoredCount - 5} more ignored books');
      }
      
      debugPrint('=== IMPORT SUMMARY ===');
      debugPrint('Total items parsed: ${items.length}');
      debugPrint('Unreviewed items: ${unreviewedItems.length}');
      debugPrint('Already reviewed: $reviewedCount');
      debugPrint('Already ignored: $ignoredCount');
      debugPrint('====================');

      setState(() {
        _importItems = unreviewedItems;
        _isLoading = false;
        _currentIndex = 0;
      });

      // Save checkpoint
      await _saveCheckpoint();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw e;
    }
  }

  Future<void> _processImports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      int imported = 0;
      int updated = 0;
      int skipped = 0;

      for (final item in _importItems) {
        // Mark this book as reviewed (even if skipped)
        final bookHash = _generateBookHash(item);
        await _markBookAsReviewed(bookHash);
        
        if (!item.shouldImport) {
          skipped++;
          continue;
        }

        if (item.importType == 'NEW') {
          final bookId = await repository.addBook(item.book);
          // Save dates to book_read_dates table if they exist
          if (item.book.dateReadInitial != null && item.book.dateReadInitial!.isNotEmpty) {
            await repository.addReadDate(ReadDate(
              bookId: bookId,
              dateStarted: item.book.dateReadInitial,
              dateFinished: item.book.dateReadFinal,
            ));
            debugPrint('📅 Saved read dates for new book $bookId: ${item.book.dateReadInitial} - ${item.book.dateReadFinal}');
          }
          imported++;
        } else if (item.importType == 'UPDATE' &&
            item.duplicateIds.isNotEmpty) {
          for (final id in item.duplicateIds) {
            // Use delete and re-add approach to properly handle relational tables
            await repository.deleteBook(id);
            // Preserve the original book ID
            final bookToAdd = Book(
              bookId: id,
              name: item.book.name,
              isbn: item.book.isbn,
              asin: item.book.asin,
              author: item.book.author,
              saga: item.book.saga,
              nSaga: item.book.nSaga,
              sagaUniverse: item.book.sagaUniverse,
              pages: item.book.pages,
              originalPublicationYear: item.book.originalPublicationYear,
              statusValue: item.book.statusValue,
              formatSagaValue: item.book.formatSagaValue,
              languageValue: item.book.languageValue,
              placeValue: item.book.placeValue,
              formatValue: item.book.formatValue,
              editorialValue: item.book.editorialValue,
              genre: item.book.genre,
              loaned: item.book.loaned,
              createdAt: item.book.createdAt,
              myRating: item.book.myRating,
              readCount: item.book.readCount,
              dateReadInitial: item.book.dateReadInitial,
              dateReadFinal: item.book.dateReadFinal,
              myReview: item.book.myReview,
              isBundle: item.book.isBundle,
              bundleCount: item.book.bundleCount,
              bundleNumbers: item.book.bundleNumbers,
              bundleStartDates: item.book.bundleStartDates,
              bundleEndDates: item.book.bundleEndDates,
              bundlePages: item.book.bundlePages,
            );
            await repository.addBook(bookToAdd);
            
            // Save dates to book_read_dates table if they exist
            if (item.book.dateReadInitial != null && item.book.dateReadInitial!.isNotEmpty) {
              await repository.addReadDate(ReadDate(
                bookId: id,
                dateStarted: item.book.dateReadInitial,
                dateFinished: item.book.dateReadFinal,
              ));
              debugPrint('📅 Saved read dates for updated book $id: ${item.book.dateReadInitial} - ${item.book.dateReadFinal}');
            }
          }
          updated++;
        }
      }

      // Reload books
      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        setState(() {
          _isLoading = false;
        });

        // Clear checkpoint and reviewed books after successful import
        await _clearCheckpoint();
        await _clearReviewedBooks();

        // Show results
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Import Complete'),
                content: Text(
                  'Imported: $imported\nUpdated: $updated\nSkipped: $skipped',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(
                        context,
                        true,
                      ); // Go back to settings with result
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _processPartialImport(int upToIndex) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      int imported = 0;
      int updated = 0;
      int skipped = 0;

      // Only process items up to the specified index
      for (int i = 0; i < upToIndex && i < _importItems.length; i++) {
        final item = _importItems[i];
        
        // Mark this book as reviewed
        final bookHash = _generateBookHash(item);
        await _markBookAsReviewed(bookHash);

        if (!item.shouldImport) {
          skipped++;
          continue;
        }

        if (item.importType == 'NEW') {
          final bookId = await repository.addBook(item.book);
          // Save dates to book_read_dates table if they exist
          if (item.book.dateReadInitial != null && item.book.dateReadInitial!.isNotEmpty) {
            await repository.addReadDate(ReadDate(
              bookId: bookId,
              dateStarted: item.book.dateReadInitial,
              dateFinished: item.book.dateReadFinal,
            ));
            debugPrint('📅 Saved read dates for new book $bookId: ${item.book.dateReadInitial} - ${item.book.dateReadFinal}');
          }
          imported++;
        } else if (item.importType == 'UPDATE' &&
            item.duplicateIds.isNotEmpty) {
          for (final id in item.duplicateIds) {
            // Use delete and re-add approach to properly handle relational tables
            await repository.deleteBook(id);
            // Preserve the original book ID
            final bookToAdd = Book(
              bookId: id,
              name: item.book.name,
              isbn: item.book.isbn,
              asin: item.book.asin,
              author: item.book.author,
              saga: item.book.saga,
              nSaga: item.book.nSaga,
              sagaUniverse: item.book.sagaUniverse,
              pages: item.book.pages,
              originalPublicationYear: item.book.originalPublicationYear,
              statusValue: item.book.statusValue,
              formatSagaValue: item.book.formatSagaValue,
              languageValue: item.book.languageValue,
              placeValue: item.book.placeValue,
              formatValue: item.book.formatValue,
              editorialValue: item.book.editorialValue,
              genre: item.book.genre,
              loaned: item.book.loaned,
              createdAt: item.book.createdAt,
              myRating: item.book.myRating,
              readCount: item.book.readCount,
              dateReadInitial: item.book.dateReadInitial,
              dateReadFinal: item.book.dateReadFinal,
              myReview: item.book.myReview,
              isBundle: item.book.isBundle,
              bundleCount: item.book.bundleCount,
              bundleNumbers: item.book.bundleNumbers,
              bundleStartDates: item.book.bundleStartDates,
              bundleEndDates: item.book.bundleEndDates,
              bundlePages: item.book.bundlePages,
            );
            await repository.addBook(bookToAdd);
            
            // Save dates to book_read_dates table if they exist
            if (item.book.dateReadInitial != null && item.book.dateReadInitial!.isNotEmpty) {
              await repository.addReadDate(ReadDate(
                bookId: id,
                dateStarted: item.book.dateReadInitial,
                dateFinished: item.book.dateReadFinal,
              ));
              debugPrint('📅 Saved read dates for updated book $id: ${item.book.dateReadInitial} - ${item.book.dateReadFinal}');
            }
          }
          updated++;
        }
      }

      // Remove imported items from the list
      setState(() {
        _importItems.removeRange(0, upToIndex);
        _currentIndex = 0;
        _isLoading = false;
      });

      // Reload books
      if (mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        // If all items imported, go back to settings
        if (_importItems.isEmpty) {
          // Clear checkpoint and reviewed books after successful partial import
          await _clearCheckpoint();
          await _clearReviewedBooks();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Import complete: $imported imported, $updated updated, $skipped skipped.',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            // Wait a bit for snackbar to show, then go back
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pop(context, true); // Go back to settings with result
            }
          }
        } else {
          // Save checkpoint for remaining items
          await _saveCheckpoint();

          // Show results with remaining count
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Partial import complete: $imported imported, $updated updated, $skipped skipped. ${_importItems.length} books remaining.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin CSV Import'),
        actions: [
          if (_importItems.isNotEmpty && !_isLoading)
            TextButton.icon(
              onPressed: _processImports,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Import All',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _importItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_file, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('No CSV file selected'),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _selectAndParseCsv,
                      icon: const Icon(Icons.file_open),
                      label: const Text('Select CSV File'),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Reviewed Books?'),
                            content: const Text(
                              'This will clear all tracked reviewed books from all import sessions. Use this if the count seems wrong.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Clear All'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmed == true) {
                          await _clearAllReviewedBooks();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cleared all reviewed books tracking'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Clear Reviewed Books Cache'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Book ${_currentIndex + 1} of ${_importItems.length}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${_importItems.where((i) => i.shouldImport).length} to import',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  // Book preview
                  Expanded(
                    child: _BookImportPreview(
                      item: _importItems[_currentIndex],
                      onChanged: (updated) {
                        setState(() {
                          _importItems[_currentIndex] = updated;
                        });
                      },
                    ),
                  ),
                  // Navigation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Import up to here button
                        if (_currentIndex < _importItems.length - 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final toImportCount =
                                    _importItems
                                        .take(_currentIndex + 1)
                                        .where((item) => item.shouldImport)
                                        .length;
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Import Up To Here'),
                                        content: Text(
                                          'Import $toImportCount books from the first ${_currentIndex + 1}?\n\n(Only books marked for import will be imported)',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Import'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
                                  await _processPartialImport(
                                    _currentIndex + 1,
                                  );
                                }
                              },
                              icon: const Icon(Icons.download, size: 18),
                              label: Text(
                                'Import Up To Here (${_importItems.take(_currentIndex + 1).where((item) => item.shouldImport).length} books)',
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    _currentIndex > 0
                                        ? () {
                                          setState(() {
                                            _currentIndex--;
                                          });
                                          _saveCheckpoint();
                                        }
                                        : null,
                                child: const Text('Previous'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    _currentIndex < _importItems.length - 1
                                        ? () async {
                                          // Mark current book as ignored, don't import, and move to next
                                          final currentItem = _importItems[_currentIndex];
                                          final currentHash = _generateBookHash(currentItem);
                                          debugPrint('🚫 Ignoring book: ${currentItem.book.name} (hash: $currentHash)');
                                          await _markBookAsIgnored(currentHash);
                                          
                                          setState(() {
                                            // Mark as not to import
                                            _importItems[_currentIndex] = _importItems[_currentIndex].copyWith(shouldImport: false);
                                            _currentIndex++;
                                          });
                                          await _saveCheckpoint();
                                        }
                                        : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                ),
                                child: const Text('Ignore'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _currentIndex < _importItems.length - 1
                                        ? () async {
                                          // Mark current book as reviewed before moving to next
                                          final currentHash = _generateBookHash(_importItems[_currentIndex]);
                                          await _markBookAsReviewed(currentHash);
                                          
                                          setState(() {
                                            _currentIndex++;
                                          });
                                          await _saveCheckpoint();
                                        }
                                        : null,
                                child: const Text('Next'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  bool _booksAreIdentical(Book book1, Book book2) {
    // Compare all relevant fields to determine if books are identical
    return book1.name == book2.name &&
        book1.author == book2.author &&
        book1.isbn == book2.isbn &&
        book1.asin == book2.asin &&
        book1.saga == book2.saga &&
        book1.nSaga == book2.nSaga &&
        book1.sagaUniverse == book2.sagaUniverse &&
        book1.formatSagaValue == book2.formatSagaValue &&
        book1.pages == book2.pages &&
        book1.originalPublicationYear == book2.originalPublicationYear &&
        book1.loaned == book2.loaned &&
        book1.statusValue == book2.statusValue &&
        book1.editorialValue == book2.editorialValue &&
        book1.languageValue == book2.languageValue &&
        book1.placeValue == book2.placeValue &&
        book1.formatValue == book2.formatValue &&
        book1.genre == book2.genre &&
        book1.dateReadInitial == book2.dateReadInitial &&
        book1.dateReadFinal == book2.dateReadFinal &&
        book1.readCount == book2.readCount &&
        book1.myRating == book2.myRating &&
        book1.myReview == book2.myReview;
  }
}

class _BookImportItem {
  final Book book;
  final String importType; // 'NEW', 'UPDATE', 'DUPLICATE'
  final List<int> duplicateIds;
  final bool shouldImport;
  final Book? existingBook; // For comparison when updating

  _BookImportItem({
    required this.book,
    required this.importType,
    required this.duplicateIds,
    required this.shouldImport,
    this.existingBook,
  });

  _BookImportItem copyWith({
    Book? book,
    String? importType,
    List<int>? duplicateIds,
    bool? shouldImport,
    Book? existingBook,
  }) {
    return _BookImportItem(
      book: book ?? this.book,
      importType: importType ?? this.importType,
      duplicateIds: duplicateIds ?? this.duplicateIds,
      shouldImport: shouldImport ?? this.shouldImport,
      existingBook: existingBook ?? this.existingBook,
    );
  }
}

class _BookImportPreview extends StatelessWidget {
  final _BookImportItem item;
  final Function(_BookImportItem) onChanged;

  const _BookImportPreview({required this.item, required this.onChanged});

  Color _getTypeColor() {
    switch (item.importType) {
      case 'NEW':
        return Colors.green;
      case 'UPDATE':
        return Colors.orange;
      case 'DUPLICATE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _isFieldNew(_BookImportItem item, String fieldName) {
    // If it's a new book, all fields with values are highlighted
    if (item.importType == 'NEW') {
      return _hasValue(item.book, fieldName);
    }

    // If it's an update, highlight fields that are different or newly added
    if (item.importType == 'UPDATE' && item.existingBook != null) {
      return _isFieldDifferent(item.book, item.existingBook!, fieldName);
    }

    return false;
  }

  bool _hasValue(Book book, String fieldName) {
    switch (fieldName) {
      case 'name':
        return book.name != null && book.name!.isNotEmpty;
      case 'author':
        return book.author != null && book.author!.isNotEmpty;
      case 'isbn':
        return book.isbn != null && book.isbn!.isNotEmpty;
      case 'asin':
        return book.asin != null && book.asin!.isNotEmpty;
      case 'saga':
        return book.saga != null && book.saga!.isNotEmpty;
      case 'nSaga':
        return book.nSaga != null && book.nSaga!.isNotEmpty;
      case 'sagaUniverse':
        return book.sagaUniverse != null && book.sagaUniverse!.isNotEmpty;
      case 'formatSaga':
        return book.formatSagaValue != null && book.formatSagaValue!.isNotEmpty;
      case 'loaned':
        return book.loaned != null && book.loaned!.isNotEmpty;
      case 'pages':
        return book.pages != null;
      case 'year':
        return book.originalPublicationYear != null;
      case 'status':
        return book.statusValue != null && book.statusValue!.isNotEmpty;
      case 'editorial':
        return book.editorialValue != null && book.editorialValue!.isNotEmpty;
      case 'language':
        return book.languageValue != null && book.languageValue!.isNotEmpty;
      case 'place':
        return book.placeValue != null && book.placeValue!.isNotEmpty;
      case 'format':
        return book.formatValue != null && book.formatValue!.isNotEmpty;
      case 'genre':
        return book.genre != null && book.genre!.isNotEmpty;
      case 'dateReadInitial':
        return book.dateReadInitial != null && book.dateReadInitial!.isNotEmpty;
      case 'dateReadFinal':
        return book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty;
      case 'readCount':
        return book.readCount != null && book.readCount! > 0;
      case 'rating':
        return book.myRating != null && book.myRating! > 0;
      default:
        return false;
    }
  }

  void _updateField(String fieldName, String value) {
    final book = item.book;
    // Trim the value to prevent trailing spaces
    final trimmedValue = value.trim();
    Book updatedBook;

    switch (fieldName) {
      case 'name':
        updatedBook = Book(
          bookId: book.bookId,
          name: trimmedValue.isEmpty ? null : trimmedValue,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'author':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: trimmedValue.isEmpty ? null : trimmedValue,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'isbn':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: trimmedValue.isEmpty ? null : trimmedValue,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'asin':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: trimmedValue.isEmpty ? null : trimmedValue,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'saga':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: trimmedValue.isEmpty ? null : trimmedValue,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'nSaga':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: trimmedValue.isEmpty ? null : trimmedValue,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'pages':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: trimmedValue.isEmpty ? null : int.tryParse(trimmedValue),
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'year':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear:
              trimmedValue.isEmpty ? null : int.tryParse(trimmedValue),
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'status':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: trimmedValue.isEmpty ? null : trimmedValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'editorial':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: trimmedValue.isEmpty ? null : trimmedValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'language':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: trimmedValue.isEmpty ? null : trimmedValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'place':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: trimmedValue.isEmpty ? null : trimmedValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'format':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: trimmedValue.isEmpty ? null : trimmedValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'genre':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: trimmedValue.isEmpty ? null : trimmedValue,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'dateReadInitial':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: value.isEmpty ? null : value,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'dateReadFinal':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: value.isEmpty ? null : value,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'readCount':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          sagaUniverse: book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: value.isEmpty ? null : int.tryParse(value),
          myRating: book.myRating,
          myReview: book.myReview,
        );
        break;
      case 'rating':
        updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: book.saga,
          nSaga: book.nSaga,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: value.isEmpty ? null : double.tryParse(value),
          myReview: book.myReview,
          sagaUniverse: book.sagaUniverse,
        );
        break;
      case 'review':
        updatedBook = Book(
          bookId: book.bookId, name: book.name, isbn: book.isbn, asin: book.asin,
          author: book.author, saga: book.saga, nSaga: book.nSaga,
          formatSagaValue: book.formatSagaValue, pages: book.pages,
          originalPublicationYear: book.originalPublicationYear, loaned: book.loaned,
          statusValue: book.statusValue, editorialValue: book.editorialValue,
          languageValue: book.languageValue, placeValue: book.placeValue,
          formatValue: book.formatValue, createdAt: book.createdAt, genre: book.genre,
          dateReadInitial: book.dateReadInitial, dateReadFinal: book.dateReadFinal,
          readCount: book.readCount, myRating: book.myRating,
          myReview: trimmedValue.isEmpty ? null : trimmedValue,
          sagaUniverse: book.sagaUniverse,
        );
        break;
      case 'sagaUniverse':
        updatedBook = Book(
          bookId: book.bookId, name: book.name, isbn: book.isbn, asin: book.asin,
          author: book.author, saga: book.saga, nSaga: book.nSaga,
          formatSagaValue: book.formatSagaValue, pages: book.pages,
          originalPublicationYear: book.originalPublicationYear, loaned: book.loaned,
          statusValue: book.statusValue, editorialValue: book.editorialValue,
          languageValue: book.languageValue, placeValue: book.placeValue,
          formatValue: book.formatValue, createdAt: book.createdAt, genre: book.genre,
          dateReadInitial: book.dateReadInitial, dateReadFinal: book.dateReadFinal,
          readCount: book.readCount, myRating: book.myRating, myReview: book.myReview,
          sagaUniverse: trimmedValue.isEmpty ? null : trimmedValue,
        );
        break;
      case 'formatSaga':
        updatedBook = Book(
          bookId: book.bookId, name: book.name, isbn: book.isbn, asin: book.asin,
          author: book.author, saga: book.saga, nSaga: book.nSaga,
          formatSagaValue: trimmedValue.isEmpty ? null : trimmedValue, pages: book.pages,
          originalPublicationYear: book.originalPublicationYear, loaned: book.loaned,
          statusValue: book.statusValue, editorialValue: book.editorialValue,
          languageValue: book.languageValue, placeValue: book.placeValue,
          formatValue: book.formatValue, createdAt: book.createdAt, genre: book.genre,
          dateReadInitial: book.dateReadInitial, dateReadFinal: book.dateReadFinal,
          readCount: book.readCount, myRating: book.myRating, myReview: book.myReview,
          sagaUniverse: book.sagaUniverse,
        );
        break;
      case 'loaned':
        updatedBook = Book(
          bookId: book.bookId, name: book.name, isbn: book.isbn, asin: book.asin,
          author: book.author, saga: book.saga, nSaga: book.nSaga,
          formatSagaValue: book.formatSagaValue, pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: trimmedValue.isEmpty ? null : trimmedValue.toLowerCase(),
          statusValue: book.statusValue, editorialValue: book.editorialValue,
          languageValue: book.languageValue, placeValue: book.placeValue,
          formatValue: book.formatValue, createdAt: book.createdAt, genre: book.genre,
          dateReadInitial: book.dateReadInitial, dateReadFinal: book.dateReadFinal,
          readCount: book.readCount, myRating: book.myRating, myReview: book.myReview,
          sagaUniverse: book.sagaUniverse,
        );
        break;
      default:
        return;
    }

    onChanged(item.copyWith(book: updatedBook));
  }

  String? _getOldValue(String fieldName) {
    if (item.importType != 'UPDATE' || item.existingBook == null) {
      return null;
    }

    final existing = item.existingBook!;
    String? oldValue;

    switch (fieldName) {
      case 'name':
        oldValue = existing.name;
        break;
      case 'author':
        oldValue = existing.author;
        break;
      case 'isbn':
        oldValue = existing.isbn;
        break;
      case 'asin':
        oldValue = existing.asin;
        break;
      case 'saga':
        oldValue = existing.saga;
        break;
      case 'nSaga':
        oldValue = existing.nSaga;
        break;
      case 'pages':
        oldValue = existing.pages?.toString();
        break;
      case 'year':
        oldValue = existing.originalPublicationYear?.toString();
        break;
      case 'status':
        oldValue = existing.statusValue;
        break;
      case 'editorial':
        oldValue = existing.editorialValue;
        break;
      case 'language':
        oldValue = existing.languageValue;
        break;
      case 'place':
        oldValue = existing.placeValue;
        break;
      case 'format':
        oldValue = existing.formatValue;
        break;
      case 'genre':
        oldValue = existing.genre;
        break;
      case 'dateReadInitial':
        oldValue = existing.dateReadInitial;
        break;
      case 'dateReadFinal':
        oldValue = existing.dateReadFinal;
        break;
      case 'readCount':
        oldValue = existing.readCount?.toString();
        break;
      case 'rating':
        oldValue = existing.myRating?.toString();
        break;
      case 'review':
        oldValue = existing.myReview;
        break;
      case 'sagaUniverse':
        oldValue = existing.sagaUniverse;
        break;
      case 'formatSaga':
        oldValue = existing.formatSagaValue;
        break;
      case 'loaned':
        oldValue = existing.loaned;
        break;
      default:
        oldValue = null;
    }

    return oldValue;
  }

  bool _isFieldDifferent(Book newBook, Book existingBook, String fieldName) {
    switch (fieldName) {
      case 'name':
        return newBook.name != existingBook.name &&
            newBook.name != null &&
            newBook.name!.isNotEmpty;
      case 'author':
        return newBook.author != existingBook.author &&
            newBook.author != null &&
            newBook.author!.isNotEmpty;
      case 'isbn':
        return newBook.isbn != existingBook.isbn &&
            newBook.isbn != null &&
            newBook.isbn!.isNotEmpty;
      case 'saga':
        return newBook.saga != existingBook.saga &&
            newBook.saga != null &&
            newBook.saga!.isNotEmpty;
      case 'nSaga':
        return newBook.nSaga != existingBook.nSaga &&
            newBook.nSaga != null &&
            newBook.nSaga!.isNotEmpty;
      case 'sagaUniverse':
        return newBook.sagaUniverse != existingBook.sagaUniverse &&
            newBook.sagaUniverse != null &&
            newBook.sagaUniverse!.isNotEmpty;
      case 'formatSaga':
        return newBook.formatSagaValue != existingBook.formatSagaValue &&
            newBook.formatSagaValue != null &&
            newBook.formatSagaValue!.isNotEmpty;
      case 'loaned':
        return newBook.loaned != existingBook.loaned &&
            newBook.loaned != null &&
            newBook.loaned!.isNotEmpty;
      case 'pages':
        return newBook.pages != existingBook.pages && newBook.pages != null;
      case 'year':
        return newBook.originalPublicationYear !=
                existingBook.originalPublicationYear &&
            newBook.originalPublicationYear != null;
      case 'status':
        return newBook.statusValue != existingBook.statusValue &&
            newBook.statusValue != null &&
            newBook.statusValue!.isNotEmpty;
      case 'editorial':
        return newBook.editorialValue != existingBook.editorialValue &&
            newBook.editorialValue != null &&
            newBook.editorialValue!.isNotEmpty;
      case 'language':
        return newBook.languageValue != existingBook.languageValue &&
            newBook.languageValue != null &&
            newBook.languageValue!.isNotEmpty;
      case 'place':
        return newBook.placeValue != existingBook.placeValue &&
            newBook.placeValue != null &&
            newBook.placeValue!.isNotEmpty;
      case 'format':
        return newBook.formatValue != existingBook.formatValue &&
            newBook.formatValue != null &&
            newBook.formatValue!.isNotEmpty;
      case 'genre':
        return newBook.genre != existingBook.genre &&
            newBook.genre != null &&
            newBook.genre!.isNotEmpty;
      case 'dateReadInitial':
        return newBook.dateReadInitial != existingBook.dateReadInitial &&
            newBook.dateReadInitial != null &&
            newBook.dateReadInitial!.isNotEmpty;
      case 'dateReadFinal':
        return newBook.dateReadFinal != existingBook.dateReadFinal &&
            newBook.dateReadFinal != null &&
            newBook.dateReadFinal!.isNotEmpty;
      case 'readCount':
        return newBook.readCount != existingBook.readCount &&
            newBook.readCount != null;
      case 'rating':
        return newBook.myRating != existingBook.myRating &&
            newBook.myRating != null &&
            newBook.myRating! > 0;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Import type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTypeColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getTypeColor()),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.importType == 'NEW'
                      ? Icons.add_circle
                      : item.importType == 'UPDATE'
                      ? Icons.update
                      : Icons.warning,
                  color: _getTypeColor(),
                ),
                const SizedBox(width: 8),
                Text(
                  item.importType,
                  style: TextStyle(
                    color: _getTypeColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Skip checkbox
          CheckboxListTile(
            title: const Text('Import this book', style: TextStyle(fontSize: 13)),
            value: item.shouldImport,
            onChanged: (value) {
              onChanged(item.copyWith(shouldImport: value ?? false));
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          // Book details (editable)
          _EditableDetailRow(
            label: 'Title',
            value: item.book.name ?? '',
            isHighlighted: _isFieldNew(item, 'name'),
            onChanged: (value) => _updateField('name', value),
            oldValue: _getOldValue('name'),
          ),
          _EditableDetailRow(
            label: 'Author',
            value: item.book.author ?? '',
            isHighlighted: _isFieldNew(item, 'author'),
            onChanged: (value) => _updateField('author', value),
            oldValue: _getOldValue('author'),
          ),
          _EditableDetailRow(
            label: 'ISBN',
            value: item.book.isbn ?? '',
            isHighlighted: _isFieldNew(item, 'isbn'),
            onChanged: (value) => _updateField('isbn', value),
            oldValue: _getOldValue('isbn'),
          ),
          _EditableDetailRow(
            label: 'ASIN',
            value: item.book.asin ?? '',
            isHighlighted: _isFieldNew(item, 'asin'),
            onChanged: (value) => _updateField('asin', value),
            oldValue: _getOldValue('asin'),
          ),
          _EditableDetailRow(
            label: 'Saga',
            value: item.book.saga ?? '',
            isHighlighted: _isFieldNew(item, 'saga'),
            onChanged: (value) => _updateField('saga', value),
            oldValue: _getOldValue('saga'),
          ),
          _EditableDetailRow(
            label: 'Saga #',
            value: item.book.nSaga ?? '',
            isHighlighted: _isFieldNew(item, 'nSaga'),
            onChanged: (value) => _updateField('nSaga', value),
            oldValue: _getOldValue('nSaga'),
          ),
          _EditableDetailRow(
            label: 'Saga Universe',
            value: item.book.sagaUniverse ?? '',
            isHighlighted: _isFieldNew(item, 'sagaUniverse'),
            onChanged: (value) => _updateField('sagaUniverse', value),
            oldValue: _getOldValue('sagaUniverse'),
          ),
          _EditableDetailRow(
            label: 'Format Saga',
            value: item.book.formatSagaValue ?? '',
            isHighlighted: _isFieldNew(item, 'formatSaga'),
            onChanged: (value) => _updateField('formatSaga', value),
            oldValue: _getOldValue('formatSaga'),
          ),
          _EditableDetailRow(
            label: 'Pages',
            value: item.book.pages?.toString() ?? '',
            isHighlighted: _isFieldNew(item, 'pages'),
            onChanged: (value) => _updateField('pages', value),
            keyboardType: TextInputType.number,
            oldValue: _getOldValue('pages'),
          ),
          _EditableDetailRow(
            label: 'Year',
            value: item.book.originalPublicationYear?.toString() ?? '',
            isHighlighted: _isFieldNew(item, 'year'),
            onChanged: (value) => _updateField('year', value),
            keyboardType: TextInputType.number,
            oldValue: _getOldValue('year'),
          ),
          _EditableDetailRow(
            label: 'Status',
            value: item.book.statusValue ?? '',
            isHighlighted: _isFieldNew(item, 'status'),
            onChanged: (value) => _updateField('status', value),
            oldValue: _getOldValue('status'),
          ),
          _EditableDetailRow(
            label: 'Editorial',
            value: item.book.editorialValue ?? '',
            isHighlighted: _isFieldNew(item, 'editorial'),
            onChanged: (value) => _updateField('editorial', value),
            oldValue: _getOldValue('editorial'),
          ),
          _EditableDetailRow(
            label: 'Language',
            value: item.book.languageValue ?? '',
            isHighlighted: _isFieldNew(item, 'language'),
            onChanged: (value) => _updateField('language', value),
            oldValue: _getOldValue('language'),
          ),
          _EditableDetailRow(
            label: 'Place',
            value: item.book.placeValue ?? '',
            isHighlighted: _isFieldNew(item, 'place'),
            onChanged: (value) => _updateField('place', value),
            oldValue: _getOldValue('place'),
          ),
          _EditableDetailRow(
            label: 'Format',
            value: item.book.formatValue ?? '',
            isHighlighted: _isFieldNew(item, 'format'),
            onChanged: (value) => _updateField('format', value),
            oldValue: _getOldValue('format'),
          ),
          _EditableDetailRow(
            label: 'Loaned',
            value: item.book.loaned == true ? 'Yes' : 'No',
            isHighlighted: _isFieldNew(item, 'loaned'),
            onChanged: (value) => _updateField('loaned', value),
            oldValue: _getOldValue('loaned'),
          ),
          _EditableDetailRow(
            label: 'Genre',
            value: item.book.genre ?? '',
            isHighlighted: _isFieldNew(item, 'genre'),
            onChanged: (value) => _updateField('genre', value),
            oldValue: _getOldValue('genre'),
          ),
          _EditableDetailRow(
            label: 'Date Read Start',
            value: item.book.dateReadInitial ?? '',
            isHighlighted: _isFieldNew(item, 'dateReadInitial'),
            onChanged: (value) => _updateField('dateReadInitial', value),
            oldValue: _getOldValue('dateReadInitial'),
          ),
          _EditableDetailRow(
            label: 'Date Read Finished',
            value: item.book.dateReadFinal ?? '',
            isHighlighted: _isFieldNew(item, 'dateReadFinal'),
            onChanged: (value) => _updateField('dateReadFinal', value),
            oldValue: _getOldValue('dateReadFinal'),
          ),
          _EditableDetailRow(
            label: 'Read Count',
            value: item.book.readCount?.toString() ?? '',
            isHighlighted: _isFieldNew(item, 'readCount'),
            onChanged: (value) => _updateField('readCount', value),
            keyboardType: TextInputType.number,
            oldValue: _getOldValue('readCount'),
          ),
          _EditableDetailRow(
            label: 'My Rating',
            value: item.book.myRating?.toString() ?? '',
            isHighlighted: _isFieldNew(item, 'rating'),
            onChanged: (value) => _updateField('rating', value),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            oldValue: _getOldValue('rating'),
          ),
          _EditableDetailRow(
            label: 'My Review',
            value: item.book.myReview ?? '',
            isHighlighted: _isFieldNew(item, 'review'),
            onChanged: (value) => _updateField('review', value),
            oldValue: _getOldValue('review'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _EditableDetailRow extends StatefulWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final Function(String) onChanged;
  final TextInputType? keyboardType;
  final String? oldValue; // For showing previous value in updates
  final int? maxLines;

  const _EditableDetailRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isHighlighted = false,
    this.keyboardType,
    this.oldValue,
    this.maxLines = 1,
  });

  @override
  State<_EditableDetailRow> createState() => _EditableDetailRowState();
}

class _EditableDetailRowState extends State<_EditableDetailRow> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_EditableDetailRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _stopEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show all fields, even empty ones
    // if (widget.value.isEmpty && (widget.oldValue == null || widget.oldValue!.isEmpty)) {
    //   return const SizedBox.shrink();
    // }

    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              '${widget.label}:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child:
                _isEditing
                    ? TextFormField(
                      controller: _controller,
                      onChanged: widget.onChanged,
                      keyboardType: widget.keyboardType,
                      maxLines: widget.maxLines,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // X icon to revert to old value (only when there's an old value)
                            if (widget.oldValue != null &&
                                widget.oldValue!.isNotEmpty &&
                                widget.oldValue != widget.value)
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  widget.onChanged(widget.oldValue!);
                                  _controller.text = widget.oldValue!;
                                  _stopEditing();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                tooltip: 'Revert to old value',
                              ),
                            // Check icon to confirm
                            IconButton(
                              icon: const Icon(Icons.check, size: 16),
                              onPressed: _stopEditing,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onFieldSubmitted: widget.maxLines == 1 ? (_) => _stopEditing() : null,
                    )
                    : Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _startEditing,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 11, height: 1.3),
                            children: [
                              // Show old value if exists and different
                              if (widget.oldValue != null &&
                                  widget.oldValue!.isNotEmpty &&
                                  widget.oldValue != widget.value)
                                TextSpan(
                                  text: widget.oldValue,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              // Space between old and new
                              if (widget.oldValue != null &&
                                  widget.oldValue!.isNotEmpty &&
                                  widget.oldValue != widget.value)
                                const TextSpan(text: ' → '),
                              // Show new value (or placeholder if empty)
                              TextSpan(
                                text:
                                    widget.value.isEmpty
                                        ? '(empty)'
                                        : widget.value,
                                style: TextStyle(
                                  color:
                                      widget.value.isEmpty
                                          ? Colors.grey[400]
                                          : (widget.isHighlighted
                                              ? Colors.green[700]
                                              : Colors.black87),
                                  fontWeight:
                                      widget.isHighlighted
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  fontStyle:
                                      widget.value.isEmpty
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                            ),
                          ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
