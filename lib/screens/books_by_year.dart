import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:provider/provider.dart';

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
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          final books = provider.allBooks; // Use all books, not filtered

          // Calculate available years from books (including bundle books)
          final yearsSet = <int>{};
          for (var book in books) {
            // Handle bundle books with multiple end dates
            if (book.isBundle == true && book.bundleEndDates != null) {
              try {
                final List<dynamic> endDates = jsonDecode(book.bundleEndDates!);
                for (var dateStr in endDates) {
                  if (dateStr != null) {
                    final date = _tryParseDate(dateStr.toString());
                    if (date != null) {
                      yearsSet.add(date.year);
                    }
                  }
                }
              } catch (e) {
                // If bundle dates parsing fails, try regular date
                if (book.dateReadFinal != null) {
                  final dateRead = _tryParseDate(book.dateReadFinal!);
                  if (dateRead != null) {
                    yearsSet.add(dateRead.year);
                  }
                }
              }
            } else if (book.dateReadFinal != null) {
              final dateRead = _tryParseDate(book.dateReadFinal!);
              if (dateRead != null) {
                yearsSet.add(dateRead.year);
              }
            }
          }
          _availableYears = yearsSet.toList()..sort((a, b) => b.compareTo(a));

          // Filter books for selected year (including bundle books)
          final booksForYear = books.where((book) {
            // Handle bundle books with multiple end dates
            if (book.isBundle == true && book.bundleEndDates != null) {
              try {
                final List<dynamic> endDates = jsonDecode(book.bundleEndDates!);
                // Check if ANY of the bundle books were finished in the selected year
                for (var dateStr in endDates) {
                  if (dateStr != null) {
                    final date = _tryParseDate(dateStr.toString());
                    if (date != null && date.year == _selectedYear) {
                      return true;
                    }
                  }
                }
              } catch (e) {
                // If bundle dates parsing fails, try regular date
                if (book.dateReadFinal != null) {
                  final dateRead = _tryParseDate(book.dateReadFinal!);
                  return dateRead != null && dateRead.year == _selectedYear;
                }
              }
              return false;
            } else if (book.dateReadFinal != null) {
              final dateRead = _tryParseDate(book.dateReadFinal!);
              return dateRead != null && dateRead.year == _selectedYear;
            }
            return false;
          }).toList();

          // Sort by date read (most recent first)
          booksForYear.sort((a, b) {
            final dateA = _tryParseDate(a.dateReadFinal ?? '');
            final dateB = _tryParseDate(b.dateReadFinal ?? '');
            if (dateA != null && dateB != null) {
              return dateB.compareTo(dateA);
            }
            return 0;
          });

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
                          // Count books for this year (including bundle books)
                          final count = books.where((book) {
                            // Handle bundle books
                            if (book.isBundle == true && book.bundleEndDates != null) {
                              try {
                                final List<dynamic> endDates = jsonDecode(book.bundleEndDates!);
                                for (var dateStr in endDates) {
                                  if (dateStr != null) {
                                    final date = _tryParseDate(dateStr.toString());
                                    if (date != null && date.year == year) {
                                      return true;
                                    }
                                  }
                                }
                              } catch (e) {
                                // If bundle parsing fails, try regular date
                                if (book.dateReadFinal != null) {
                                  final dateRead = _tryParseDate(book.dateReadFinal!);
                                  return dateRead != null && dateRead.year == year;
                                }
                              }
                              return false;
                            } else if (book.dateReadFinal != null) {
                              final dateRead = _tryParseDate(book.dateReadFinal!);
                              return dateRead != null && dateRead.year == year;
                            }
                            return false;
                          }).length;

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
