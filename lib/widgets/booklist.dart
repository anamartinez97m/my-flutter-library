import 'package:flutter/material.dart';
import 'package:mylibrary/model/book.dart';

class BookListView extends StatelessWidget {
  final List<Book> books;

  const BookListView({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (BuildContext context, int index) {
        final Book book = books[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  book.name ?? 'Unknown Title',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                if (book.author != null && book.author!.isNotEmpty)
                  Text(
                    'Author: ${book.author}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (book.author != null && book.author!.isNotEmpty)
                  const SizedBox(height: 4),
                if (book.genre != null && book.genre!.isNotEmpty)
                  Text(
                    'Genre: ${book.genre}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (book.genre != null && book.genre!.isNotEmpty)
                  const SizedBox(height: 4),
                if (book.saga != null && book.saga!.isNotEmpty)
                  Text(
                    'Saga: ${book.saga}${book.nSaga != null ? ' #${book.nSaga}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (book.saga != null && book.saga!.isNotEmpty)
                  const SizedBox(height: 4),
                Text(
                  'ISBN: ${book.isbn ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Format: ${book.formatValue ?? 'N/A'} • Language: ${book.languageValue ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
