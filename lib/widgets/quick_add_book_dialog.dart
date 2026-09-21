import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF5D2641);
const _kText = Color(0xFF1C1B1A);
const _kSub = Color(0xFF514348);
const _kBorder = Color(0xFFDDD9D7);
const _kWarning = Color(0xFF7A4D00);
const _kWarningBg = Color(0xFFFFF4D9);
const _kWarningBorder = Color(0xFFE5C46B);

/// Dialog for quickly searching and adding books to a saga or universe
class QuickAddBookDialog extends StatefulWidget {
  final String? sagaName;
  final String? sagaUniverse;

  const QuickAddBookDialog({super.key, this.sagaName, this.sagaUniverse});

  @override
  State<QuickAddBookDialog> createState() => _QuickAddBookDialogState();
}

class _QuickAddBookDialogState extends State<QuickAddBookDialog> {
  final _searchController = TextEditingController();
  List<Book> _searchResults = [];
  final List<Book> _selectedBooks = [];
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
      final filtered =
          results.where((book) {
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
          orderWithinUniverse: book.orderWithinUniverse,
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
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _kBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 25,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.playlist_add, color: _kPrimary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${AppLocalizations.of(context)!.add_books_to} ${widget.sagaName ?? widget.sagaUniverse}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: _kSub),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontFamily: 'Manrope', color: _kText),
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.search_books_by_title,
                    labelStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      color: _kPrimary,
                    ),
                    prefixIcon: const Icon(Icons.search, color: _kPrimary),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kSub),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _kPrimary, width: 2),
                    ),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, color: _kSub),
                              onPressed: () {
                                _searchController.clear();
                                _searchBooks('');
                              },
                            )
                            : null,
                  ),
                  onChanged: _searchBooks,
                ),
              ),
              const SizedBox(height: 16),

              // Selected books count
              if (_selectedBooks.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _kPrimary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: _kPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.books_selected(_selectedBooks.length),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: _kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // Search results
              Expanded(
                child:
                    _isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : _searchResults.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _searchController.text.isEmpty
                                    ? Icons.search
                                    : Icons.search_off,
                                color: _kPrimary.withValues(alpha: 0.45),
                                size: 36,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.isEmpty
                                    ? AppLocalizations.of(
                                      context,
                                    )!.search_for_books_to_add
                                    : AppLocalizations.of(
                                      context,
                                    )!.no_books_found,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  color: _kSub,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final book = _searchResults[index];
                            final isSelected = _selectedBooks.contains(book);
                            final currentAssignment =
                                widget.sagaName != null
                                    ? book.saga
                                    : book.sagaUniverse;
                            final assignmentLabel =
                                widget.sagaName != null
                                    ? AppLocalizations.of(context)!.saga
                                    : AppLocalizations.of(
                                      context,
                                    )!.saga_universe;

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: _kPrimary,
                              checkColor: Colors.white,
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              selectedTileColor: _kPrimary.withValues(
                                alpha: 0.05,
                              ),
                              selected: isSelected,
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
                                book.name ??
                                    AppLocalizations.of(context)!.unknown,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w600,
                                  color: _kText,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (book.author != null)
                                    Text(
                                      'by ${book.author}',
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 13,
                                        color: _kSub,
                                      ),
                                    ),
                                  if (currentAssignment != null &&
                                      currentAssignment.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _kWarningBg,
                                        borderRadius: BorderRadius.circular(7),
                                        border: Border.all(
                                          color: _kWarningBorder,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            color: _kWarning,
                                            size: 15,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              '$assignmentLabel: $currentAssignment',
                                              style: const TextStyle(
                                                fontFamily: 'Manrope',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _kWarning,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
              ),

              // Action buttons
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: _kBg,
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: _kSub,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed:
                          _selectedBooks.isEmpty ? null : _addSelectedBooks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kBorder,
                        disabledForegroundColor: _kSub,
                        elevation: _selectedBooks.isEmpty ? 0 : 4,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        AppLocalizations.of(
                          context,
                        )!.add_n_books(_selectedBooks.length),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
