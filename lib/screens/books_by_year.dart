import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';

class BooksByYearScreen extends StatefulWidget {
  final int initialYear;

  const BooksByYearScreen({
    super.key,
    required this.initialYear,
  });

  @override
  State<BooksByYearScreen> createState() => _BooksByYearScreenState();
}

class _BooksByYearScreenState extends State<BooksByYearScreen> {
  late int _selectedYear;
  List<int> _availableYears = [];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  Future<List<int>> _loadYears() async {
    final db = await DatabaseHelper.instance.database;
    final repository = BookRepository(db);
    return await repository.getYearsWithReadBooks();
  }

  Future<List<Book>> _loadBooksForYear(int year) async {
    final db = await DatabaseHelper.instance.database;
    final repository = BookRepository(db);
    final booksData = await repository.getBooksReadInYear(year);
    return booksData.map((data) => Book.fromMap(data)).toList();
  }

  /// Try to parse date with multiple formats
  DateTime? _tryParseDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;
    
    final trimmed = dateStr.trim();
    
    // Try ISO8601 format first (handles YYYY-MM-DD and full timestamps)
    try {
      return DateTime.parse(trimmed);
    } catch (e) {
      // Check if it contains slashes - likely YYYY/MM/DD format
      if (trimmed.contains('/')) {
        try {
          final parts = trimmed.split('/');
          if (parts.length == 3) {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            
            // Validate it's YYYY/MM/DD (year should be > 1900)
            if (year > 1900) {
              return DateTime(year, month, day);
            }
          }
        } catch (e) {
          // Failed to parse
        }
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books by Year'),
      ),
      body: FutureBuilder<List<int>>(
        future: _loadYears(),
        builder: (context, yearsSnapshot) {
          if (!yearsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _availableYears = yearsSnapshot.data!;
          
          // Ensure selected year is valid
          if (_availableYears.isNotEmpty && !_availableYears.contains(_selectedYear)) {
            _selectedYear = _availableYears.first;
          }

          return FutureBuilder<List<Book>>(
            future: _loadBooksForYear(_selectedYear),
            builder: (context, booksSnapshot) {
              if (!booksSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final booksForYear = booksSnapshot.data!;

          return Column(
            children: [
              // Year selector
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Row(
                  children: [
                    const Text(
                      'Year: ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        items: _availableYears.map((year) {
                          // Show year with count from current selection
                          final count = year == _selectedYear ? booksForYear.length : 0;
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year == _selectedYear ? '$year ($count books)' : '$year'),
                          );
                        }).toList(),
                        onChanged: (year) {
                          if (year != null) {
                            setState(() {
                              _selectedYear = year;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Books list
              Expanded(
                child: booksForYear.isEmpty
                    ? const Center(
                        child: Text('No books read in this year'),
                      )
                    : ListView.builder(
                        itemCount: booksForYear.length,
                        itemBuilder: (context, index) {
                          final book = booksForYear[index];
                          return _buildBookCard(context, book);
                        },
                      ),
              ),
            ],
          );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Book book) {
    // Parse date for display
    String dateStr = '';
    if (book.dateReadFinal != null) {
      final date = _tryParseDate(book.dateReadFinal!);
      if (date != null) {
        dateStr = '${date.day}/${date.month}/${date.year}';
      } else {
        dateStr = book.dateReadFinal!;
      }
    }

    // Build subtitle info list - only author, finished date, and pages
    final List<String> subtitleParts = [];
    if (book.author != null && book.author!.isNotEmpty) {
      subtitleParts.add(book.author!);
    }
    if (dateStr.isNotEmpty) {
      subtitleParts.add('Finished: $dateStr');
    }
    if (book.pages != null && book.pages! > 0) {
      subtitleParts.add('${book.pages} pages');
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          book.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitleParts.isNotEmpty
            ? Text(subtitleParts.join(' • '))
            : null,
        trailing: book.myRating != null && book.myRating! > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    book.myRating!.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
        },
      ),
    );
  }
}
