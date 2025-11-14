import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

/// Dialog for quickly searching and adding books to a saga or universe
class QuickAddBookDialog extends StatefulWidget {
  final String? sagaName;
  final String? sagaUniverse;

  const QuickAddBookDialog({
    super.key,
    this.sagaName,
    this.sagaUniverse,
  });

  @override
  State<QuickAddBookDialog> createState() => _QuickAddBookDialogState();
}

class _QuickAddBookDialogState extends State<QuickAddBookDialog> {
  final _searchController = TextEditingController();
  List<Book> _searchResults = [];
  List<Book> _selectedBooks = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchBooks(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      
      // Search by title
      final results = await repository.searchBooks(query, 0);
      
      // Filter out books already in this saga/universe
      final filtered = results.where((book) {
        if (widget.sagaName != null) {
          return book.saga != widget.sagaName;
        } else if (widget.sagaUniverse != null) {
          return book.sagaUniverse != widget.sagaUniverse;
        }
        return true;
      }).toList();

      setState(() {
        _searchResults = filtered;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching books: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _addSelectedBooks() async {
    if (_selectedBooks.isEmpty) return;

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      for (final book in _selectedBooks) {
        // Update the book with the saga/universe
        final updatedBook = Book(
          bookId: book.bookId,
          name: book.name,
          isbn: book.isbn,
          asin: book.asin,
          author: book.author,
          saga: widget.sagaName ?? book.saga,
          nSaga: book.nSaga,
          sagaUniverse: widget.sagaUniverse ?? book.sagaUniverse,
          formatSagaValue: book.formatSagaValue,
          pages: book.pages,
          originalPublicationYear: book.originalPublicationYear,
          loaned: book.loaned,
          statusValue: book.statusValue,
          editorialValue: book.editorialValue,
          languageValue: book.languageValue,
          placeValue: book.placeValue,
          formatValue: book.formatValue,
          createdAt: book.createdAt,
          genre: book.genre,
          dateReadInitial: book.dateReadInitial,
          dateReadFinal: book.dateReadFinal,
          readCount: book.readCount,
          myRating: book.myRating,
          myReview: book.myReview,
          isBundle: book.isBundle,
          bundleCount: book.bundleCount,
          bundleNumbers: book.bundleNumbers,
          bundleStartDates: book.bundleStartDates,
          bundleEndDates: book.bundleEndDates,
          bundlePages: book.bundlePages,
          bundlePublicationYears: book.bundlePublicationYears,
          bundleTitles: book.bundleTitles,
          tbr: book.tbr,
          isTandem: book.isTandem,
        );

        await repository.deleteBook(book.bookId!);
        await repository.addBook(updatedBook);
      }

      if (mounted) {
        Navigator.pop(context, _selectedBooks.length);
      }
    } catch (e) {
      debugPrint('Error adding books: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding books: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Add Books to ${widget.sagaName ?? widget.sagaUniverse}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search books by title',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchBooks('');
                        },
                      )
                    : null,
              ),
              onChanged: _searchBooks,
            ),
            const SizedBox(height: 16),

            // Selected books count
            if (_selectedBooks.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedBooks.length} book(s) selected',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),

            // Search results
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Search for books to add'
                                : 'No books found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final book = _searchResults[index];
                            final isSelected = _selectedBooks.contains(book);

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true) {
                                    _selectedBooks.add(book);
                                  } else {
                                    _selectedBooks.remove(book);
                                  }
                                });
                              },
                              title: Text(
                                book.name ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (book.author != null)
                                    Text('by ${book.author}'),
                                  if (book.saga != null)
                                    Text(
                                      'Current saga: ${book.saga}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Action buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _selectedBooks.isEmpty ? null : _addSelectedBooks,
                  icon: const Icon(Icons.add),
                  label: Text('Add ${_selectedBooks.length} Book(s)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
