import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:provider/provider.dart';

class RereadsDetailScreen extends StatelessWidget {
  const RereadsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Re-read Books')),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          final books = provider.allBooks;

          // Filter books that have been read more than once
          final rereadBooks =
              books.where((book) {
                return book.readCount != null && book.readCount! > 1;
              }).toList();

          // Sort by read count (most re-read first)
          rereadBooks.sort((a, b) {
            final countA = a.readCount ?? 0;
            final countB = b.readCount ?? 0;
            return countB.compareTo(countA);
          });

          if (rereadBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.replay, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No re-read books yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            itemCount: rereadBooks.length + 1,
            itemBuilder: (context, index) {
              // Add SizedBox at the end
              if (index == rereadBooks.length) {
                return const SizedBox(height: 50);
              }

              final book = rereadBooks[index];
              final readCount = book.readCount ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Text(
                      '${readCount}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    book.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (book.author != null && book.author!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          book.author!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Read $readCount times',
                        style: TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
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
            },
          );
        },
      ),
    );
  }
}
