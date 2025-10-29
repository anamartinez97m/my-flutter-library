import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/locale_provider.dart';
import 'package:myrandomlibrary/providers/theme_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/manage_dropdowns.dart';
import 'package:myrandomlibrary/utils/csv_import_helper.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          const SnackBar(
            content: Text('Creating backup...'),
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
            const SnackBar(
              content: Text('Backup canceled'),
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
            content: Text('Backup created successfully!\n$backupPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Backup error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating backup: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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

      final input = File(filePath).readAsStringSync();

      // Parse CSV
      final rows = const CsvToListConverter().convert(input);

      if (rows.isEmpty || rows.length < 2) {
        throw Exception(
          'CSV file must have at least a header row and one data row',
        );
      }

      // Detect CSV format
      final headers = rows[0];
      final csvFormat = CsvImportHelper.detectCsvFormat(headers);

      if (csvFormat == CsvFormat.unknown) {
        throw Exception('Unknown CSV format. Please check the file structure.');
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

      int importedCount = 0;
      int skippedCount = 0;
      int duplicateCount = 0;
      final List<String> duplicateBooks = [];
      final List<String> skippedReasons = [];

      debugPrint('=== Starting Import ===');
      debugPrint('Processing ${rows.length - 1} rows from CSV');

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
          // Parse book from CSV based on format
          final book = CsvImportHelper.parseBookFromCsv(
            row,
            csvFormat,
            headers,
          );

          if (book == null) {
            skippedCount++;
            skippedReasons.add(
              'Row $i: Failed to parse (possibly filtered out)',
            );
            debugPrint('Row $i: Book parsed as null (filtered or invalid)');
            continue;
          }

          // Detailed logging for first 5 rows and rows around 215-220
          final showDetails = i <= 5 || (i >= 215 && i <= 220);
          if (showDetails) {
            debugPrint(
              'Row $i: Checking "${book.name ?? '(no title)'}" (ISBN: ${book.isbn ?? '(no ISBN)'}) Status: ${book.statusValue}',
            );
          }

          // Check for duplicates
          final duplicateId = await repository.findDuplicateBook(book);
          if (duplicateId != null) {
            duplicateCount++;
            final displayName = book.name ?? '(no title)';
            final displayInfo =
                book.isbn != null
                    ? 'ISBN: ${book.isbn}'
                    : (book.saga != null
                        ? 'Saga: ${book.saga} #${book.nSaga}'
                        : 'N/A');
            duplicateBooks.add('$displayName ($displayInfo)');
            if (showDetails) {
              debugPrint(
                'Row $i: DUPLICATE found - "${book.name ?? '(no title)'}" matches book_id $duplicateId',
              );
            }
            continue;
          }

          final newBookId = await repository.addBook(book);
          importedCount++;
          if (showDetails) {
            debugPrint(
              'Row $i: IMPORTED - "${book.name ?? '(no title)'}" (${book.statusValue}) as book_id $newBookId',
            );
          }
        } catch (e) {
          skippedCount++;
          skippedReasons.add('Row $i: Error - $e');
          debugPrint('Error importing row $i: $e');
        }
      }

      // Log summary
      debugPrint('=== CSV Import Summary ===');
      debugPrint('Total rows processed: ${rows.length - 1}');
      debugPrint('Imported: $importedCount');
      debugPrint('Duplicates: $duplicateCount');
      debugPrint('Skipped: $skippedCount');
      if (skippedReasons.isNotEmpty) {
        debugPrint('Skipped reasons:');
        for (final reason in skippedReasons) {
          debugPrint('  - $reason');
        }
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Reload the books in the provider
      if (context.mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

        // Show results with duplicates info
        if (duplicateCount > 0) {
          _showDuplicatesDialog(
            context,
            importedCount,
            skippedCount,
            duplicateCount,
            duplicateBooks,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Import completed!\nImported: $importedCount books\nSkipped: $skippedCount rows',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing CSV: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
            title: const Text('Delete All Data?'),
            content: const Text(
              'This will permanently delete ALL books from your library. '
              'This action cannot be undone!\n\n'
              'Are you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete All'),
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
            content: Text('Deleted ${allBooks.length} books successfully'),
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
            content: Text('Error deleting data: $e'),
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
        dialogTitle: 'Select database backup file',
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
              title: const Text('Import Database Backup'),
              content: const Text(
                'This will replace your current database with the backup. '
                'All current data will be lost. Are you sure?',
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
                  child: const Text('Replace Database'),
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
          const SnackBar(
            content: Text('Database restored successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Import backup error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing backup: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showDuplicatesDialog(
    BuildContext context,
    int importedCount,
    int skippedCount,
    int duplicateCount,
    List<String> duplicateBooks,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Import Completed with Duplicates'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Imported: $importedCount books'),
                  Text('Skipped: $skippedCount rows'),
                  Text('Duplicates found: $duplicateCount books'),
                  const SizedBox(height: 16),
                  const Text(
                    'Duplicate books (not imported):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...duplicateBooks
                      .take(10)
                      .map(
                        (book) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 4),
                          child: Text('• $book'),
                        ),
                      ),
                  if (duplicateBooks.length > 10)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text(
                        '... and ${duplicateBooks.length - 10} more',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'These books already exist in your library. You can add them manually if needed.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
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
            Card(
              elevation: 2,
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
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Create Database Backup',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save a copy of your library database',
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
            Card(
              elevation: 2,
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
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Import Database Backup',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Restore a copy of your library database',
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
            Card(
              elevation: 2,
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
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Import from CSV',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Import books from a CSV file (.csv)',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
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
                                'For unreleased books, use status: TBReleased',
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
                      const SizedBox(height: 12),
                      Text(
                        'Expected columns: read, name, author, editorial, genre, saga, n_saga, format_saga, isbn, pages, publication_year, language, place, format, loaned',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Manage Dropdown Values',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add, edit, or remove values for Status, Language, Place, Format, and Format Saga',
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
                        'Delete All Data',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Permanently delete all books from the database',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette, color: Colors.deepPurple),
                        const SizedBox(width: 12),
                        Text(
                          'Theme',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return Column(
                          children: [
                            RadioListTile<AppThemeMode>(
                              title: const Text('Light'),
                              value: AppThemeMode.light,
                              groupValue: themeProvider.themeMode,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setThemeMode(value);
                                }
                              },
                            ),
                            RadioListTile<AppThemeMode>(
                              title: const Text('Dark'),
                              value: AppThemeMode.dark,
                              groupValue: themeProvider.themeMode,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setThemeMode(value);
                                }
                              },
                            ),
                            RadioListTile<AppThemeMode>(
                              title: const Text('System'),
                              value: AppThemeMode.system,
                              groupValue: themeProvider.themeMode,
                              onChanged: (value) {
                                if (value != null) {
                                  themeProvider.setThemeMode(value);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
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
                        const Icon(Icons.language, color: Colors.deepPurple),
                        const SizedBox(width: 12),
                        Text(
                          'Language',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
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
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Row(
                                children: [
                                  Text('🇬🇧'),
                                  SizedBox(width: 12),
                                  Text('English'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'es',
                              child: Row(
                                children: [
                                  Text('🇪🇸'),
                                  SizedBox(width: 12),
                                  Text('Español'),
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

            AboutListTile(
              icon: const Icon(Icons.info_outline),
              applicationName: 'My Random Library',
              applicationVersion: '1.0.0',
              applicationIcon: const FlutterLogo(),
              applicationLegalese:
                  '© 2025 Ana Martínez Montañez. Todos los derechos reservados.',
              aboutBoxChildren: [
                const SizedBox(height: 16),
                const Text(
                  'Aplicación desarrollada con Flutter/Dart.\n'
                  'Permite gestionar tu biblioteca personal y recibir recomendaciones de lectura personalizadas.',
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
}
