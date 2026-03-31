import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/model/book_metadata.dart';
import 'package:myrandomlibrary/model/author_catalog_item.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:myrandomlibrary/services/open_library_service.dart';
import 'package:provider/provider.dart';

class BooksByAuthorScreen extends StatefulWidget {
  final List<String> authors;

  const BooksByAuthorScreen({super.key, required this.authors});

  @override
  State<BooksByAuthorScreen> createState() => _BooksByAuthorScreenState();
}

class _BooksByAuthorScreenState extends State<BooksByAuthorScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.author)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If single author, show simple screen
    if (widget.authors.length == 1) {
      return _SingleAuthorScreen(
        author: widget.authors.first,
        provider: provider,
      );
    }

    // If multiple authors, show tabs
    return DefaultTabController(
      length: widget.authors.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.authors),
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: widget.authors.map((author) => Tab(text: author)).toList(),
          ),
        ),
        body: TabBarView(
          children:
              widget.authors.map((author) {
                return _AuthorContentView(author: author, provider: provider);
              }).toList(),
        ),
      ),
    );
  }
}

/// Single author screen wrapper with AppBar toggle button
class _SingleAuthorScreen extends StatefulWidget {
  final String author;
  final BookProvider provider;

  const _SingleAuthorScreen({required this.author, required this.provider});

  @override
  State<_SingleAuthorScreen> createState() => _SingleAuthorScreenState();
}

class _SingleAuthorScreenState extends State<_SingleAuthorScreen> {
  bool _showFullCatalog = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.author),
        actions: [
          IconButton(
            icon: Icon(
              _showFullCatalog ? Icons.library_books : Icons.travel_explore,
            ),
            tooltip:
                _showFullCatalog ? l10n.my_library_view : l10n.full_catalog,
            onPressed: () {
              setState(() {
                _showFullCatalog = !_showFullCatalog;
              });
            },
          ),
        ],
      ),
      body:
          _showFullCatalog
              ? _CatalogView(author: widget.author, provider: widget.provider)
              : _LocalAuthorContent(
                author: widget.author,
                provider: widget.provider,
              ),
    );
  }
}

/// Wraps the content view with its own toggle state (for tabs)
class _AuthorContentView extends StatefulWidget {
  final String author;
  final BookProvider provider;

  const _AuthorContentView({required this.author, required this.provider});

  @override
  State<_AuthorContentView> createState() => _AuthorContentViewState();
}

class _AuthorContentViewState extends State<_AuthorContentView> {
  bool _showFullCatalog = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // Toggle bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(
                  _showFullCatalog ? Icons.library_books : Icons.travel_explore,
                  size: 18,
                ),
                label: Text(
                  _showFullCatalog ? l10n.my_library_view : l10n.full_catalog,
                ),
                onPressed: () {
                  setState(() {
                    _showFullCatalog = !_showFullCatalog;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _showFullCatalog
                  ? _CatalogView(
                    author: widget.author,
                    provider: widget.provider,
                  )
                  : _LocalAuthorContent(
                    author: widget.author,
                    provider: widget.provider,
                  ),
        ),
      ],
    );
  }
}

/// Original local-only author content (unchanged logic)
class _LocalAuthorContent extends StatelessWidget {
  final String author;
  final BookProvider provider;

