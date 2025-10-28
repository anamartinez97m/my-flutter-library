import 'package:flutter/material.dart';
import 'package:mylibrary/db/database_helper.dart';
import 'package:mylibrary/model/book.dart';
import 'package:mylibrary/providers/book_provider.dart';
import 'package:mylibrary/repositories/book_repository.dart';
import 'package:mylibrary/screens/edit_book.dart';
import 'package:provider/provider.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  Future<void> _deleteBook(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${book.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && book.bookId != null) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookRepository(db);
        await repository.deleteBook(book.bookId!);

        if (context.mounted) {
          final provider = Provider.of<BookProvider?>(context, listen: false);
          await provider?.loadBooks();

          Navigator.pop(context); // Go back to list

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting book: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditBookScreen(book: book),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteBook(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image placeholder
            Container(
              height: 180,
              color: Colors.grey[300],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Image coming soon',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    book.name ?? 'Unknown Title',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description (from API - future implementation)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.description, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'API',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.deepPurple[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This is a placeholder for the book description that will be fetched from an external API in future development. The description will provide a summary of the book\'s content, themes, and other relevant information.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details in cards
                  if (book.author != null && book.author!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.person,
                      label: 'Author(s)',
                      value: book.author!,
                    ),
                  if (book.isbn != null && book.isbn!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.numbers,
                      label: 'ISBN',
                      value: book.isbn!,
                    ),
                  if (book.editorialValue != null &&
                      book.editorialValue!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.business,
                      label: 'Editorial',
                      value: book.editorialValue!,
                    ),
                  if (book.genre != null && book.genre!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.category,
                      label: 'Genre(s)',
                      value: book.genre!,
                    ),
                  if (book.saga != null && book.saga!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.collections_bookmark,
                      label: 'Saga',
                      value:
                          '${book.saga}${book.nSaga != null ? ' #${book.nSaga}' : ''}',
                    ),
                  if (book.pages != null)
                    _DetailCard(
                      icon: Icons.description,
                      label: 'Pages',
                      value: book.pages.toString(),
                    ),
                  if (book.originalPublicationYear != null)
                    _DetailCard(
                      icon: Icons.calendar_today,
                      label: 'Publication Year',
                      value: book.originalPublicationYear.toString(),
                    ),
                  if (book.statusValue != null && book.statusValue!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.check_circle,
                      label: 'Status',
                      value: book.statusValue!,
                    ),
                  if (book.formatSagaValue != null &&
                      book.formatSagaValue!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.format_shapes,
                      label: 'Format Saga',
                      value: book.formatSagaValue!,
                    ),
                  if (book.languageValue != null &&
                      book.languageValue!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.language,
                      label: 'Language',
                      value: book.languageValue!,
                    ),
                  if (book.placeValue != null && book.placeValue!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.place,
                      label: 'Place',
                      value: book.placeValue!,
                    ),
                  if (book.formatValue != null && book.formatValue!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.import_contacts,
                      label: 'Format',
                      value: book.formatValue!,
                    ),
                  if (book.loaned != null && book.loaned!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.swap_horiz,
                      label: 'Loaned',
                      value: book.loaned!,
                    ),
                  if (book.createdAt != null && book.createdAt!.isNotEmpty)
                    _DetailCard(
                      icon: Icons.access_time,
                      label: 'Created',
                      value: book.createdAt!.split('T')[0],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24), // Bottom margin
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.deepPurple, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
