import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/providers/role_provider.dart';
import 'package:myrandomlibrary/screens/new_ui/author_catalog_view.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
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

// ─────────────────────────────────────────────────────────────────────────────
// V2 DESIGN
// ─────────────────────────────────────────────────────────────────────────────

Color get _kV2Bg => V2Colors.background;
Color get _kV2AppBar => V2Colors.primary;
Color get _kV2Text => V2Colors.textSubtle;
Color get _kV2Sub => V2Colors.textSubtle;
Color get _kV2Border => V2Colors.borderNeutral;
Color get _kV2Divider => V2Colors.divider;

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
              icon: Icon(Icons.arrow_back, color: _kV2AppBar),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context)!.authors,
              style: TextStyle(
                fontFamily: V2Typography.family,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _kV2AppBar,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
            actions: [
              if (context.watch<RoleProvider>().isAdmin)
                IconButton(
                  icon: Icon(
                    _showFullCatalog
                        ? Icons.library_books
                        : Icons.travel_explore,
                    color: _kV2AppBar,
                  ),
                  tooltip:
                      _showFullCatalog
                          ? AppLocalizations.of(context)!.my_library_view
                          : AppLocalizations.of(context)!.full_catalog,
                  onPressed:
                      () => _contentKey.currentState?.toggleCatalogView(),
                ),
            ],
          ),
          Divider(height: 1, color: V2Colors.border),
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
                      color: sel ? _kV2AppBar : V2Colors.surface,
                      border: Border.all(color: sel ? _kV2AppBar : _kV2Border),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      widget.authors[i],
                      style: TextStyle(
                        fontFamily: V2Typography.family,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel ? V2Colors.onPrimary : _kV2Sub,
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

  @override
  void initState() {
    super.initState();
    // Refresh the book list so the author screen reflects the latest data,
    // especially bundle child authors that may have been edited from the
    // book detail screen while the provider cache was stale.
    provider.loadBooks();
  }

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
            child: AuthorCatalogView(author: author, provider: provider),
          ),
        ],
      );
    }

    final selectedAuthor = _normalizeAuthorName(author);

    final filteredBooks =
        provider.allBooks.where((book) {
          if (book.author == null || book.author!.isEmpty) return false;
          final bookAuthors =
              book.author!
                  .split(',')
                  .map((a) => _normalizeAuthorName(a))
                  .where((a) => a.isNotEmpty)
                  .toList();
          return bookAuthors.contains(selectedAuthor);
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

    final l10n = AppLocalizations.of(context)!;

    // Map bundle parent IDs to their titles so individual child books can
    // surface which bundle they belong to, even if the bundle itself is not
    // shown for this author.
    final bundleNamesById = <int, String>{
      for (final b in provider.allBooks)
        if (b.isBundle == true && b.bookId != null)
          b.bookId!: b.name ?? l10n.unknown,
    };

    if (filteredBooks.isEmpty) {
      return CustomScrollView(
        slivers: [
          if (widget.showHeader) _buildV2AppBar(context),
          SliverFillRemaining(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_books_for_author,
                style: TextStyle(
                  fontFamily: V2Typography.family,
                  fontSize: 16,
                  color: _kV2Sub,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
                bundleCount: book.isBundle == true ? book.bundleCount : null,
                bundleName:
                    book.bundleParentId != null
                        ? bundleNamesById[book.bundleParentId]
                        : null,
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
        icon: Icon(Icons.arrow_back, color: _kV2AppBar),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        author,
        style: TextStyle(
          fontFamily: V2Typography.family,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _kV2AppBar,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        if (context.watch<RoleProvider>().isAdmin)
          IconButton(
            icon: Icon(
              _showFullCatalog ? Icons.library_books : Icons.travel_explore,
              color: _kV2AppBar,
            ),
            tooltip:
                _showFullCatalog ? l10n.my_library_view : l10n.full_catalog,
            onPressed: toggleCatalogView,
          ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: V2Colors.border),
      ),
    );
  }
}

// ── V2 shared helpers ────────────────────────────────────────────────────────

String _normalizeAuthorName(String name) {
  return _removeAuthorAccents(
    name.toLowerCase().trim(),
  ).replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ');
}

String _removeAuthorAccents(String str) {
  const withAccents = 'àáâãäåèéêëìíîïòóôõöùúûüýñç';
  const withoutAccents = 'aaaaaaeeeeiiiioooooouuuuync';
  String result = str;
  for (int i = 0; i < withAccents.length; i++) {
    result = result.replaceAll(withAccents[i], withoutAccents[i]);
  }
  return result;
}

Widget _v2StatChip({
  required IconData icon,
  required String value,
  required String label,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: V2Colors.surface,
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
          style: TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _kV2AppBar,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: V2Typography.family,
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
  int? bundleCount,
  String? bundleName,
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
        color: isRead ? V2Colors.surfaceMuted : V2Colors.surface,
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
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: _kV2AppBar,
                height: 1.25,
              ),
            ),
            if (bundleCount != null || bundleName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (bundleCount != null && bundleCount > 0)
                    _v2InfoChip(
                      icon: Icons.layers_outlined,
                      label:
                          '${AppLocalizations.of(context)!.bundle} · $bundleCount ${AppLocalizations.of(context)!.books}',
                      foregroundColor: _kV2AppBar,
                    ),
                  if (bundleName != null) ...[
                    if (bundleCount != null) const SizedBox(width: 8),
                    _v2InfoChip(
                      icon: Icons.folder_copy_outlined,
                      label: AppLocalizations.of(context)!.part_of_bundle,
                      foregroundColor: _kV2Text,
                      tooltip: bundleName,
                    ),
                  ],
                ],
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: _kV2Text, height: 1.43),
              ),
            ],
            if (year != null || isRead) ...[
              if (subtitle != null)
                Padding(
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
                      style: TextStyle(
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
                      style: TextStyle(
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

Widget _v2InfoChip({
  IconData? icon,
  required String label,
  required Color foregroundColor,
  String? tooltip,
}) {
  final chip = Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: foregroundColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: foregroundColor),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontFamily: V2Typography.family,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: foregroundColor,
            letterSpacing: 0.3,
          ),
        ),
      ],
    ),
  );

  if (tooltip != null && tooltip.isNotEmpty) {
    return Tooltip(message: tooltip, child: chip);
  }
  return chip;
}
