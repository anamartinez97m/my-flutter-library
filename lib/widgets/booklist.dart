import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/theme_provider.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';

class BookListView extends StatelessWidget {
  final List<Book> books;

  const BookListView({super.key, required this.books});

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
      itemCount: books.length,
      itemBuilder: (BuildContext context, int index) {
        final Book book = books[index];
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
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      book.name ?? AppLocalizations.of(context)!.unknown_title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  if (book.isTandem == true) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.swap_horizontal_circle_outlined,
                      size: 20,
                      color: Colors.deepPurple,
                    ),
                    Icon(
                      Icons.alt_route_outlined,
                      size: 20,
                      color: Colors.deepPurple,
                    ),
                  ],
                  if (book.tbr == true) ...[
                    Icon(
                      Icons.bookmark_add,
                      size: 20,
                      color: Colors.deepPurple,
                    ),
                  ],
                  if (book.isBundle == true) ...[
                    Icon(
                      Icons.library_books,
                      size: 20,
                      color: Colors.deepPurple,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (book.author != null && book.author!.isNotEmpty)
                Text(
                  AppLocalizations.of(
                    context,
                  )!.author_with_colon(book.author ?? ''),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (book.author != null && book.author!.isNotEmpty)
                const SizedBox(height: 4),
              if (book.genre != null && book.genre!.isNotEmpty)
                Text(
                  AppLocalizations.of(
                    context,
                  )!.genre_with_colon(book.genre ?? ''),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (book.genre != null && book.genre!.isNotEmpty)
                const SizedBox(height: 4),
              if (book.saga != null && book.saga!.isNotEmpty)
                Text(
                  AppLocalizations.of(
                        context,
                      )!.saga_with_colon(book.saga ?? '') +
                      (book.nSaga != null && book.nSaga!.isNotEmpty
                          ? ' #${book.nSaga}'
                          : ''),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (book.saga != null && book.saga!.isNotEmpty)
                const SizedBox(height: 4),
              Text(
                'ISBN/ASIN: ${book.isbn?.isNotEmpty == true ? book.isbn : (book.asin?.isNotEmpty == true ? book.asin : 'N/A')}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(
                      context,
                    )!.format_with_colon(book.formatValue ?? 'N/A') +
                    ' • ' +
                    AppLocalizations.of(
                      context,
                    )!.language_with_colon(book.languageValue ?? 'N/A'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
