import 'package:flutter/material.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:provider/provider.dart';

class BooksByAuthorScreen extends StatelessWidget {
  final List<String> authors;

  const BooksByAuthorScreen({
    super.key,
    required this.authors,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Author'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If single author, show simple screen
    if (authors.length == 1) {
      return _buildSingleAuthorScreen(context, authors.first, provider);
    }

    // If multiple authors, show tabs
    return DefaultTabController(
      length: authors.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Authors'),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: authors.map((author) => Tab(text: author)).toList(),
          ),
        ),
        body: TabBarView(
          children: authors.map((author) {
            return _buildAuthorContent(context, author, provider);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSingleAuthorScreen(BuildContext context, String author, BookProvider provider) {
    return Scaffold(
      appBar: AppBar(
        title: Text(author),
      ),
      body: _buildAuthorContent(context, author, provider),
    );
  }

  Widget _buildAuthorContent(BuildContext context, String author, BookProvider provider) {
    // Filter books by author (case-insensitive, handles comma-separated authors)
    final filteredBooks = provider.allBooks.where((book) {
      if (book.author == null) return false;
      final bookAuthors = book.author!.split(',').map((a) => a.trim().toLowerCase()).toList();
      return bookAuthors.contains(author.toLowerCase());
    }).toList();

    // Calculate average rating for read books with ratings
    final readBooksWithRating = filteredBooks.where((book) {
      return book.statusValue?.toLowerCase() == 'yes' && 
             book.myRating != null && 
             book.myRating! > 0;
    }).toList();

    double? averageRating;
    if (readBooksWithRating.isNotEmpty) {
      final totalRating = readBooksWithRating.fold<double>(
        0.0,
        (sum, book) => sum + (book.myRating ?? 0),
      );
      averageRating = totalRating / readBooksWithRating.length;
    }

    // Sort books by publication year (if available) or alphabetically
    filteredBooks.sort((a, b) {
      final aYear = a.originalPublicationYear;
      final bYear = b.originalPublicationYear;

      if (aYear != null && bYear != null) {
        return aYear.compareTo(bYear);
      } else if (aYear != null) {
        return -1;
      } else if (bYear != null) {
        return 1;
      }

      // Fallback to alphabetical sorting
      return (a.name ?? '').compareTo(b.name ?? '');
    });

    return filteredBooks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No books found for this author',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // Header card with stats
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${filteredBooks.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total Books',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (averageRating != null)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.amber[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber[700],
                                    size: 28,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Average Rating',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Books list
              Expanded(
                child: ListView.builder(
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    final isRead = book.statusValue?.toLowerCase() == 'yes';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailScreen(book: book),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isRead 
                              ? Colors.grey[300]?.withOpacity(0.3)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.name ?? 'Untitled',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: isRead 
                                                ? FontWeight.normal
                                                : FontWeight.w500,
                                            color: isRead
                                                ? Colors.grey[700]
                                                : null,
                                          ),
                                    ),
                                    if (book.saga != null && book.saga!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          book.nSaga != null && book.nSaga!.isNotEmpty
                                              ? '${book.saga} #${book.nSaga}'
                                              : book.saga!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Show release date for TBReleased books, publication year for others
                              if (book.statusValue?.toLowerCase() == 'tbreleased' && 
                                  book.notificationDatetime != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Builder(
                                    builder: (context) {
                                      try {
                                        final dateStr = book.notificationDatetime!;
                                        DateTime releaseDate;
                                        
                                        // Parse YYYYMMDD format (e.g., "20260210")
                                        if (dateStr.length == 8 && int.tryParse(dateStr) != null) {
                                          final year = int.parse(dateStr.substring(0, 4));
                                          final month = int.parse(dateStr.substring(4, 6));
                                          final day = int.parse(dateStr.substring(6, 8));
                                          releaseDate = DateTime(year, month, day);
                                        } else {
                                          // Try ISO format as fallback
                                          releaseDate = DateTime.parse(dateStr);
                                        }
                                        
                                        final now = DateTime.now();
                                        final today = DateTime(now.year, now.month, now.day);
                                        final releaseDateOnly = DateTime(releaseDate.year, releaseDate.month, releaseDate.day);
                                        
                                        String displayText;
                                        if (releaseDateOnly.isBefore(today)) {
                                          // Past date: show DD/MM/YYYY
                                          displayText = '${releaseDate.day.toString().padLeft(2, '0')}/${releaseDate.month.toString().padLeft(2, '0')}/${releaseDate.year}';
                                        } else {
                                          // Future date: show only year
                                          displayText = '${releaseDate.year}';
                                        }
                                        
                                        return Text(
                                          displayText,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        );
                                      } catch (e) {
                                        return const SizedBox.shrink();
                                      }
                                    },
                                  ),
                                )
                              else if (book.originalPublicationYear != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    '${book.originalPublicationYear}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}
