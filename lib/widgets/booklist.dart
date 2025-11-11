import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/theme_provider.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';

class BookListView extends StatelessWidget {
  final List<Book> books;

  const BookListView({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (BuildContext context, int index) {
        final Book book = books[index];
        // Check if book is read (status is 'yes' case-insensitive)
        final isRead = book.statusValue?.toLowerCase() == 'yes';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          color: isRead ? Colors.grey.shade200 : null,
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
                          book.name ??
                              AppLocalizations.of(context)!.unknown_title,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (book.saga != null && book.saga!.isNotEmpty)
                    const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.isbn_with_colon(book.isbn ?? 'N/A'),
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
      },
    );
  }
}
