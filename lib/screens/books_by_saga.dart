import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/widgets/booklist.dart';
import 'package:myrandomlibrary/widgets/quick_add_book_dialog.dart';
import 'package:provider/provider.dart';

class BooksBySagaScreen extends StatelessWidget {
  final String sagaName;
  final String? sagaUniverse;
  final bool isSagaUniverse;

  const BooksBySagaScreen({
    super.key,
    required this.sagaName,
    this.sagaUniverse,
    this.isSagaUniverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isSagaUniverse ? 'Saga Universe' : 'Saga'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Filter books by saga or saga universe
    final filteredBooks = provider.allBooks.where((book) {
      if (isSagaUniverse) {
        return book.sagaUniverse?.toLowerCase() == sagaName.toLowerCase();
      } else {
        return book.saga?.toLowerCase() == sagaName.toLowerCase();
      }
    }).toList();

    // Sort by saga number if available
    filteredBooks.sort((a, b) {
      final aSagaNum = int.tryParse(a.nSaga ?? '');
      final bSagaNum = int.tryParse(b.nSaga ?? '');
      
      if (aSagaNum != null && bSagaNum != null) {
        return aSagaNum.compareTo(bSagaNum);
      } else if (aSagaNum != null) {
        return -1;
      } else if (bSagaNum != null) {
        return 1;
      }
      
      // Fallback to name sorting
      return (a.name ?? '').compareTo(b.name ?? '');
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isSagaUniverse ? 'Universe: $sagaName' : 'Saga: $sagaName'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<int>(
            context: context,
            builder: (context) => QuickAddBookDialog(
              sagaName: isSagaUniverse ? null : sagaName,
              sagaUniverse: isSagaUniverse ? sagaName : sagaUniverse,
            ),
          );
          
          if (result != null && result > 0) {
            // Reload books
            provider.loadBooks();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added $result book(s) to ${isSagaUniverse ? 'universe' : 'saga'}'),
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
      ),
      body: filteredBooks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.collections_bookmark_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No books found in this ${isSagaUniverse ? 'universe' : 'saga'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
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
                          if (!isSagaUniverse && sagaUniverse != null)
                            Column(
                              children: [
                                Icon(
                                  Icons.public,
                                  color: Colors.deepPurple,
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sagaUniverse!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: BookListView(books: filteredBooks),
                ),
              ],
            ),
    );
  }
}
