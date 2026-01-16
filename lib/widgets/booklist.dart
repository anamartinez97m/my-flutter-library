import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookListView extends StatefulWidget {
  final List<Book> books;

  const BookListView({super.key, required this.books});

  @override
  State<BookListView> createState() => _BookListViewState();
}

class _BookListViewState extends State<BookListView> {
  Set<String> _enabledCardFields = {};

  @override
  void initState() {
    super.initState();
    _loadEnabledCardFields();
  }

  Future<void> _loadEnabledCardFields() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCardFields = prefs.getStringList('enabled_card_fields');
    setState(() {
      if (savedCardFields != null) {
        _enabledCardFields = savedCardFields.toSet();
      } else {
        // Default: show essential fields
        _enabledCardFields = {'title', 'author', 'saga', 'format', 'language'};
      }
    });
  }

  Future<bool> _isOriginalBookRead(int originalBookId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'book',
        columns: ['status_id'],
        where: 'book_id = ?',
        whereArgs: [originalBookId],
      );
      if (result.isNotEmpty) {
        final statusId = result.first['status_id'];
        final statusResult = await db.query(
          'status',
          columns: ['value'],
          where: 'status_id = ?',
          whereArgs: [statusId],
        );
        if (statusResult.isNotEmpty) {
          return statusResult.first['value']?.toString().toLowerCase() == 'yes';
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.books.length,
      itemBuilder: (BuildContext context, int index) {
        final Book book = widget.books[index];
        // Check if book is read (status is 'yes' case-insensitive)
        final isRead = book.statusValue?.toLowerCase() == 'yes';
        final isRepeated = book.statusValue?.toLowerCase() == 'repeated';

        // For repeated books, check if original is read
        Widget cardWidget;
        if (isRepeated && book.originalBookId != null) {
          cardWidget = FutureBuilder<bool>(
            future: _isOriginalBookRead(book.originalBookId!),
            builder: (context, snapshot) {
              final originalIsRead = snapshot.data ?? false;
              return _buildCard(context, book, isRead, originalIsRead);
            },
          );
        } else {
          cardWidget = _buildCard(context, book, isRead, false);
        }

        return cardWidget;
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    Book book,
    bool isRead,
    bool originalIsRead,
  ) {
    // Determine background color
    Color? backgroundColor;
    if (isRead) {
      backgroundColor = Colors.grey.shade200;
    } else if (originalIsRead) {
      // Repeated book whose original is read - use a distinct color
      backgroundColor = Colors.grey.shade200;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Title row with icons
              if (_enabledCardFields.contains('title')) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        book.name ?? AppLocalizations.of(context)!.unknown_title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    if (book.isTandem == true) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.swap_horizontal_circle_outlined,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                      Icon(
                        Icons.alt_route_outlined,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                    ],
                    if (book.tbr == true) ...[
                      Icon(
                        Icons.bookmark_add,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                    ],
                    if (book.isBundle == true) ...[
                      Icon(
                        Icons.library_books,
                        size: 18,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
              ],
              
              // Author
              if (_enabledCardFields.contains('author') && 
                  book.author != null && book.author!.isNotEmpty) ...[
                Text(
                  AppLocalizations.of(context)!.author_with_colon(book.author ?? ''),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
              ],
              
              // Saga
              if (_enabledCardFields.contains('saga') && 
                  book.saga != null && book.saga!.isNotEmpty) ...[
                Text(
                  AppLocalizations.of(context)!.saga_with_colon(book.saga ?? '') +
                      (book.nSaga != null && book.nSaga!.isNotEmpty
                          ? ' #${book.nSaga}'
                          : ''),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 3),
              ],
              
              // Format and Language (combined for efficiency)
              if ((_enabledCardFields.contains('format') || _enabledCardFields.contains('language')) &&
                  (book.formatValue != null || book.languageValue != null)) ...[
                Text(
                  [
                    if (_enabledCardFields.contains('format'))
                      AppLocalizations.of(context)!.format_with_colon(book.formatValue ?? 'N/A'),
                    if (_enabledCardFields.contains('language'))
                      AppLocalizations.of(context)!.language_with_colon(book.languageValue ?? 'N/A'),
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
              ],
              
              // ISBN/ASIN
              if (_enabledCardFields.contains('isbn') && 
                  (book.isbn != null || book.asin != null)) ...[
                Text(
                  'ISBN/ASIN: ${book.isbn ?? book.asin ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
              ],
              
              // Pages
              if (_enabledCardFields.contains('pages') && 
                  book.pages != null) ...[
                Text(
                  'Pages: ${book.pages}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
              ],
              
              // Genre
              if (_enabledCardFields.contains('genre') && 
                  book.genre != null && book.genre!.isNotEmpty) ...[
                Text(
                  'Genre: ${book.genre}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
              ],
              
              // Editorial
              if (_enabledCardFields.contains('editorial') && 
                  book.editorialValue != null && book.editorialValue!.isNotEmpty) ...[
                Text(
                  'Editorial: ${book.editorialValue}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
              ],
              
              // Publication Year
              if (_enabledCardFields.contains('publication_year') && 
                  book.originalPublicationYear != null) ...[
                Text(
                  'Published: ${book.originalPublicationYear}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
              ],
              
              // Publication Date (shows if date is filled, regardless of notification status)
              if (_enabledCardFields.contains('publication_date') && 
                  book.notificationDatetime != null && 
                  book.notificationDatetime!.isNotEmpty) ...[
                Text(
                  'Publication Date: ${book.notificationDatetime!.split('T')[0]}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
              ],
              
              // Rating
              if (_enabledCardFields.contains('rating') && 
                  book.myRating != null) ...[
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${book.myRating}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
              ],
              
              // Read Count
              if (_enabledCardFields.contains('read_count') && 
                  book.readCount != null && book.readCount! > 0) ...[
                Text(
                  'Read count: ${book.readCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
              ],
              
              // Status
              if (_enabledCardFields.contains('status') && 
                  book.statusValue != null && book.statusValue!.isNotEmpty) ...[
                Text(
                  'Status: ${book.statusValue}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
              ],
              
              // Reading Progress (only for Started or Standby books)
              if (_enabledCardFields.contains('progress') && 
                  book.readingProgress != null && 
                  book.readingProgress! > 0 &&
                  (book.statusValue?.toLowerCase() == 'started' ||
                   book.statusValue?.toLowerCase() == 'standby')) ...[
                Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      book.progressType == 'pages' 
                          ? '${book.readingProgress} pages'
                          : '${book.readingProgress}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
