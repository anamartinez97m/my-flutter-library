import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/utils/csv_import_helper.dart';
import 'package:provider/provider.dart';

class AdminCsvImportScreen extends StatefulWidget {
  const AdminCsvImportScreen({super.key});

  @override
  State<AdminCsvImportScreen> createState() => _AdminCsvImportScreenState();
}

class _AdminCsvImportScreenState extends State<AdminCsvImportScreen> {
  List<_BookImportItem> _importItems = [];
  bool _isLoading = false;
  int _currentIndex = 0;

  Future<void> _selectAndParseCsv() async {
    try {
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select CSV file',
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;

      if (!filePath.toLowerCase().endsWith('.csv')) {
        throw Exception('Please select a CSV file');
      }

      setState(() {
        _isLoading = true;
      });

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
        throw Exception('CSV file must have at least a header and one data row');
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

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
          continue;
        }

        try {
          final book = CsvImportHelper.parseBookFromCsv(row, csvFormat, headers);
          if (book == null) continue;

          // Map status
          final dbHelper = DatabaseHelper();
          final mappedStatus = await CsvImportHelper.mapStatusValue(book.statusValue, dbHelper);
          
          final bookWithMappedStatus = Book(
            bookId: book.bookId,
            name: book.name,
            isbn: book.isbn,
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
          final duplicateIds = await repository.findDuplicateBooks(bookWithMappedStatus);
          
          String importType;
          if (duplicateIds.isEmpty) {
            importType = 'NEW';
          } else if (duplicateIds.length == 1) {
            importType = 'UPDATE';
          } else {
            importType = 'DUPLICATE';
          }

          items.add(_BookImportItem(
            book: bookWithMappedStatus,
            importType: importType,
            duplicateIds: duplicateIds,
            shouldImport: true,
          ));
        } catch (e) {
          debugPrint('Error parsing row $i: $e');
        }
      }

      setState(() {
        _importItems = items;
        _isLoading = false;
        _currentIndex = 0;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        if (!item.shouldImport) {
          skipped++;
          continue;
        }

        if (item.importType == 'NEW') {
          await repository.addBook(item.book);
          imported++;
        } else if (item.importType == 'UPDATE' && item.duplicateIds.isNotEmpty) {
          for (final id in item.duplicateIds) {
            await repository.updateBookWithNewData(id, item.book);
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

        // Show results
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Complete'),
            content: Text('Imported: $imported\nUpdated: $updated\nSkipped: $skipped'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to settings
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
              label: const Text('Import All', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
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
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _currentIndex > 0
                                  ? () {
                                      setState(() {
                                        _currentIndex--;
                                      });
                                    }
                                  : null,
                              child: const Text('Previous'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _currentIndex < _importItems.length - 1
                                  ? () {
                                      setState(() {
                                        _currentIndex++;
                                      });
                                    }
                                  : null,
                              child: const Text('Next'),
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

class _BookImportItem {
  final Book book;
  final String importType; // 'NEW', 'UPDATE', 'DUPLICATE'
  final List<int> duplicateIds;
  final bool shouldImport;

  _BookImportItem({
    required this.book,
    required this.importType,
    required this.duplicateIds,
    required this.shouldImport,
  });

  _BookImportItem copyWith({
    Book? book,
    String? importType,
    List<int>? duplicateIds,
    bool? shouldImport,
  }) {
    return _BookImportItem(
      book: book ?? this.book,
      importType: importType ?? this.importType,
      duplicateIds: duplicateIds ?? this.duplicateIds,
      shouldImport: shouldImport ?? this.shouldImport,
    );
  }
}

class _BookImportPreview extends StatelessWidget {
  final _BookImportItem item;
  final Function(_BookImportItem) onChanged;

  const _BookImportPreview({
    required this.item,
    required this.onChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Import type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const SizedBox(height: 16),
          // Skip checkbox
          CheckboxListTile(
            title: const Text('Import this book'),
            value: item.shouldImport,
            onChanged: (value) {
              onChanged(item.copyWith(shouldImport: value ?? false));
            },
          ),
          const SizedBox(height: 16),
          // Book details (read-only for now)
          _DetailRow(label: 'Title', value: item.book.name ?? ''),
          _DetailRow(label: 'Author', value: item.book.author ?? ''),
          _DetailRow(label: 'ISBN', value: item.book.isbn ?? ''),
          _DetailRow(label: 'Saga', value: item.book.saga ?? ''),
          _DetailRow(label: 'Saga #', value: item.book.nSaga ?? ''),
          _DetailRow(label: 'Pages', value: item.book.pages?.toString() ?? ''),
          _DetailRow(label: 'Year', value: item.book.originalPublicationYear?.toString() ?? ''),
          _DetailRow(label: 'Status', value: item.book.statusValue ?? ''),
          _DetailRow(label: 'Editorial', value: item.book.editorialValue ?? ''),
          _DetailRow(label: 'Language', value: item.book.languageValue ?? ''),
          _DetailRow(label: 'Place', value: item.book.placeValue ?? ''),
          _DetailRow(label: 'Format', value: item.book.formatValue ?? ''),
          _DetailRow(label: 'Genre', value: item.book.genre ?? ''),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
