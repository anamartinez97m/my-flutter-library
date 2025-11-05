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
                  if (dateStr != null && dateStr.toString().isNotEmpty) {
                    try {
                      final date = DateTime.parse(dateStr);
                      yearsSet.add(date.year);
                    } catch (e) {
                      // Skip invalid dates
                    }
                  }
                }
              } catch (e) {
                // If bundle dates parsing fails, try regular date
                if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
                  try {
                    final dateRead = DateTime.parse(book.dateReadFinal!);
                    yearsSet.add(dateRead.year);
                  } catch (e) {
                    // Skip invalid dates
                  }
                }
              }
            } else if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
              try {
                final dateRead = DateTime.parse(book.dateReadFinal!);
                yearsSet.add(dateRead.year);
              } catch (e) {
                // Skip invalid dates
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
                  if (dateStr != null && dateStr.toString().isNotEmpty) {
                    try {
                      final date = DateTime.parse(dateStr);
                      if (date.year == _selectedYear) {
                        return true;
                      }
                    } catch (e) {
                      // Skip invalid dates
                    }
                  }
                }
              } catch (e) {
                // If bundle dates parsing fails, try regular date
                if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
                  try {
                    final dateRead = DateTime.parse(book.dateReadFinal!);
                    return dateRead.year == _selectedYear;
                  } catch (e) {
                    return false;
                  }
                }
              }
              return false;
            } else if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
              try {
                final dateRead = DateTime.parse(book.dateReadFinal!);
                return dateRead.year == _selectedYear;
              } catch (e) {
                return false;
              }
            }
            return false;
          }).toList();

          // Sort by date read (most recent first)
          booksForYear.sort((a, b) {
            try {
              final dateA = DateTime.parse(a.dateReadFinal!);
              final dateB = DateTime.parse(b.dateReadFinal!);
              return dateB.compareTo(dateA);
            } catch (e) {
              return 0;
            }
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
                                  if (dateStr != null && dateStr.toString().isNotEmpty) {
                                    try {
                                      final date = DateTime.parse(dateStr);
                                      if (date.year == year) {
                                        return true;
                                      }
                                    } catch (e) {
                                      // Skip invalid dates
                                    }
                                  }
                                }
                              } catch (e) {
                                // If bundle parsing fails, try regular date
                                if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
                                  try {
                                    final dateRead = DateTime.parse(book.dateReadFinal!);
                                    return dateRead.year == year;
                                  } catch (e) {
                                    return false;
                                  }
                                }
                              }
                              return false;
                            } else if (book.dateReadFinal != null &&
                                book.dateReadFinal!.isNotEmpty) {
                              try {
                                final dateRead =
                                    DateTime.parse(book.dateReadFinal!);
                                return dateRead.year == year;
                              } catch (e) {
                                return false;
                              }
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
    if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
      try {
        final date = DateTime.parse(book.dateReadFinal!);
        dateStr = '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        dateStr = book.dateReadFinal!;
      }
    }

    // Build subtitle info list
    final List<String> subtitleParts = [];
    if (book.author != null && book.author!.isNotEmpty) {
      subtitleParts.add('By ${book.author}');
    }
    if (book.editorialValue != null && book.editorialValue!.isNotEmpty) {
      subtitleParts.add(book.editorialValue!);
    }
    if (book.formatValue != null && book.formatValue!.isNotEmpty) {
      subtitleParts.add(book.formatValue!);
    }
    if (dateStr.isNotEmpty) {
      subtitleParts.add('Read: $dateStr');
    }
    if (book.pages != null && book.pages! > 0) {
      subtitleParts.add('${book.pages} pages');
    }
    // Show bundle info if it's a bundle
    if (book.isBundle == true && book.bundleCount != null && book.bundleCount! > 0) {
      subtitleParts.add('Bundle (${book.bundleCount} books)');
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