  const _LocalAuthorContent({required this.author, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Filter books by author (case-insensitive, handles comma-separated authors)
    final filteredBooks =
        provider.allBooks.where((book) {
          if (book.author == null) return false;
          final bookAuthors =
              book.author!
                  .split(',')
                  .map((a) => a.trim().toLowerCase())
                  .toList();
          return bookAuthors.contains(author.toLowerCase());
        }).toList();

    // Calculate average rating for read books with ratings
    final readBooksWithRating =
        filteredBooks.where((book) {
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
              Icon(Icons.person_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.no_books_for_author,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
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
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.total_books,
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
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
                              AppLocalizations.of(context)!.average_rating,
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
                        color:
                            isRead
                                ? Colors.grey[300]?.withValues(alpha: 0.3)
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
                                    book.name ??
                                        AppLocalizations.of(context)!.unknown,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      fontWeight:
                                          isRead
                                              ? FontWeight.normal
                                              : FontWeight.w500,
                                      color: isRead ? Colors.grey[700] : null,
                                    ),
                                  ),
                                  if (book.saga != null &&
                                      book.saga!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        book.nSaga != null &&
                                                book.nSaga!.isNotEmpty
                                            ? '${book.saga} #${book.nSaga}'
                                            : book.saga!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Show release date for TBReleased books, publication year for others
                            Builder(
                              builder: (context) {
                                // Priority: TBReleased notification date > publication year
                                if (book.statusValue?.toLowerCase() ==
                                        'tbreleased' &&
                                    book.notificationDatetime != null &&
                                    book.notificationDatetime!.isNotEmpty) {
                                  try {
                                    final dateStr = book.notificationDatetime!;
                                    DateTime releaseDate;

                                    // Parse YYYYMMDD format (e.g., "20260210")
                                    if (dateStr.length == 8 &&
                                        int.tryParse(dateStr) != null) {
                                      final year = int.parse(
                                        dateStr.substring(0, 4),
                                      );
                                      final month = int.parse(
                                        dateStr.substring(4, 6),
                                      );
                                      final day = int.parse(
                                        dateStr.substring(6, 8),
                                      );
                                      releaseDate = DateTime(year, month, day);
                                    } else {
                                      // Try ISO format as fallback
                                      releaseDate = DateTime.parse(dateStr);
                                    }

                                    final now = DateTime.now();
                                    final today = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                    );
                                    final releaseDateOnly = DateTime(
                                      releaseDate.year,
                                      releaseDate.month,
                                      releaseDate.day,
                                    );

                                    String displayText;
                                    if (releaseDateOnly.isBefore(today)) {
                                      // Past date: show DD/MM/YYYY
                                      displayText =
                                          '${releaseDate.day.toString().padLeft(2, '0')}/${releaseDate.month.toString().padLeft(2, '0')}/${releaseDate.year}';
                                    } else {
                                      // Future date: show only year
                                      displayText = '${releaseDate.year}';
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        displayText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.grey[600]),
                                      ),
                                    );
                                  } catch (e) {
                                    // If parsing fails, fall through to publication year
                                  }
                                }

                                // Show publication year for non-TBReleased or if date parsing failed
                                if (book.originalPublicationYear != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      '${book.originalPublicationYear}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  );
                                }

                                return const SizedBox.shrink();
                              },
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

/// Catalog view: fetches all books by the author from Open Library API
/// and merges with local library data (unique works, no duplicate editions)
class _CatalogView extends StatefulWidget {
  final String author;
  final BookProvider provider;

  const _CatalogView({required this.author, required this.provider});

  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  final OpenLibraryService _openLibraryService = OpenLibraryService();
  final ScrollController _scrollController = ScrollController();

  List<AuthorCatalogItem> _catalogItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  int _totalItems = 0;
  String? _error;
  String? _detectedLanguage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _detectLanguageFromLocalBooks();
    _fetchCatalog();
  }

  void _detectLanguageFromLocalBooks() {
    final localBooks =
        widget.provider.allBooks.where((book) {
          if (book.author == null) return false;
          final bookAuthors =
              book.author!
                  .split(',')
                  .map((a) => a.trim().toLowerCase())
                  .toList();
          return bookAuthors.contains(widget.author.toLowerCase());
        }).toList();

    if (localBooks.isEmpty) {
      debugPrint('[CatalogView] No local books found for language detection');
      return;
    }

    // Count languages
    final langCounts = <String, int>{};
    for (final book in localBooks) {
      final lang = book.languageValue;
      if (lang != null && lang.isNotEmpty) {
        langCounts[lang] = (langCounts[lang] ?? 0) + 1;
      }
    }

    if (langCounts.isNotEmpty) {
      // Pick the most common language
      final sorted =
          langCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      _detectedLanguage = sorted.first.key;
      debugPrint(
        '[CatalogView] Detected language from local books: "$_detectedLanguage" (counts: $langCounts)',
      );
    } else {
      debugPrint('[CatalogView] No language info found in local books');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMoreCatalog();
    }
  }

  Future<void> _fetchCatalog() async {
    debugPrint(
      '[CatalogView] === Starting catalog fetch for author: "${widget.author}" ===',
    );
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _openLibraryService.fetchByAuthor(
        widget.author,
        offset: 0,
        language: _detectedLanguage,
      );

      _totalItems = result.totalItems;
      _currentOffset = result.books.length;
      _hasMore = _currentOffset < _totalItems;

      debugPrint(
        '[CatalogView] API returned ${result.books.length} works, totalItems: $_totalItems, hasMore: $_hasMore',
      );

      final items = _mergeWithLocalBooks(result.books);
      items.sort((a, b) {
        final yearA = a.displayYear ?? 9999;
        final yearB = b.displayYear ?? 9999;
        return yearA.compareTo(yearB);
      });

      debugPrint(
        '[CatalogView] After merge & sort: ${items.length} catalog items',
      );
      final inLibrary = items.where((i) => i.isInLibrary).length;
      final notInLibrary = items.where((i) => !i.isInLibrary).length;
      debugPrint(
        '[CatalogView] In library: $inLibrary, Not in library: $notInLibrary',
      );

      if (mounted) {
        setState(() {
          _catalogItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[CatalogView] Error fetching catalog: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _fetchMoreCatalog() async {
    if (_isLoadingMore || !_hasMore) return;

    debugPrint(
      '[CatalogView] === Fetching more catalog, offset: $_currentOffset, totalItems: $_totalItems ===',
    );
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _openLibraryService.fetchByAuthor(
        widget.author,
        offset: _currentOffset,
        language: _detectedLanguage,
      );

      debugPrint(
        '[CatalogView] More fetch returned ${result.books.length} works',
      );
      _currentOffset += result.books.length;
      _hasMore = _currentOffset < _totalItems && result.books.isNotEmpty;
      debugPrint(
        '[CatalogView] Updated offset: $_currentOffset, hasMore: $_hasMore',
      );

      final newItems = _mergeWithLocalBooks(result.books);
      debugPrint(
        '[CatalogView] After merge: ${newItems.length} new items, total will be: ${_catalogItems.length + newItems.length}',
      );

      if (mounted) {
        setState(() {
          _catalogItems.addAll(newItems);
          _catalogItems.sort((a, b) {
            final yearA = a.displayYear ?? 9999;
            final yearB = b.displayYear ?? 9999;
            return yearA.compareTo(yearB);
          });
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('[CatalogView] Error fetching more: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  List<AuthorCatalogItem> _mergeWithLocalBooks(List<BookMetadata> apiBooks) {
    // Compare against local books by the same author
    final localBooks =
        widget.provider.allBooks.where((book) {
          if (book.author == null) return false;
          final bookAuthors =
              book.author!
                  .split(',')
                  .map((a) => a.trim().toLowerCase())
                  .toList();
          return bookAuthors.contains(widget.author.toLowerCase());
        }).toList();

    debugPrint(
      '[CatalogView] === Merging ${apiBooks.length} API works against ${localBooks.length} local books by "${widget.author}" ===',
    );

    for (int i = 0; i < localBooks.length; i++) {
      debugPrint(
        '[CatalogView] Local[$i]: "${localBooks[i].name}" | ISBN: ${localBooks[i].isbn} | Status: ${localBooks[i].statusValue}',
      );
    }

    final List<AuthorCatalogItem> result = [];
    int matchedCount = 0;

    for (final metadata in apiBooks) {
      final isbn = metadata.isbn13 ?? metadata.isbn10;
      final apiTitle = metadata.title;

      // Try to find a matching local book
      dynamic matchedBook;
      String matchReason = '';

      // 1. ISBN match
      if (isbn != null && isbn.isNotEmpty) {
        final normalizedApiIsbn = _normalizeIsbn(isbn);
        for (final b in localBooks) {
          if (b.isbn != null &&
              b.isbn!.isNotEmpty &&
              _normalizeIsbn(b.isbn!) == normalizedApiIsbn) {
            matchedBook = b;
            matchReason = 'ISBN';
            break;
          }
        }
      }

      // 2. Exact normalized title match
      if (matchedBook == null && apiTitle != null && apiTitle.isNotEmpty) {
        final normalizedApiTitle = _normalizeTitle(apiTitle);
        for (final b in localBooks) {
          if (b.name != null &&
              _normalizeTitle(b.name!) == normalizedApiTitle) {
            matchedBook = b;
            matchReason = 'exact title';
            break;
          }
        }

        // 3. Fuzzy title match
        if (matchedBook == null) {
          for (final book in localBooks) {
            if (book.name == null || book.name!.isEmpty) continue;
            final normalizedLocalTitle = _normalizeTitle(book.name!);
            if (normalizedLocalTitle.isEmpty || normalizedApiTitle.isEmpty) {
              continue;
            }

            // Contains check: e.g. "Artemis" ⊂ "Artemisa", or
            // "El nombre del viento" ⊂ "El nombre del viento (Edicion especial)"
            if (normalizedApiTitle.contains(normalizedLocalTitle) ||
                normalizedLocalTitle.contains(normalizedApiTitle)) {
              matchedBook = book;
              matchReason = 'fuzzy (contains)';
              break;
            }

            // Word overlap: if 50%+ of significant words match, consider it the same book
            // This catches cross-language titles like "Project Hail Mary" / "Proyecto Hail Mary"
            final apiWords =
                normalizedApiTitle
                    .split(' ')
                    .where((w) => w.length > 2)
                    .toSet();
            final localWords =
                normalizedLocalTitle
                    .split(' ')
                    .where((w) => w.length > 2)
                    .toSet();
            if (apiWords.length >= 2 && localWords.length >= 2) {
              final commonWords = apiWords.intersection(localWords).length;
              final maxWords =
                  apiWords.length > localWords.length
                      ? apiWords.length
                      : localWords.length;
              // At least 50% of the larger set must match, AND at least 2 words in common
              if (commonWords >= 2 && commonWords / maxWords >= 0.5) {
                matchedBook = book;
                matchReason = 'fuzzy (word overlap: $commonWords/$maxWords)';
                break;
              }
            }
          }
        }
      }

      if (matchedBook != null) {
        matchedCount++;
        debugPrint(
          '[CatalogView] MATCHED ($matchReason): API "$apiTitle" ~ Local "${matchedBook.name}"',
        );
        result.add(
          AuthorCatalogItem(
            title: metadata.title,
            authors: metadata.authors,
            publishedYear: metadata.publishedYear,
            isbn: isbn,
            metadata: metadata,
            isInLibrary: true,
            localBookId: matchedBook.bookId,
            localBookStatus: matchedBook.statusValue,
            localSaga: matchedBook.saga,
            localNSaga: matchedBook.nSaga,
            localPublicationYear: matchedBook.originalPublicationYear,
          ),
        );
      } else {
        debugPrint('[CatalogView] NEW: "$apiTitle" | ISBN: $isbn');
        result.add(
          AuthorCatalogItem(
            title: metadata.title,
            authors: metadata.authors,
            publishedYear: metadata.publishedYear,
            isbn: isbn,
            metadata: metadata,
            isInLibrary: false,
          ),
        );
      }
    }

    debugPrint(
      '[CatalogView] Result: ${result.length} total, $matchedCount matched as owned, ${result.length - matchedCount} new',
    );
    return result;
  }

  String _normalizeIsbn(String isbn) {
    return isbn.replaceAll(RegExp(r'[^0-9X]'), '').toUpperCase();
  }

  String _normalizeTitle(String title) {
    return _removeAccents(
      title.toLowerCase().trim(),
    ).replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');
  }

  String _removeAccents(String str) {
    const withAccents = 'àáâãäåèéêëìíîïòóôõöùúûüýñç';
    const withoutAccents = 'aaaaaaeeeeiiiioooooouuuuync';
    String result = str;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.fetching_author_books,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              l10n.no_catalog_results,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchCatalog,
              child: Text(l10n.fetching_author_books),
            ),
          ],
        ),
      );
    }

    if (_catalogItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              l10n.no_catalog_results,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _catalogItems.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _catalogItems.length) {
          // Loading more indicator
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loading_more,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        final item = _catalogItems[index];
        return _buildCatalogItemTile(context, item);
      },
    );
  }

  Widget _buildCatalogItemTile(BuildContext context, AuthorCatalogItem item) {
    Color? backgroundColor;
    if (item.isInLibrary && item.isRead) {
      // Read: grey background
      backgroundColor = Colors.grey[300]?.withValues(alpha: 0.3);
    } else if (item.isInLibrary) {
      // In library but not read: subtle tint
      backgroundColor = Colors.deepPurple.withValues(alpha: 0.05);
    }

    // Saga info (only available for local books)
    final String? sagaText;
    if (item.isInLibrary &&
        item.localSaga != null &&
        item.localSaga!.isNotEmpty) {
      sagaText =
          item.localNSaga != null && item.localNSaga!.isNotEmpty
              ? '${item.localSaga} #${item.localNSaga}'
              : item.localSaga;
    } else {
      sagaText = null;
    }

    return InkWell(
      onTap:
          item.isInLibrary && item.localBookId != null
              ? () {
                final localBook = widget.provider.allBooks.firstWhere(
                  (b) => b.bookId == item.localBookId,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookDetailScreen(book: localBook),
                  ),
                );
              }
              : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Checkmark for read books
              if (item.isInLibrary && item.isRead)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 20,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title ?? AppLocalizations.of(context)!.unknown,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            item.isRead ? FontWeight.normal : FontWeight.w500,
                        color:
                            item.isRead
                                ? Colors.grey[700]
                                : (item.isInLibrary ? null : Colors.grey[800]),
                      ),
                    ),
                    if (sagaText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          sagaText,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Publication year
              if (item.displayYear != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${item.displayYear}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
