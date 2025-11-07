import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:provider/provider.dart';

class BooksByDecadeScreen extends StatefulWidget {
  final String initialDecade;

  const BooksByDecadeScreen({
    super.key,
    required this.initialDecade,
  });

  @override
  State<BooksByDecadeScreen> createState() => _BooksByDecadeScreenState();
}

class _BooksByDecadeScreenState extends State<BooksByDecadeScreen> {
  late String _selectedDecade;
  List<String> _availableDecades = [];

  @override
  void initState() {
    super.initState();
    _selectedDecade = widget.initialDecade;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books by Decade'),
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          final books = provider.allBooks; // Use all books, not filtered

          // Calculate available decades from books (only books with read_count > 0)
          final decadesSet = <String>{};
          for (var book in books) {
            if (book.readCount != null && book.readCount! > 0 && 
                book.originalPublicationYear != null) {
              int pubYear = book.originalPublicationYear!;
              
              // Handle full date format (YYYYMMDD)
              if (pubYear > 9999) {
                pubYear = pubYear ~/ 10000;
              }
              
              // Calculate decade
              final decade = (pubYear ~/ 10) * 10;
              decadesSet.add('${decade}s');
            }
          }
          _availableDecades = decadesSet.toList()..sort((a, b) {
            final aDecade = int.parse(a.replaceAll('s', ''));
            final bDecade = int.parse(b.replaceAll('s', ''));
            return bDecade.compareTo(aDecade);
          });

          // Filter books for selected decade (only books with read_count > 0)
          final booksForDecade = books.where((book) {
            if (book.readCount == null || book.readCount! <= 0 || 
                book.originalPublicationYear == null) {
              return false;
            }
            
            int pubYear = book.originalPublicationYear!;
            
            // Handle full date format (YYYYMMDD)
            if (pubYear > 9999) {
              pubYear = pubYear ~/ 10000;
            }
            
            // Calculate decade
            final decade = (pubYear ~/ 10) * 10;
            final decadeLabel = '${decade}s';
            
            return decadeLabel == _selectedDecade;
          }).toList();

          // Sort by date read (most recent first)
          booksForDecade.sort((a, b) {
            try {
              if (a.dateReadFinal != null && b.dateReadFinal != null) {
                final dateA = DateTime.parse(a.dateReadFinal!.trim());
                final dateB = DateTime.parse(b.dateReadFinal!.trim());
                return dateB.compareTo(dateA);
              }
            } catch (e) {
              // Fall through to default
            }
            return 0;
          });

          return Column(
            children: [
              // Decade selector
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Row(
                  children: [
                    const Text(
                      'Decade: ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedDecade,
                        isExpanded: true,
                        items: _availableDecades.map((decade) {
                          // Count books for this decade
                          final count = books.where((book) {
                            if (book.readCount == null || book.readCount! <= 0 || 
                                book.originalPublicationYear == null) {
                              return false;
                            }
                            
                            int pubYear = book.originalPublicationYear!;
                            
                            // Handle full date format (YYYYMMDD)
                            if (pubYear > 9999) {
                              pubYear = pubYear ~/ 10000;
                            }
                            
                            // Calculate decade
                            final decadeNum = (pubYear ~/ 10) * 10;
                            final decadeLabel = '${decadeNum}s';
                            
                            return decadeLabel == decade;
                          }).length;

                          // Calculate total book count (including bundles)
                          int totalCount = 0;
                          for (var book in books) {
                            if (book.readCount == null || book.readCount! <= 0 || 
                                book.originalPublicationYear == null) {
                              continue;
                            }
                            
                            int pubYear = book.originalPublicationYear!;
                            if (pubYear > 9999) {
                              pubYear = pubYear ~/ 10000;
                            }
                            
                            final decadeNum = (pubYear ~/ 10) * 10;
                            final decadeLabel = '${decadeNum}s';
                            
                            if (decadeLabel == decade) {
                              final multiplier = (book.isBundle == true && book.bundleCount != null && book.bundleCount! > 0) 
                                  ? book.bundleCount! 
                                  : 1;
                              totalCount += multiplier;
                            }
                          }

                          return DropdownMenuItem<String>(
                            value: decade,
                            child: Text('$decade ($totalCount books)'),
                          );
                        }).toList(),
                        onChanged: (decade) {
                          if (decade != null) {
                            setState(() {
                              _selectedDecade = decade;
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
                child: booksForDecade.isEmpty
                    ? const Center(
                        child: Text('No books read from this decade'),
                      )
                    : ListView.builder(
                        itemCount: booksForDecade.length,
                        itemBuilder: (context, index) {
                          final book = booksForDecade[index];
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
    // Get original publication year
    String pubYearStr = '';
    if (book.originalPublicationYear != null) {
      int pubYear = book.originalPublicationYear!;
      
      // Handle full date format (YYYYMMDD)
      if (pubYear > 9999) {
        pubYear = pubYear ~/ 10000;
      }
      
      pubYearStr = '$pubYear';
    }

    // Build subtitle info list - only author, publication year, and pages
    final List<String> subtitleParts = [];
    if (book.author != null && book.author!.isNotEmpty) {
      subtitleParts.add(book.author!);
    }
    if (pubYearStr.isNotEmpty) {
      subtitleParts.add('Published: $pubYearStr');
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
