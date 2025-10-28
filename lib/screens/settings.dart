import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mylibrary/db/database_helper.dart';
import 'package:mylibrary/model/book.dart';
import 'package:mylibrary/providers/book_provider.dart';
import 'package:mylibrary/repositories/book_repository.dart';
import 'package:mylibrary/screens/manage_dropdowns.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled the picker
      }

      final filePath = result.files.single.path!;
      final input = File(filePath).readAsStringSync();

      // Parse CSV
      final rows = const CsvToListConverter().convert(input);

      if (rows.isEmpty || rows.length < 2) {
        throw Exception(
          'CSV file must have at least a header row and one data row',
        );
      }

      // Get database and repository
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      int importedCount = 0;
      int skippedCount = 0;

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
          // Expected columns: read, name, author, editorial, genre, saga, n_saga,
          // format_saga, isbn, pages, publication_year, language, place, format, loaned
          final statusValue = row.length > 0 ? row[0]?.toString().trim() : '';
          final name = row.length > 1 ? row[1]?.toString().trim() : '';
          final author = row.length > 2 ? row[2]?.toString().trim() : '';
          final editorial = row.length > 3 ? row[3]?.toString().trim() : '';
          final genre = row.length > 4 ? row[4]?.toString().trim() : '';
          final saga = row.length > 5 ? row[5]?.toString().trim() : '';
          final nSaga = row.length > 6 ? row[6]?.toString().trim() : '';
          final formatSaga = row.length > 7 ? row[7]?.toString().trim() : '';
          final isbn = row.length > 8 ? row[8]?.toString().trim() : '';
          final pagesStr = row.length > 9 ? row[9]?.toString().trim() : '';
          final pubYearStr = row.length > 10 ? row[10]?.toString().trim() : '';
          final language = row.length > 11 ? row[11]?.toString().trim() : '';
          final place = row.length > 12 ? row[12]?.toString().trim() : '';
          final format = row.length > 13 ? row[13]?.toString().trim() : '';
          final loaned = row.length > 14 ? row[14]?.toString().trim() : '';

          if (name?.isEmpty ?? true) {
            skippedCount++;
            continue;
          }

          final book = Book(
            bookId: null,
            name: name?.isEmpty ?? true ? null : name,
            isbn: isbn?.isEmpty ?? true ? null : isbn,
            author: author?.isEmpty ?? true ? null : author,
            saga: saga?.isEmpty ?? true ? null : saga,
            nSaga: nSaga?.isEmpty ?? true ? null : nSaga,
            formatSagaValue: formatSaga?.isEmpty ?? true ? null : formatSaga,
            pages: pagesStr?.isEmpty ?? true ? null : int.tryParse(pagesStr!),
            originalPublicationYear:
                pubYearStr?.isEmpty ?? true ? null : int.tryParse(pubYearStr!),
            loaned: loaned?.isEmpty ?? true ? null : loaned,
            statusValue: statusValue?.isEmpty ?? true ? null : statusValue,
            editorialValue: editorial?.isEmpty ?? true ? null : editorial,
            languageValue: language?.isEmpty ?? true ? null : language,
            placeValue: place?.isEmpty ?? true ? null : place,
            formatValue: format?.isEmpty ?? true ? null : format,
            createdAt: DateTime.now().toIso8601String(),
            genre: genre?.isEmpty ?? true ? null : genre,
          );

          await repository.addBook(book);
          importedCount++;
        } catch (e) {
          skippedCount++;
          debugPrint('Error importing row $i: $e');
        }
      }

      // Reload the books in the provider
      if (context.mounted) {
        final provider = Provider.of<BookProvider?>(context, listen: false);
        await provider?.loadBooks();

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
    } catch (e) {
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
                      Icon(Icons.backup, size: 36, color: Colors.deepPurple),
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
                      Icon(Icons.settings, size: 36, color: Colors.deepPurple),
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
            const SizedBox(height: 24), // Bottom margin
          ],
        ),
      ),
    );
  }
}
