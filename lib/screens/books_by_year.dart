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
          final books = provider.books;

          // Calculate available years from books
          final yearsSet = <int>{};
          for (var book in books) {
            if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
              try {
                final dateRead = DateTime.parse(book.dateReadFinal!);
                yearsSet.add(dateRead.year);
              } catch (e) {
                // Skip invalid dates
              }
            }
          }
          _availableYears = yearsSet.toList()..sort((a, b) => b.compareTo(a));

          // Filter books for selected year
          final booksForYear = books.where((book) {
            if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
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
                          // Count books for this year
                          final count = books.where((book) {
                            if (book.dateReadFinal != null &&
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          book.name ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.author != null && book.author!.isNotEmpty)
              Text('By ${book.author}'),
            if (dateStr.isNotEmpty) Text('Read: $dateStr'),
            if (book.pages != null && book.pages! > 0)
              Text('${book.pages} pages'),
          ],
        ),
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
