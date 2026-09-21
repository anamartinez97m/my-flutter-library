import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/model/book_metadata.dart';
import 'package:myrandomlibrary/model/author_catalog_item.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
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
    return _MultiAuthorScreen(authors: widget.authors, provider: provider);
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.no_catalog_results,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.no_catalog_results,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
      backgroundColor = Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    } else if (item.isInLibrary) {
      // In library but not read: subtle tint
      backgroundColor = Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.15);
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
                    builder: (context) => NewBookDetailScreen(book: localBook),
                  ),
                );
              }
              : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
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
                    color: Theme.of(context).colorScheme.primary,
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
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : null,
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// V2 DESIGN
// ─────────────────────────────────────────────────────────────────────────────

const _kV2Bg = Color(0xFFFDF8F6);
const _kV2AppBar = Color(0xFF43102B);
const _kV2Text = Color(0xFF5F5E5C);
const _kV2Sub = Color(0xFF5F5E5C);
const _kV2Border = Color(0xFFCEC5BE);
const _kV2Divider = Color(0xFFE6E2DF);

class _SingleAuthorScreen extends StatelessWidget {
  final String author;
  final BookProvider provider;

  const _SingleAuthorScreen({required this.author, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kV2Bg,
      body: _AuthorContentView(author: author, provider: provider),
    );
  }
}

class _MultiAuthorScreen extends StatefulWidget {
  final List<String> authors;
  final BookProvider provider;

  const _MultiAuthorScreen({required this.authors, required this.provider});

  @override
  State<_MultiAuthorScreen> createState() => _MultiAuthorScreenState();
}

