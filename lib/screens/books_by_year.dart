import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';

class BooksByYearScreen extends StatefulWidget {
  final int initialYear;

  const BooksByYearScreen({super.key, required this.initialYear});

  @override
  State<BooksByYearScreen> createState() => _BooksByYearScreenState();
}

class _BooksByYearScreenState extends State<BooksByYearScreen> {
  late int _selectedYear;
  List<int> _availableYears = [];
  final Map<int, int> _yearBookCounts = {};

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  Future<List<int>> _loadYears() async {
    final db = await DatabaseHelper.instance.database;
    final repository = BookRepository(db);
    final years = await repository.getYearsWithReadBooks();

    // Load book counts for all years
    for (var year in years) {
      final booksData = await repository.getBooksReadInYear(year);
      _yearBookCounts[year] = booksData.length;
    }

    return years;
  }

  Future<List<Map<String, dynamic>>> _loadBooksForYear(int year) async {
    final db = await DatabaseHelper.instance.database;
    final repository = BookRepository(db);
    final booksData = await repository.getBooksReadInYear(year);

    // Return the raw data with bundle_book_index for proper display
    return booksData.map((data) {
      final mappedData = Map<String, dynamic>.from(data);
      if (mappedData.containsKey('latest_read_date')) {
        mappedData['date_read_final'] = mappedData['latest_read_date'];
      }
      return mappedData;
    }).toList();
  }

  String _getDisplayName(Map<String, dynamic> bookData) {
    final book = Book.fromMap(bookData);
    final bundleIndex = bookData['bundle_book_index'] as int?;

    if (book.isBundle == true && bundleIndex != null) {
      // Extract title from bundle_titles if available
      String? bundleBookTitle;
      if (book.bundleTitles != null) {
        try {
          final List<dynamic> titles = jsonDecode(book.bundleTitles!);
          if (bundleIndex < titles.length && titles[bundleIndex] != null) {
            bundleBookTitle = titles[bundleIndex] as String?;
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
      }

      if (bundleBookTitle != null && bundleBookTitle.isNotEmpty) {
        return '${book.name} - Book ${bundleIndex + 1}: $bundleBookTitle';
      } else {
        return '${book.name} - Book ${bundleIndex + 1}';
      }
    }

    return book.name ?? 'Unknown';
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

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return month >= 1 && month <= 12 ? monthNames[month] : '';
  }

  int _getItemCount(List<Map<String, dynamic>> booksData) {
    if (booksData.isEmpty) return 0;

    int count = 0;
    int? lastMonth;

    for (var bookData in booksData) {
      final dateReadFinal = bookData['date_read_final'] as String?;
      if (dateReadFinal != null) {
        final date = _tryParseDate(dateReadFinal);
        if (date != null) {
          if (lastMonth != date.month) {
            count++; // Add month header
            lastMonth = date.month;
          }
        }
      }
      count++; // Add book card
    }

    return count;
  }

  Widget _buildItem(
    BuildContext context,
    List<Map<String, dynamic>> booksData,
    int index,
  ) {
    int currentIndex = 0;
    int? lastMonth;

    for (var i = 0; i < booksData.length; i++) {
      final bookData = booksData[i];
      final dateReadFinal = bookData['date_read_final'] as String?;

      // Check if we need a month header
      if (dateReadFinal != null) {
        final date = _tryParseDate(dateReadFinal);
        if (date != null && lastMonth != date.month) {
          if (currentIndex == index) {
            // Return month header
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Text(
                _getMonthName(date.month),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
          }
          currentIndex++;
          lastMonth = date.month;
        }
      }

      // Check if this is the book card we're looking for
      if (currentIndex == index) {
        return _buildBookCard(context, bookData);
      }
      currentIndex++;
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Books by Year')),
      body: FutureBuilder<List<int>>(
        future: _loadYears(),
        builder: (context, yearsSnapshot) {
          if (!yearsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _availableYears = yearsSnapshot.data!;

          // Ensure selected year is valid
          if (_availableYears.isNotEmpty &&
              !_availableYears.contains(_selectedYear)) {
            _selectedYear = _availableYears.first;
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadBooksForYear(_selectedYear),
            builder: (context, booksSnapshot) {
              if (!booksSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final booksDataForYear = booksSnapshot.data!;

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
                            items:
                                _availableYears.map((year) {
                                  final count = _yearBookCounts[year] ?? 0;
                                  return DropdownMenuItem<int>(
                                    value: year,
                                    child: Text('$year ($count books)'),
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
                  // Books list with month separators
                  Expanded(
                    child:
                        booksDataForYear.isEmpty
                            ? const Center(
                              child: Text('No books read in this year'),
                            )
                            : ListView.builder(
                              itemCount: _getItemCount(booksDataForYear),
                              itemBuilder: (context, index) {
                                return _buildItem(
                                  context,
                                  booksDataForYear,
                                  index,
                                );
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

  Widget _buildBookCard(BuildContext context, Map<String, dynamic> bookData) {
    final book = Book.fromMap(bookData);
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
          _getDisplayName(bookData),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle:
            subtitleParts.isNotEmpty ? Text(subtitleParts.join(' • ')) : null,
        trailing:
            book.myRating != null && book.myRating! > 0
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
