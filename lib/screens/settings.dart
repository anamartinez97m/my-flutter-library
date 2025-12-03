import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/locale_provider.dart';
import 'package:myrandomlibrary/providers/theme_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/admin_csv_import.dart';
import 'package:myrandomlibrary/screens/manage_dropdowns.dart';
import 'package:myrandomlibrary/screens/bundle_migration_screen.dart';
import 'package:myrandomlibrary/utils/csv_import_helper.dart';
import 'package:myrandomlibrary/utils/bundle_migration.dart';
import 'package:myrandomlibrary/utils/reading_session_migration.dart';
import 'package:myrandomlibrary/widgets/tbr_limit_setting.dart';
import 'package:myrandomlibrary/widgets/status_mapping_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAdmin = false;
  Set<String> _enabledFilters = {};

  // Available filters
  static const List<Map<String, String>> _availableFilters = [
    {'key': 'title', 'label': 'Title'},
    {'key': 'isbn', 'label': 'ISBN/ASIN'},
    {'key': 'author', 'label': 'Author'},
    {'key': 'status', 'label': 'Status'},
    {'key': 'format', 'label': 'Format'},
    {'key': 'genre', 'label': 'Genre'},
    {'key': 'language', 'label': 'Language'},
    {'key': 'place', 'label': 'Place'},
    {'key': 'editorial', 'label': 'Editorial'},
    {'key': 'saga', 'label': 'Saga'},
    {'key': 'saga_universe', 'label': 'Saga Universe'},
    {'key': 'format_saga', 'label': 'Format Saga'},
    {'key': 'pages_empty', 'label': 'Pages Empty'},
    {'key': 'is_bundle', 'label': 'Is Bundle'},
    {'key': 'is_tandem', 'label': 'Is Tandem'},
    {'key': 'saga_format_without_saga', 'label': 'Saga Format Without Saga'},
    {'key': 'saga_format_without_nsaga', 'label': 'Saga Format Without N_Saga'},
  ];

  @override
  void initState() {
    super.initState();
    _loadEnabledFilters();
  }

  Future<void> _loadEnabledFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFilters = prefs.getStringList('enabled_filters');
    setState(() {
      if (savedFilters != null) {
        _enabledFilters = savedFilters.toSet();
      } else {
        // Default: enable all filters
        _enabledFilters = _availableFilters.map((f) => f['key']!).toSet();
      }
    });
  }

  Future<void> _saveEnabledFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('enabled_filters', _enabledFilters.toList());
  }

  void _showFiltersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Customize Home Filters'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableFilters.length,
                      itemBuilder: (context, index) {
                        final filter = _availableFilters[index];
                        final key = filter['key']!;
                        final label = filter['label']!;

                        return CheckboxListTile(
                          title: Text(label),
                          value: _enabledFilters.contains(key),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _enabledFilters.add(key);
                              } else {
                                _enabledFilters.remove(key);
                              }
                            });
                            setDialogState(() {}); // Rebuild dialog
                            _saveEnabledFilters();
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _enabledFilters =
                              _availableFilters.map((f) => f['key']!).toSet();
                        });
                        setDialogState(() {}); // Rebuild dialog
                        _saveEnabledFilters();
                      },
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _enabledFilters.clear();
                        });
                        setDialogState(() {}); // Rebuild dialog
                        _saveEnabledFilters();
                      },
                      child: const Text('Clear All'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PopScope(
            canPop: false,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indeterminate spinner (spinning animation)
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(message),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.creating_backup),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get the database path
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final dbPath = db.path;

      // Create backup file name with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupFileName = 'my_library_backup_$timestamp.db';

      // Let user pick a directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save backup',
      );

      if (selectedDirectory == null) {
        // User canceled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backup_canceled),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return;
      }

      // Create the full path for the backup file
      final backupPath = '$selectedDirectory/$backupFileName';

      // Copy the database file
      await File(dbPath).copy(backupPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.backup_created_successfully(backupPath),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Backup error: $e');

      // Check if it's a permission error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') ||
          errorStr.contains('denied') ||
          errorStr.contains('eacces')) {
        // Permission error - try to request again
        if (context.mounted) {
          final shouldRetry = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Permission Required'),
                  content: const Text(
                    'Storage permission is needed to create backups. Would you like to grant permission?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Grant Permission'),
                    ),
                  ],
                ),
          );

          if (shouldRetry == true) {
            // Retry the backup operation
            await _createBackup(context);
          }
        }
      } else {
        // Other error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.error_creating_backup(e.toString()),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _importFromCsv(BuildContext context) async {
    try {
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select CSV file',
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled the picker
      }

      final filePath = result.files.single.path!;

      // Validate it's a CSV file
      if (!filePath.toLowerCase().endsWith('.csv')) {
        throw Exception('Please select a CSV file');
      }

      // Read file with proper encoding handling
      String input;
      try {
        input = File(filePath).readAsStringSync();
      } catch (e) {
        throw Exception('Failed to read CSV file: $e');
      }

      // Check if file is empty
      if (input.trim().isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Parse CSV with better error handling
      List<List<dynamic>> rows;
      try {
        // Configure CSV parser to handle different line endings
        rows = const CsvToListConverter(
          eol: '\n',
          shouldParseNumbers: false,
        ).convert(input);

        // If we got only 1 row, try with different line ending
        if (rows.length == 1) {
          debugPrint('Only 1 row found, trying with \\r\\n line ending...');
          rows = const CsvToListConverter(
            eol: '\r\n',
            shouldParseNumbers: false,
          ).convert(input);
        }

        // If still only 1 row, try with \\r
        if (rows.length == 1) {
          debugPrint('Still 1 row, trying with \\r line ending...');
          rows = const CsvToListConverter(
            eol: '\r',
            shouldParseNumbers: false,
          ).convert(input);
        }
      } catch (e) {
        throw Exception(
          'Failed to parse CSV file. Please check the file format: $e',
        );
      }

      if (rows.isEmpty) {
        throw Exception('CSV file appears to be empty or invalid');
      }

      // Filter out completely empty rows (all cells are null or empty)
      final nonEmptyRows =
          rows.where((row) {
            if (row.isEmpty) return false;
            // Check if at least one cell has meaningful content
            return row.any((cell) {
              if (cell == null) return false;
              final str = cell.toString().trim();
              return str.isNotEmpty && str != '';
            });
          }).toList();

      if (nonEmptyRows.length < 2) {
        throw Exception(
          'CSV file must have at least a header row and one data row. Found ${nonEmptyRows.length} non-empty row(s). Please check your CSV file format.',
        );
      }

      // Use filtered rows for the rest of the import
      rows = nonEmptyRows;

      // Detect CSV format
      final headers = rows[0];
      final csvFormat = CsvImportHelper.detectCsvFormat(headers);

      if (csvFormat == CsvFormat.unknown) {
        throw Exception('Unknown CSV format. Please check the file structure.');
      }

      // For Format 1 (non-Goodreads), show status mapping dialog
      Map<String, String>? statusMappings;
      if (csvFormat == CsvFormat.format1) {
        if (context.mounted) {
          // Get predefined status values from database
          final db = await DatabaseHelper.instance.database;
          final statusList = await db.query('status', columns: ['value']);
          final predefinedStatuses =
              statusList.map((s) => s['value'] as String).toList();

          // Show mapping dialog
          statusMappings = await showDialog<Map<String, String>>(
            context: context,
            barrierDismissible: false,
            builder:
                (context) =>
                    StatusMappingDialog(predefinedStatuses: predefinedStatuses),
          );

          // User canceled
          if (statusMappings == null) {
            return;
          }
        }
      }

      // Show loading indicator
      if (context.mounted) {
        _showLoadingDialog(context, 'Importing books from CSV...');
      }

      // Get database and repository (ensure it's open)
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Verify database is open
      if (!db.isOpen) {
        throw Exception('Database is not open. Please restart the app.');
      }

      // Log current database state
      final currentBooks = await repository.getAllBooks();
      final tbReleasedBooks =
          currentBooks
              .where((b) => b.statusValue?.toLowerCase() == 'tbreleased')
              .toList();
      debugPrint('=== Before Import ===');
      debugPrint('Total books in database: ${currentBooks.length}');
      debugPrint('TBReleased books: ${tbReleasedBooks.length}');
      for (var book in tbReleasedBooks) {
        debugPrint(
          '  - ${book.name ?? '(no title)'} by ${book.author} (${book.saga} #${book.nSaga})',
        );
      }

      // Parse all books first to show import choice dialog
      final List<_BookImportItem> importItems = [];
      final Set<String> allTags = {};
      debugPrint('=== Parsing CSV for Import Choice ===');
      debugPrint('Processing ${rows.length - 1} rows from CSV');

      // Create header map for efficient lookups
      final headerMap = <String, int>{};
      for (int j = 0; j < headers.length; j++) {
        headerMap[headers[j].toString().toLowerCase()] = j;
      }

      // Skip header row (index 0) and process data rows
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        // Skip empty rows
        if (row.isEmpty ||
            row.every(
              (cell) => cell == null || cell.toString().trim().isEmpty,
            )) {
          continue;
        }

        try {
          // Extract tags from bookshelves if available (for Goodreads format)
          List<String> bookTags = [];
          if (csvFormat == CsvFormat.format2 && headerMap.containsKey('bookshelves')) {
            final bookshelvesIndex = headerMap['bookshelves'];
            if (bookshelvesIndex != null && bookshelvesIndex < row.length) {
              final bookshelves = row[bookshelvesIndex]?.toString();
              if (bookshelves != null && bookshelves.isNotEmpty) {
                bookTags = bookshelves.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
                allTags.addAll(bookTags);
              }
            }
          }

          // Parse book from CSV based on format
          final book = CsvImportHelper.parseBookFromCsv(
            row,
            csvFormat,
            headers,
          );

          if (book == null) {
            continue;
          }

          // Map status value to existing database value
          String? mappedStatus;
          if (csvFormat == CsvFormat.format1 && statusMappings != null) {
            // Use user-provided mappings for Format 1
            final bookStatusLower = book.statusValue?.toLowerCase().trim();
            if (bookStatusLower != null &&
                statusMappings.containsKey(bookStatusLower)) {
              mappedStatus = statusMappings[bookStatusLower];
            } else {
              // If no mapping found, keep original value
              mappedStatus = book.statusValue;
            }
          } else {
            // For Format 2 (Goodreads), use automatic mapping
            final dbHelper = DatabaseHelper();
            mappedStatus = await CsvImportHelper.mapStatusValue(
              book.statusValue,
              dbHelper,
            );
          }

          // Create book with mapped status
          final bookWithMappedStatus = Book(
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
            statusValue: mappedStatus,
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
            existingBook = bookWithMappedStatus; // Simplified for settings import
          } else {
            importType = 'DUPLICATE';
          }

          importItems.add(
            _BookImportItem(
              book: bookWithMappedStatus,
              importType: importType,
              duplicateIds: duplicateIds,
              existingBook: existingBook,
              tags: bookTags,
            ),
          );
        } catch (e) {
          debugPrint('Error parsing row $i: $e');
        }
      }

      debugPrint('=== Parse Complete ===');
      debugPrint('Total books parsed: ${importItems.length}');
      debugPrint('Available tags: ${allTags.length}');

      // Show import choice dialog
      Map<String, dynamic>? importChoice;
      if (context.mounted) {
        importChoice = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _ImportChoiceDialog(
            availableTags: allTags.toList()..sort(),
            csvFormat: csvFormat == CsvFormat.format1 ? 'Format 1' : 'Goodreads',
          ),
        );
      }

      if (importChoice == null) {
        // User canceled - close loading dialog
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        return;
      }

      // Filter books based on user choice
      List<_BookImportItem> selectedItems;
      if (importChoice['importFromTag'] == true) {
        final selectedTag = importChoice['selectedTag'] as String;
        selectedItems = importItems.where((item) => item.tags.contains(selectedTag)).toList();
        debugPrint('=== Importing from tag: $selectedTag ===');
        debugPrint('Books with tag: ${selectedItems.length}');
      } else {
        selectedItems = importItems;
        debugPrint('=== Importing All Books ===');
        debugPrint('Total books to import: ${selectedItems.length}');
      }

      // Now process the selected books
      int importedCount = 0;
      int skippedCount = 0;
      int updatedCount = 0;
      final List<String> skippedReasons = [];

      for (final item in selectedItems) {
        try {
          if (item.importType == 'NEW') {
            await repository.addBook(item.book);
            importedCount++;
          } else if (item.importType == 'UPDATE' &&
              item.duplicateIds.isNotEmpty) {
            // Update all existing books with the same ISBN
            for (final duplicateId in item.duplicateIds) {
              await repository.updateBookWithNewData(
                duplicateId,
                item.book,
              );
              updatedCount++;
            }
          } else {
            skippedCount++;
            skippedReasons.add('Duplicate: ${item.book.name}');
          }
        } catch (e) {
          skippedCount++;
          skippedReasons.add('Error importing ${item.book.name}: $e');
          debugPrint('Error importing ${item.book.name}: $e');
        }
      }

      // Log summary
      debugPrint('=== CSV Import Summary ===');
      debugPrint('Total rows processed: ${rows.length - 1}');
      debugPrint('Imported: $importedCount');
      debugPrint('Updated: $updatedCount');
      debugPrint('Skipped: $skippedCount');
      if (skippedReasons.isNotEmpty) {
        debugPrint('Skipped reasons:');
        for (final reason in skippedReasons) {
          debugPrint('  - $reason');
        }
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Reload the books in the provider
      if (context.mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        // Show results in modal dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    const SizedBox(width: 8),
                    const Text('Import Completed'),
                  ],
                ),
                content: Text(
                  'Imported: $importedCount books\nUpdated: $updatedCount books\nSkipped: $skippedCount rows',
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint('CSV Import Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // Close any open dialogs to prevent black screen
      if (context.mounted) {
        try {
          // Try to pop any dialogs that might be open
          Navigator.of(
            context,
            rootNavigator: true,
          ).popUntil((route) => route.isFirst);
        } catch (popError) {
          debugPrint('Error closing dialogs: $popError');
        }
      }

      // Wait a bit to ensure dialogs are closed
      await Future.delayed(const Duration(milliseconds: 100));

      // Show error dialog
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Import Error'),
                content: SingleChildScrollView(
                  child: Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _deleteAllData(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.delete_all_data),
            content: Text(
              AppLocalizations.of(context)!.delete_all_data_confirmation,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(AppLocalizations.of(context)!.delete_all_data),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (context.mounted) {
      _showLoadingDialog(context, 'Deleting all books...');
    }

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      // Get all books
      final allBooks = await repository.getAllBooks();

      // Delete each book (this will also delete related records)
      for (final book in allBooks) {
        if (book.bookId != null) {
          await repository.deleteBook(book.bookId!);
        }
      }

      // Reset auto-increment counters for all tables
      await db.execute("DELETE FROM sqlite_sequence WHERE name='book'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='author'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='genre'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='editorial'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='status'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='language'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='place'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='format'");
      await db.execute("DELETE FROM sqlite_sequence WHERE name='format_saga'");

      debugPrint('Reset all auto-increment IDs to 0');

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Reload books in provider
      if (context.mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.deleted_books(allBooks.length),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.error_deleting_data(e.toString()),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _migrateReadingSessions(BuildContext context) async {
    // Get statistics first
    final stats = await ReadingSessionMigration.getStats();

    if (!stats.needsMigration) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No reading sessions to migrate. All sessions are already on individual books!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 8),
                Text('Migrate Reading Sessions?'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will migrate ${stats.oldStyleSessions} reading session${stats.oldStyleSessions == 1 ? '' : 's'} '
                  'from ${stats.bundlesWithOldSessions} bundle${stats.bundlesWithOldSessions == 1 ? '' : 's'} '
                  'to individual books.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'What will happen:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  '• Reading sessions will be copied to individual books\n'
                  '• Old bundle reading sessions will be deleted\n'
                  '• This fixes inconsistencies in bundle reading history',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ℹ️ This is safe and can be run multiple times',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Migrate'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (context.mounted) {
      _showLoadingDialog(context, 'Migrating reading sessions...');
    }

    try {
      final result = await ReadingSessionMigration.migrateAllReadingSessions();

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show result dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  result.hasErrors
                      ? 'Migration Completed with Errors'
                      : 'Migration Successful!',
                  style: TextStyle(
                    color: result.hasErrors ? Colors.orange : Colors.green,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ Successful: ${result.successfulBundles} bundles'),
                      Text('⏭️  Skipped: ${result.skippedBundles} bundles'),
                      Text('❌ Failed: ${result.failedBundles} bundles'),
                      Text(
                        '📚 Total sessions migrated: ${result.totalSessionsMigrated}',
                      ),
                      if (result.errors.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Errors:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...result.errors.map(
                          (error) => Text(
                            '• $error',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );

        // Refresh the settings screen to update badges
        setState(() {});
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error migrating reading sessions: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      // Pick database backup file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: AppLocalizations.of(context)!.select_backup_file,
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled
      }

      final backupPath = result.files.single.path!;

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.import_backup),
              content: Text(
                AppLocalizations.of(context)!.import_backup_confirmation,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context)!.replace_database),
                ),
              ],
            ),
      );

      if (confirmed != true) return;

      // Get current database path before closing
      final db = await DatabaseHelper.instance.database;
      final dbPath = db.path;

      // Close the database
      await DatabaseHelper.instance.closeDatabase();

      // Replace database file
      await File(backupPath).copy(dbPath);

      // Reinitialize database (this will open the new database)
      await DatabaseHelper.instance.database;

      // Reload books in provider
      if (context.mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.database_restored_successfully,
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        AppLocalizations.of(context)!.import_backup_error(e.toString()),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.error_importing_backup(e.toString()),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _exportToCsv(BuildContext context) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preparing CSV export...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Get all books from the database
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final allBooks = await repository.getAllBooks();

      if (allBooks.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No books to export'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Create CSV data
      List<List<dynamic>> csvData = [];

      // Add header row
      csvData.add([
        'Title',
        'Author',
        'ISBN',
        'ASIN',
        'Saga',
        'N_Saga',
        'Saga Universe',
        'Format Saga',
        'Status',
        'Editorial',
        'Language',
        'Place',
        'Format',
        'Genre',
        'Pages',
        'Original Publication Year',
        'Loaned',
        'Date Read Initial',
        'Date Read Final',
        'Read Count',
        'My Rating',
        'My Review',
        'Is Bundle',
        'Bundle Count',
        'Bundle Numbers',
        'Created At',
      ]);

      // Add book data
      for (var book in allBooks) {
        csvData.add([
          book.name ?? '',
          book.author ?? '',
          book.isbn ?? '',
          book.asin ?? '',
          book.saga ?? '',
          book.nSaga ?? '',
          book.sagaUniverse ?? '',
          book.formatSagaValue ?? '',
          book.statusValue ?? '',
          book.editorialValue ?? '',
          book.languageValue ?? '',
          book.placeValue ?? '',
          book.formatValue ?? '',
          book.genre ?? '',
          book.pages?.toString() ?? '',
          book.originalPublicationYear?.toString() ?? '',
          book.loaned ?? '',
          book.dateReadInitial ?? '',
          book.dateReadFinal ?? '',
          book.readCount?.toString() ?? '',
          book.myRating?.toString() ?? '',
          book.myReview ?? '',
          book.isBundle == true ? 'yes' : 'no',
          book.bundleCount?.toString() ?? '',
          book.bundleNumbers ?? '',
          book.createdAt ?? '',
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Create file name with timestamp
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'my_library_export_$timestamp.csv';

      // Let user pick a directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save CSV',
      );

      if (selectedDirectory == null) {
        // User canceled
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export canceled'),
              backgroundColor: Colors.grey,
            ),
          );
        }
        return;
      }

      // Create the full path for the CSV file
      final filePath = '$selectedDirectory/$fileName';

      // Write the CSV file
      await File(filePath).writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${allBooks.length} books to:\n$filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');

      // Check if it's a permission error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') ||
          errorStr.contains('denied') ||
          errorStr.contains('eacces')) {
        // Permission error - try to request again
        if (context.mounted) {
          final shouldRetry = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Permission Required'),
                  content: const Text(
                    'Storage permission is needed to export CSV files. Would you like to grant permission?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Grant Permission'),
                    ),
                  ],
                ),
          );

          if (shouldRetry == true) {
            // Retry the export operation
            await _exportToCsv(context);
          }
        }
      } else {
        // Other error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error exporting to CSV: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Widget _buildLightThemeGrid(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildThemePreview(
          context,
          'Warm Earth',
          [
            const Color(0xFFa36361),
            const Color(0xFFd3a29d),
            const Color(0xFFe8b298),
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.warmEarth,
          () => themeProvider.setLightThemeVariant(LightThemeVariant.warmEarth),
        ),
        _buildThemePreview(
          context,
          'Vibrant Sunset',
          [
            const Color(0xFFef476f),
            const Color(0xFFf78c6b),
            const Color(0xFFffd166),
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.vibrantSunset,
          () => themeProvider.setLightThemeVariant(
            LightThemeVariant.vibrantSunset,
          ),
        ),
        _buildThemePreview(
          context,
          'Soft Pastel',
          [
            const Color(0xFFc8a8e9),
            const Color(0xFFe3aadd),
            const Color(0xFFf5bcba),
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.softPastel,
          () =>
              themeProvider.setLightThemeVariant(LightThemeVariant.softPastel),
        ),
        _buildThemePreview(
          context,
          'Deep Ocean',
          [
            const Color(0xFF14919b),
            const Color(0xFF0ad1c8),
            const Color(0xFF45dfb1),
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.deepOcean,
          () => themeProvider.setLightThemeVariant(LightThemeVariant.deepOcean),
        ),
        _buildThemePreview(
          context,
          'Custom',
          [
            themeProvider.customLightPrimary,
            themeProvider.customLightSecondary,
            themeProvider.customLightTertiary,
          ],
          themeProvider.lightThemeVariant == LightThemeVariant.custom,
          () {
            themeProvider.setLightThemeVariant(LightThemeVariant.custom);
            _showCustomLightPaletteDialog(context, themeProvider);
          },
        ),
      ],
    );
  }

  Widget _buildDarkThemeGrid(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildThemePreview(
          context,
          'Mystic Purple',
          [
            const Color(0xFF854f6c),
            const Color(0xFF522b5b),
            const Color(0xFFdfb6b2),
          ],
          themeProvider.darkThemeVariant == DarkThemeVariant.mysticPurple,
          () =>
              themeProvider.setDarkThemeVariant(DarkThemeVariant.mysticPurple),
        ),
        _buildThemePreview(
          context,
          'Deep Sea',
          [
            const Color(0xFF0c7075),
            const Color(0xFF0f969c),
            const Color(0xFF6da5c0),
          ],
          themeProvider.darkThemeVariant == DarkThemeVariant.deepSea,
          () => themeProvider.setDarkThemeVariant(DarkThemeVariant.deepSea),
        ),
        _buildThemePreview(
          context,
          'Warm Autumn',
          [
            const Color(0xFF662549),
            const Color(0xFFae445a),
            const Color(0xFFf39f5a),
          ],
          themeProvider.darkThemeVariant == DarkThemeVariant.warmAutumn,
          () => themeProvider.setDarkThemeVariant(DarkThemeVariant.warmAutumn),
        ),
        _buildThemePreview(
          context,
          'Custom',
          [
            themeProvider.customDarkPrimary,
            themeProvider.customDarkSecondary,
            themeProvider.customDarkTertiary,
          ],
          themeProvider.darkThemeVariant == DarkThemeVariant.custom,
          () {
            themeProvider.setDarkThemeVariant(DarkThemeVariant.custom);
            _showCustomDarkPaletteDialog(context, themeProvider);
          },
        ),
      ],
    );
  }

  void _showCustomLightPaletteDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Custom Light Palette'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorPickerRow(
                context,
                'Primary',
                themeProvider.customLightPrimary,
                (color) async {
                  await themeProvider.setCustomLightColors(
                    color,
                    themeProvider.customLightSecondary,
                    themeProvider.customLightTertiary,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildColorPickerRow(
                context,
                'Secondary',
                themeProvider.customLightSecondary,
                (color) async {
                  await themeProvider.setCustomLightColors(
                    themeProvider.customLightPrimary,
                    color,
                    themeProvider.customLightTertiary,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildColorPickerRow(
                context,
                'Tertiary',
                themeProvider.customLightTertiary,
                (color) async {
                  await themeProvider.setCustomLightColors(
                    themeProvider.customLightPrimary,
                    themeProvider.customLightSecondary,
                    color,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCustomDarkPaletteDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Custom Dark Palette'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorPickerRow(
                context,
                'Primary',
                themeProvider.customDarkPrimary,
                (color) async {
                  await themeProvider.setCustomDarkColors(
                    color,
                    themeProvider.customDarkSecondary,
                    themeProvider.customDarkTertiary,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildColorPickerRow(
                context,
                'Secondary',
                themeProvider.customDarkSecondary,
                (color) async {
                  await themeProvider.setCustomDarkColors(
                    themeProvider.customDarkPrimary,
                    color,
                    themeProvider.customDarkTertiary,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildColorPickerRow(
                context,
                'Tertiary',
                themeProvider.customDarkTertiary,
                (color) async {
                  await themeProvider.setCustomDarkColors(
                    themeProvider.customDarkPrimary,
                    themeProvider.customDarkSecondary,
                    color,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePreview(
    BuildContext context,
    String name,
    List<Color> colors,
    bool isSelected,
    VoidCallback onTap, {
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children:
                    colors.map((color) {
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius:
                                colors.indexOf(color) == 0
                                    ? const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                    )
                                    : colors.indexOf(color) == colors.length - 1
                                    ? const BorderRadius.only(
                                      topRight: Radius.circular(10),
                                    )
                                    : null,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                  if (isSelected) const SizedBox(width: 4),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16),
            // Admin mode toggle
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                title: const Text('Admin Mode'),
                subtitle: const Text(
                  'Enable advanced features like admin CSV import',
                ),
                value: _isAdmin,
                onChanged: (value) {
                  setState(() {
                    _isAdmin = value ?? false;
                  });
                },
                secondary: const Icon(Icons.admin_panel_settings),
              ),
            ),
            const SizedBox(height: 16),
            // Admin CSV Import (moved to top)
            if (_isAdmin) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminCsvImportScreen(),
                      ),
                    );
                    // If books were imported, reload the provider
                    if (result == true && mounted) {
                      final provider = Provider.of<BookProvider?>(
                        context,
                        listen: false,
                      );
                      await provider?.loadBooks();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Admin CSV Import',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Review and edit each book before importing',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ===== DEFAULT VALUES SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.tune,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Default Values',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                subtitle: const Text('TBR Limit, Sort Order, Home Filters'),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // TBR Limit Setting
                        const TBRLimitSetting(),
                        const SizedBox(height: 16),

                        // Home Filters Configuration
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _showFiltersDialog(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    size: 36,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Customize Home Filters',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Select which filters to show in the home screen',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Default Sort Order setting
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Consumer<BookProvider>(
                              builder: (context, provider, child) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.sort,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Default Sort Order',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Set the default order for your book list',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<String>(
                                      value: provider.currentSortBy,
                                      decoration: const InputDecoration(
                                        labelText: 'Sort By',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'name',
                                          child: Text('Title'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'author',
                                          child: Text('Author'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'created_at',
                                          child: Text('Date Added'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          provider.setDefaultSortOrder(
                                            value,
                                            provider.currentSortAscending,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SegmentedButton<bool>(
                                            segments: const [
                                              ButtonSegment(
                                                value: true,
                                                label: Text('Ascending'),
                                                icon: Icon(
                                                  Icons.arrow_upward,
                                                  size: 16,
                                                ),
                                              ),
                                              ButtonSegment(
                                                value: false,
                                                label: Text('Descending'),
                                                icon: Icon(
                                                  Icons.arrow_downward,
                                                  size: 16,
                                                ),
                                              ),
                                            ],
                                            selected: {
                                              provider.currentSortAscending
                                            },
                                            onSelectionChanged:
                                                (Set<bool> newSelection) {
                                              provider.setDefaultSortOrder(
                                                provider.currentSortBy,
                                                newSelection.first,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== IMPORT/EXPORT SECTION (COLLAPSIBLE) =====
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      Icons.import_export,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Import/Export',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                subtitle: const Text('CSV & Database Backup'),
                initiallyExpanded: false,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Backup and Restore buttons
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _createBackup(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.backup_outlined,
                                          size: 36,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.create_database_backup,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .save_a_copy_of_your_library_database,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _importBackup(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.cloud_download_outlined,
                                          size: 36,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.import_database_backup,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .restore_a_copy_of_your_library_database,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
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
                        const SizedBox(height: 16),

                        // Import from CSV
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _importFromCsv(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    size: 36,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .import_from_csv,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .import_from_csv_file,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.import_from_csv_tbreleased,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Colors.blue[900],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green[200]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.green[700],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'For Goodreads CSV: Books must have "owned" or "read-loaned" in bookshelves to be imported',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: Colors.green[900],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .import_from_csv_hint,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Export to CSV
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () => _exportToCsv(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.file_download,
                                    size: 36,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Export to CSV',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Export all books to a CSV file',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== OTHER SETTINGS (NO GROUPING) =====
            // Manage Dropdown Values
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageDropdownsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 36,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.manage_dropdown_values,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.manage_dropdown_values_hint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delete All Data button
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _deleteAllData(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.delete_forever,
                        size: 36,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.delete_all_data,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.permanently_delete_all_books_from_the_database,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Theme selector
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.palette,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.theme_mode,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        RadioListTile<AppThemeMode>(
                          title: Text(
                            AppLocalizations.of(context)!.theme_light,
                          ),
                          value: AppThemeMode.light,
                          groupValue: themeProvider.themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                        RadioListTile<AppThemeMode>(
                          title: Text(AppLocalizations.of(context)!.theme_dark),
                          value: AppThemeMode.dark,
                          groupValue: themeProvider.themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                        RadioListTile<AppThemeMode>(
                          title: Text(
                            AppLocalizations.of(context)!.theme_system,
                          ),
                          value: AppThemeMode.system,
                          groupValue: themeProvider.themeMode,
                          onChanged: (value) {
                            if (value != null) {
                              themeProvider.setThemeMode(value);
                            }
                          },
                        ),
                        const Divider(height: 32),

                        // Light theme variants
                        Text(
                          AppLocalizations.of(context)!.light_theme_colors,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        _buildLightThemeGrid(context, themeProvider),
                        const SizedBox(height: 24),

                        // Dark theme variants
                        Text(
                          AppLocalizations.of(context)!.dark_theme_colors,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        _buildDarkThemeGrid(context, themeProvider),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Language selector
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.language,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.language,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<LocaleProvider>(
                      builder: (context, localeProvider, _) {
                        return DropdownButtonFormField<String>(
                          value: localeProvider.locale.languageCode,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'en',
                              child: Row(
                                children: [
                                  Text('🇬🇧'),
                                  SizedBox(width: 12),
                                  Text(AppLocalizations.of(context)!.english),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'es',
                              child: Row(
                                children: [
                                  Text('🇪🇸'),
                                  SizedBox(width: 12),
                                  Text(AppLocalizations.of(context)!.spanish),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              localeProvider.setLocale(Locale(value));
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bundle Migration
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sync_alt),
                    title: const Text('Migrate Bundle Books'),
                    subtitle: const Text('Convert old bundles to new system'),
                    trailing: FutureBuilder<bool>(
                      future: BundleMigration.isMigrationNeeded(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        if (snapshot.data == true) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        return const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BundleMigrationScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: const Text('Migrate Reading Sessions'),
                    subtitle: const Text(
                      'Move reading sessions to individual books',
                    ),
                    trailing: FutureBuilder<bool>(
                      future: ReadingSessionMigration.needsMigration(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }

                        if (snapshot.data == true) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Available',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }

                        return const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        );
                      },
                    ),
                    onTap: () => _migrateReadingSessions(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            AboutListTile(
              icon: const Icon(Icons.info_outline),
              applicationName: 'My Random Library',
              applicationVersion: '1.0.0',
              applicationIcon: const FlutterLogo(),
              applicationLegalese:
                  '© 2025 Ana Martínez Montañez. Todos los derechos reservados.',
              aboutBoxChildren: [
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.about_box_children,
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
            const SizedBox(height: 8), // Bottom margin
          ],
        ),
      ),
    );
  }

  Widget _buildColorPickerRow(
    BuildContext context,
    String label,
    Color color,
    Function(Color) onColorChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap:
                    () =>
                        _showColorPickerDialog(context, color, onColorChanged),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '#${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}',
                      style: TextStyle(
                        color:
                            color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showHexInputDialog(color, onColorChanged),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Icon(Icons.palette, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    Color initialColor,
    Function(Color) onColorChanged,
  ) {
    Color selectedColor = initialColor;
    bool showHueSlider = false;
    double hue = HSVColor.fromColor(initialColor).hue;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Pick a Color'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Big square showing current color
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '#${selectedColor.value.toRadixString(16).toUpperCase().padLeft(8, '0')}',
                              style: TextStyle(
                                color:
                                    selectedColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 7 quick color options + 1 hue picker
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            // 7 quick color options
                            _buildColorOption(
                              const Color(0xFFa36361),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFFef476f),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFFc8a8e9),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF14919b),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF854f6c),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF0c7075),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF662549),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                  showHueSlider = false;
                                });
                              },
                            ),
                            // 8th square: colorized palette icon for hue picker
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  showHueSlider = !showHueSlider;
                                  hue = HSVColor.fromColor(selectedColor).hue;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.palette,
                                  color: selectedColor.computeLuminance() > 0.5
                                      ? Colors.black54
                                      : Colors.white54,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Hue slider (shown when palette icon is tapped)
                        if (showHueSlider) ...[
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hue',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: LinearGradient(
                                    colors: [
                                      HSVColor.fromAHSV(1, 0, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 60, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 120, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 180, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 240, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 300, 1, 1).toColor(),
                                      HSVColor.fromAHSV(1, 360, 1, 1).toColor(),
                                    ],
                                  ),
                                ),
                                child: Slider(
                                  value: hue,
                                  min: 0,
                                  max: 360,
                                  onChanged: (newHue) {
                                    setDialogState(() {
                                      hue = newHue;
                                      selectedColor =
                                          HSVColor.fromAHSV(
                                            1,
                                            hue,
                                            1,
                                            1,
                                          ).toColor();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onColorChanged(selectedColor);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildColorOption(
    Color color,
    Color selectedColor,
    Function(Color) onTap,
  ) {
    final isSelected = color.value == selectedColor.value;
    return GestureDetector(
      onTap: () => onTap(color),
      onLongPress: () => _showHexInputDialog(color, onTap),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }

  void _showHexInputDialog(Color initialColor, Function(Color) onColorChanged) {
    Color selectedColor = initialColor;
    double hue = HSVColor.fromColor(initialColor).hue;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Pick a Custom Color'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 150,
                          height: 80,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '#${selectedColor.value.toRadixString(16).toUpperCase().padLeft(8, '0')}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hue',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  colors: [
                                    HSVColor.fromAHSV(1, 0, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 60, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 120, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 180, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 240, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 300, 1, 1).toColor(),
                                    HSVColor.fromAHSV(1, 360, 1, 1).toColor(),
                                  ],
                                ),
                              ),
                              child: Slider(
                                value: hue,
                                min: 0,
                                max: 360,
                                onChanged: (newHue) {
                                  setDialogState(() {
                                    hue = newHue;
                                    selectedColor =
                                        HSVColor.fromAHSV(
                                          1,
                                          hue,
                                          1,
                                          1,
                                        ).toColor();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildColorOption(
                              const Color(0xFFa36361),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFFef476f),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFFc8a8e9),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF14919b),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF854f6c),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF0c7075),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                            _buildColorOption(
                              const Color(0xFF662549),
                              selectedColor,
                              (color) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onColorChanged(selectedColor);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
          ),
    );
  }
}

// Book import item class for import processing
class _BookImportItem {
  final Book book;
  final String importType; // 'NEW', 'UPDATE', 'DUPLICATE'
  final List<int> duplicateIds;
  final Book? existingBook;
  final List<String> tags;

  _BookImportItem({
    required this.book,
    required this.importType,
    required this.duplicateIds,
    this.existingBook,
    this.tags = const [],
  });
}

// Simple import choice dialog
class _ImportChoiceDialog extends StatefulWidget {
  final List<String> availableTags;
  final String csvFormat;

  const _ImportChoiceDialog({
    required this.availableTags,
    required this.csvFormat,
  });

  @override
  State<_ImportChoiceDialog> createState() => _ImportChoiceDialogState();
}

class _ImportChoiceDialogState extends State<_ImportChoiceDialog> {
  String? _selectedTag;
  bool _importFromTag = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.import_export, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Import Options (${widget.csvFormat})',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RadioListTile<bool>(
              title: const Text('Import All Books'),
              value: false,
              groupValue: _importFromTag,
              onChanged: (value) {
                setState(() {
                  _importFromTag = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (widget.availableTags.isNotEmpty) ...[
              RadioListTile<bool>(
                title: const Text('Import from Tag'),
                value: true,
                groupValue: _importFromTag,
                onChanged: (value) {
                  setState(() {
                    _importFromTag = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_importFromTag) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTag,
                  decoration: const InputDecoration(
                    labelText: 'Select tag',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tag),
                    isDense: true,
                  ),
                  isExpanded: true,
                  items: widget.availableTags.map((tag) => DropdownMenuItem(
                    value: tag,
                    child: Text(
                      tag,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTag = value;
                    });
                  },
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_importFromTag && _selectedTag == null) ? null : () {
            Navigator.pop(context, {
              'importFromTag': _importFromTag,
              'selectedTag': _selectedTag,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(_importFromTag ? 'Import from Tag' : 'Import All Books'),
        ),
      ],
    );
  }
}