class _MultiAuthorScreenState extends State<_MultiAuthorScreen> {
  int _selectedIndex = 0;
  bool _showFullCatalog = false;
  GlobalKey<_AuthorContentViewState> _contentKey =
      GlobalKey<_AuthorContentViewState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kV2Bg,
      body: Column(
        children: [
          AppBar(
            backgroundColor: _kV2Bg,
            foregroundColor: _kV2AppBar,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _kV2AppBar),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.authors,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _kV2AppBar,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  _showFullCatalog ? Icons.library_books : Icons.travel_explore,
                  color: _kV2AppBar,
                ),
                tooltip:
                    _showFullCatalog
                        ? AppLocalizations.of(context)!.my_library_view
                        : AppLocalizations.of(context)!.full_catalog,
                onPressed: () => _contentKey.currentState?.toggleCatalogView(),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFD5C2C7)),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: widget.authors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final sel = i == _selectedIndex;
                return GestureDetector(
                  onTap: () {
                    if (i == _selectedIndex) return;
                    setState(() {
                      _selectedIndex = i;
                      _showFullCatalog = false;
                      _contentKey = GlobalKey<_AuthorContentViewState>();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? _kV2AppBar : Colors.white,
                      border: Border.all(color: sel ? _kV2AppBar : _kV2Border),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      widget.authors[i],
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : _kV2Sub,
                        letterSpacing: 0.26,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _AuthorContentView(
              key: _contentKey,
              author: widget.authors[_selectedIndex],
              provider: widget.provider,
              showHeader: false,
              onCatalogViewChanged: (showFullCatalog) {
                if (mounted) {
                  setState(() => _showFullCatalog = showFullCatalog);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorContentView extends StatefulWidget {
  final String author;
  final BookProvider provider;
  final bool showHeader;
  final ValueChanged<bool>? onCatalogViewChanged;

  const _AuthorContentView({
    super.key,
    required this.author,
    required this.provider,
    this.showHeader = true,
    this.onCatalogViewChanged,
  });

  @override
  State<_AuthorContentView> createState() => _AuthorContentViewState();
}

class _AuthorContentViewState extends State<_AuthorContentView> {
  bool _showFullCatalog = false;

  String get author => widget.author;
  BookProvider get provider => widget.provider;

  void toggleCatalogView() {
    setState(() => _showFullCatalog = !_showFullCatalog);
    widget.onCatalogViewChanged?.call(_showFullCatalog);
  }

  @override
  Widget build(BuildContext context) {
    if (_showFullCatalog) {
      return CustomScrollView(
        slivers: [
          if (widget.showHeader) _buildV2AppBar(context),
          SliverFillRemaining(
            child: _CatalogView(author: author, provider: provider),
          ),
        ],
      );
    }

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

    filteredBooks.sort((a, b) {
      final aYear = a.originalPublicationYear;
      final bYear = b.originalPublicationYear;
      if (aYear != null && bYear != null) return aYear.compareTo(bYear);
      if (aYear != null) return -1;
      if (bYear != null) return 1;
      return (a.name ?? '').compareTo(b.name ?? '');
    });

    if (filteredBooks.isEmpty) {
      return CustomScrollView(
        slivers: [
          if (widget.showHeader) _buildV2AppBar(context),
          SliverFillRemaining(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_books_for_author,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  color: _kV2Sub,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final l10n = AppLocalizations.of(context)!;
    return CustomScrollView(
      slivers: [
        if (widget.showHeader) _buildV2AppBar(context),
        // Stats row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                _v2StatChip(
                  icon: Icons.menu_book_outlined,
                  value: '${filteredBooks.length}',
                  label: l10n.total_books,
                ),
                if (averageRating != null) ...[
                  const SizedBox(width: 10),
                  _v2StatChip(
                    icon: Icons.star_outline,
                    value: averageRating.toStringAsFixed(1),
                    label: l10n.average_rating,
                  ),
                ],
              ],
            ),
          ),
        ),
        // Book list
        SliverPadding(
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final book = filteredBooks[index];
              final isRead =
                  book.statusValue?.toLowerCase() == 'yes' ||
                  book.statusValue?.toLowerCase() == 'repeated';
              final sagaText =
                  (book.saga != null && book.saga!.isNotEmpty)
                      ? (book.nSaga != null && book.nSaga!.isNotEmpty
                          ? '${book.saga} #${book.nSaga}'
                          : book.saga!)
                      : null;

              return _v2BookCard(
                context: context,
                book: book,
                isRead: isRead,
                subtitle: sagaText,
                year: book.originalPublicationYear,
              );
            }, childCount: filteredBooks.length),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildV2AppBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar(
      backgroundColor: _kV2Bg,
      foregroundColor: _kV2AppBar,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _kV2AppBar),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        author,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _kV2AppBar,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            _showFullCatalog ? Icons.library_books : Icons.travel_explore,
            color: _kV2AppBar,
          ),
          tooltip: _showFullCatalog ? l10n.my_library_view : l10n.full_catalog,
          onPressed: toggleCatalogView,
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFD5C2C7)),
      ),
    );
  }
}

// ── V2 shared helpers ────────────────────────────────────────────────────────

Widget _v2StatChip({
  required IconData icon,
  required String value,
  required String label,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _kV2Border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _kV2Text),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kV2AppBar,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _kV2Text,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );
}

Widget _v2BookCard({
  required BuildContext context,
  required dynamic book,
  required bool isRead,
  String? subtitle,
  int? year,
}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewBookDetailScreen(book: book),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFF5F3F2) : Colors.white,
        border: Border.all(color: _kV2Border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.name ?? AppLocalizations.of(context)!.unknown,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: _kV2AppBar,
                height: 1.25,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: _kV2Text,
                  height: 1.43,
                ),
              ),
            ],
            if (year != null || isRead) ...[
              if (subtitle != null)
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Divider(height: 1, thickness: 1, color: _kV2Divider),
                )
              else
                const SizedBox(height: 10),
              Row(
                children: [
                  if (year != null) ...[
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: _kV2Text,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$year',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kV2Text,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                  if (isRead) ...[
                    if (year != null) const SizedBox(width: 16),
                    Icon(Icons.check_circle_outline, size: 12, color: _kV2Text),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.read_label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kV2Text,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
