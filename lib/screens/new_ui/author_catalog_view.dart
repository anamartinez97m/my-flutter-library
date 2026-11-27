import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/author_catalog_item.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/screens/add_book.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:myrandomlibrary/services/author_catalog_service.dart';
import 'package:myrandomlibrary/services/open_library_service.dart';
import 'package:myrandomlibrary/utils/author_catalog.dart';

/// Whether catalog rows show a cover thumbnail.
const bool _showCovers = false;

/// Every book [author] has published (Open Library + Google Books), marked
/// against the library, with filters, search and corrections.
class AuthorCatalogView extends StatefulWidget {
  final String author;
  final BookProvider provider;

  const AuthorCatalogView({
    super.key,
    required this.author,
    required this.provider,
  });

  @override
  State<AuthorCatalogView> createState() => _AuthorCatalogViewState();
}

class _AuthorCatalogViewState extends State<AuthorCatalogView> {
  final _service = AuthorCatalogService();
  final _searchController = TextEditingController();

  AuthorCatalogResult? _result;
  CatalogOverrides _overrides = CatalogOverrides();
  bool _loading = true;

  /// Language name used to query the sources; null for any language.
  String? _language;
  CatalogFilter _filter = CatalogFilter.all;
  CatalogSort _sort = CatalogSort.oldest;
  bool _showHidden = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Book> get _library =>
      AuthorCatalog.libraryBooks(widget.provider.allBooks, widget.author);

  /// Library languages the sources can filter by, most used first.
  List<String> get _languageOptions {
    final counts = <String, int>{};
    for (final book in widget.provider.allBooks) {
      final language = book.languageValue?.trim();
      if (language == null || language.isEmpty) continue;
      if (OpenLibraryService.languageCode(language) == null) continue;
      counts[language] = (counts[language] ?? 0) + 1;
    }
    return counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  }

  String? _detectLanguage() {
    final counts = <String, int>{};
    for (final book in _library) {
      final language = book.languageValue?.trim();
      if (language == null || language.isEmpty) continue;
      if (OpenLibraryService.languageCode(language) == null) continue;
      counts[language] = (counts[language] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  Future<void> _init() async {
    final overrides = await _service.loadOverrides(widget.author);
    final saved = await _service.savedLanguage(widget.author);
    if (!mounted) return;
    setState(() {
      _overrides = overrides;
      _language =
          saved == null ? _detectLanguage() : (saved.isEmpty ? null : saved);
    });
    await _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _loading = true);
    final result = await _service.load(
      widget.author,
      language: _language,
      refresh: refresh,
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  Future<void> _updateOverrides(
    void Function(CatalogOverrides o) change,
  ) async {
    setState(() => change(_overrides));
    await _service.saveOverrides(widget.author, _overrides);
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _openBook(Book book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewBookDetailScreen(book: book)),
    );
    await widget.provider.loadBooks();
    if (mounted) setState(() {});
  }

  Future<void> _addBook(CatalogWork work, {String? statusValue}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddBookScreen(
              prefill: BookPrefill(
                title: work.title,
                author: widget.author,
                year: work.year,
                isbn: work.isbn,
                coverUrl: work.coverUrl,
                pages: work.pages,
                statusValue: statusValue,
              ),
            ),
      ),
    );
    await widget.provider.loadBooks();
    if (mounted) setState(() {});
  }

  Future<void> _linkExisting(AuthorCatalogItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final books = [..._library]..sort(
      (a, b) =>
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
    );
    final picked = await showModalBottomSheet<Book>(
      context: context,
      backgroundColor: V2Colors.background,
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      l10n.catalog_pick_book,
                      style: TextStyle(
                        fontFamily: V2Typography.family,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: V2Colors.primary,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final book in books)
                          ListTile(
                            title: Text(
                              book.name ?? l10n.unknown,
                              style: TextStyle(color: V2Colors.textPrimary),
                            ),
                            subtitle:
                                book.originalPublicationYear == null
                                    ? null
                                    : Text(
                                      '${book.originalPublicationYear}',
                                      style: TextStyle(
                                        color: V2Colors.textSubtle,
                                      ),
                                    ),
                            onTap: () => Navigator.pop(context, book),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
    if (picked == null) return;
    await _updateOverrides((o) {
      o.links.removeWhere((_, id) => id == picked.bookId);
      o.links[item.key] = picked.bookId!;
      o.notMine.remove(CatalogOverrides.pair(item.key, picked.bookId!));
    });
  }

  Future<void> _notMyCopy(AuthorCatalogItem item) => _updateOverrides((o) {
    o.links.remove(item.key);
    o.notMine.add(CatalogOverrides.pair(item.key, item.book!.bookId!));
  });

  Future<void> _toggleHidden(AuthorCatalogItem item) => _updateOverrides((o) {
    if (!o.hidden.remove(item.key)) o.hidden.add(item.key);
  });

  Future<void> _showItemSheet(AuthorCatalogItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final work = item.work;
    final book = item.book;
    final details = [
      if (item.year != null) '${item.year}',
      if (work != null) _sourceNames(work.sources),
      if (work?.isbn != null) 'ISBN ${work!.isbn}',
    ].join(' · ');

    Widget option(IconData icon, String label, VoidCallback onTap) => ListTile(
      leading: Icon(icon, color: V2Colors.primary),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: V2Typography.family,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: V2Colors.textPrimary,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: V2Colors.background,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontFamily: V2Typography.family,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: V2Colors.primary,
                        ),
                      ),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          details,
                          style: TextStyle(
                            fontFamily: V2Typography.family,
                            fontSize: 12,
                            color: V2Colors.textSubtle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(height: 1, color: V2Colors.divider),
                if (book != null)
                  option(
                    Icons.menu_book_outlined,
                    l10n.catalog_open_book,
                    () => _openBook(book),
                  ),
                if (book == null && work != null) ...[
                  option(
                    Icons.add,
                    l10n.catalog_add_to_library,
                    () => _addBook(work),
                  ),
                  option(
                    Icons.hourglass_empty,
                    l10n.catalog_add_tbreleased,
                    () => _addBook(work, statusValue: 'TBReleased'),
                  ),
                  option(
                    Icons.link,
                    l10n.catalog_link_existing,
                    () => _linkExisting(item),
                  ),
                ],
                if (book != null &&
                    (item.match == CatalogMatch.automatic ||
                        item.match == CatalogMatch.manual))
                  option(
                    Icons.link_off,
                    l10n.catalog_not_my_copy,
                    () => _notMyCopy(item),
                  ),
                option(
                  item.hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  item.hidden ? l10n.catalog_unhide : l10n.catalog_hide,
                  () => _toggleHidden(item),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final options = _languageOptions;
    if (_language != null && !options.contains(_language)) {
      options.insert(0, _language!);
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: V2Colors.background,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in ['', ...options])
                  ListTile(
                    title: Text(
                      option.isEmpty ? l10n.catalog_any_language : option,
                      style: TextStyle(color: V2Colors.textPrimary),
                    ),
                    trailing:
                        (option.isEmpty ? null : option) == _language
                            ? Icon(Icons.check, color: V2Colors.primary)
                            : null,
                    onTap: () => Navigator.pop(context, option),
                  ),
              ],
            ),
          ),
    );
    if (picked == null) return;
    final language = picked.isEmpty ? null : picked;
    if (language == _language) return;
    setState(() => _language = language);
    await _service.saveLanguage(widget.author, language);
    await _load();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  String _sourceNames(Set<String> sources) => [
    if (sources.contains(CatalogSource.openLibrary)) 'Open Library',
    if (sources.contains(CatalogSource.googleBooks)) 'Google Books',
  ].join(' · ');

  String _sortLabel(AppLocalizations l10n, CatalogSort sort) => switch (sort) {
    CatalogSort.oldest => l10n.catalog_sort_oldest,
    CatalogSort.newest => l10n.catalog_sort_newest,
    CatalogSort.title => l10n.catalog_sort_title,
  };

  TextStyle _text(double size, FontWeight weight, Color color) => TextStyle(
    fontFamily: V2Typography.family,
    fontSize: size,
    fontWeight: weight,
    color: color,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final result = _result;

    if (result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: V2Colors.primary),
            const SizedBox(height: 16),
            Text(
              l10n.fetching_author_books,
              style: _text(14, FontWeight.w500, V2Colors.textSubtle),
            ),
          ],
        ),
      );
    }

    final items = AuthorCatalog.build(
      works: result.works,
      library: _library,
      overrides: _overrides,
    );
    final visible = items.where((i) => !i.hidden).toList();
    final owned = visible.where((i) => i.isInLibrary).length;
    final read = visible.where((i) => i.isRead).length;
    final hiddenCount = items.length - visible.length;
    final filtered = AuthorCatalog.filter(
      items,
      filter: _filter,
      query: _searchController.text,
      showHidden: _showHidden,
    );
    final sections = AuthorCatalog.group(filtered, _sort);
    final hasSagas = sections.any((s) => s.kind == CatalogSectionKind.saga);
    final bottom = MediaQuery.paddingOf(context).bottom;

    final failedSources = {
      CatalogSource.openLibrary,
      CatalogSource.googleBooks,
    }.difference(result.sources);

    return RefreshIndicator(
      color: V2Colors.primary,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 24),
        children: [
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(
                color: V2Colors.primary,
                backgroundColor: V2Colors.divider,
              ),
            ),
          Row(
            children: [
              _stat('$owned / ${visible.length}', l10n.catalog_owned),
              const SizedBox(width: 8),
              _stat('$read', l10n.read_label),
              const SizedBox(width: 8),
              _stat('${visible.length - owned}', l10n.catalog_missing),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(V2Radii.pill),
            child: LinearProgressIndicator(
              value: visible.isEmpty ? 0 : owned / visible.length,
              minHeight: V2Sizes.progress,
              color: V2Colors.primary,
              backgroundColor: V2Colors.divider,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: _text(14, FontWeight.w500, V2Colors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.catalog_search_hint,
              hintStyle: _text(13, FontWeight.w400, V2Colors.textSubtle),
              prefixIcon: Icon(Icons.search, color: V2Colors.textSubtle),
              suffixIcon:
                  _searchController.text.isEmpty
                      ? null
                      : IconButton(
                        icon: Icon(Icons.close, color: V2Colors.textSubtle),
                        onPressed:
                            () => setState(() => _searchController.clear()),
                      ),
              filled: true,
              fillColor: V2Colors.searchBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(V2Radii.input),
                borderSide: BorderSide(color: V2Colors.borderNeutral),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(V2Radii.input),
                borderSide: BorderSide(color: V2Colors.borderNeutral),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(V2Radii.input),
                borderSide: BorderSide(color: V2Colors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (filter, label) in [
                (CatalogFilter.all, l10n.catalog_filter_all),
                (CatalogFilter.missing, l10n.catalog_missing),
                (CatalogFilter.owned, l10n.catalog_owned),
                (CatalogFilter.unread, l10n.catalog_filter_unread),
              ])
                _chip(
                  label,
                  selected: _filter == filter,
                  onTap: () => setState(() => _filter = filter),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip(
                l10n.catalog_language(_language ?? l10n.catalog_any_language),
                icon: Icons.language,
                muted: true,
                onTap: _pickLanguage,
              ),
              PopupMenuButton<CatalogSort>(
                color: V2Colors.surface,
                onSelected: (sort) => setState(() => _sort = sort),
                itemBuilder:
                    (context) => [
                      for (final sort in CatalogSort.values)
                        CheckedPopupMenuItem(
                          value: sort,
                          checked: sort == _sort,
                          child: Text(
                            _sortLabel(l10n, sort),
                            style: TextStyle(color: V2Colors.textPrimary),
                          ),
                        ),
                    ],
                child: _chip(
                  _sortLabel(l10n, _sort),
                  icon: Icons.swap_vert,
                  muted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              l10n.catalog_sources(_sourceNames(result.sources)),
              for (final source in failedSources)
                l10n.catalog_source_unavailable(_sourceNames({source})),
            ].join(' · '),
            style: _text(11, FontWeight.w500, V2Colors.textSubtle),
          ),
          if (result.sources.isEmpty && result.works.isEmpty) ...[
            const SizedBox(height: 32),
            Text(
              l10n.catalog_load_failed,
              textAlign: TextAlign.center,
              style: _text(14, FontWeight.w500, V2Colors.textSubtle),
            ),
          ] else if (filtered.isEmpty) ...[
            const SizedBox(height: 32),
            Text(
              items.isEmpty ? l10n.no_catalog_results : l10n.catalog_no_matches,
              textAlign: TextAlign.center,
              style: _text(14, FontWeight.w500, V2Colors.textSubtle),
            ),
          ],
          for (final section in sections) ...[
            _sectionHeader(l10n, section, hasSagas),
            for (final item in section.items) _card(l10n, item),
          ],
          if (hiddenCount > 0)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showHidden = !_showHidden),
                child: Text(
                  _showHidden
                      ? l10n.catalog_dont_show_hidden
                      : l10n.catalog_show_hidden(hiddenCount),
                  style: _text(13, FontWeight.w600, V2Colors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(V2Radii.input),
        border: Border.all(color: V2Colors.borderNeutral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: _text(17, FontWeight.w700, V2Colors.primary)),
          const SizedBox(height: 2),
          Text(label, style: _text(11, FontWeight.w500, V2Colors.textSubtle)),
        ],
      ),
    ),
  );

  Widget _chip(
    String label, {
    bool selected = false,
    bool muted = false,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final foreground = selected ? V2Colors.chipTextSelected : V2Colors.chipText;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color:
            selected
                ? V2Colors.chipSelected
                : (muted ? V2Colors.chip : V2Colors.surface),
        borderRadius: BorderRadius.circular(V2Radii.pill),
        border: Border.all(
          color:
              selected
                  ? V2Colors.chipSelected
                  : (muted ? V2Colors.chip : V2Colors.borderNeutral),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(label, style: _text(12, FontWeight.w600, foreground)),
          if (muted) Icon(Icons.arrow_drop_down, size: 16, color: foreground),
        ],
      ),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }

  Widget _sectionHeader(
    AppLocalizations l10n,
    CatalogSection section,
    bool hasSagas,
  ) {
    final (String title, String? trailing) = switch (section.kind) {
      CatalogSectionKind.saga => (
        section.title!,
        l10n.catalog_saga_owned(section.items.length),
      ),
      CatalogSectionKind.others => (
        hasSagas ? l10n.catalog_other_books : l10n.catalog_all_books,
        _sortLabel(l10n, _sort),
      ),
      CatalogSectionKind.unknownYear => (l10n.catalog_year_unknown, null),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: _text(
                12,
                FontWeight.w700,
                V2Colors.primary,
              ).copyWith(letterSpacing: 0.6),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: _text(11, FontWeight.w500, V2Colors.textSubtle),
            ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color foreground, Color background) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label.toUpperCase(),
      style: _text(
        10,
        FontWeight.w700,
        foreground,
      ).copyWith(letterSpacing: 0.3),
    ),
  );

  Widget _cover(AuthorCatalogItem item) {
    final url = item.coverUrl;
    final placeholder = Container(
      width: 44,
      height: 66,
      decoration: BoxDecoration(
        color: V2Colors.chip,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: V2Colors.borderNeutral),
      ),
      child: Icon(Icons.menu_book, size: 18, color: V2Colors.textSubtle),
    );
    if (url == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        url,
        width: 44,
        height: 66,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _card(AppLocalizations l10n, AuthorCatalogItem item) {
    final missing = !item.isInLibrary;
    final tag =
        item.isRead
            ? _tag(
              '✓ ${l10n.read_label}',
              V2Colors.success,
              V2Colors.successBackground,
            )
            : item.match == CatalogMatch.libraryOnly
            ? _tag(
              l10n.catalog_library_only_tag,
              V2Colors.primary,
              V2Colors.primary.withValues(alpha: 0.08),
            )
            : item.isInLibrary
            ? _tag(
              l10n.catalog_owned_tag,
              V2Colors.primary,
              V2Colors.primary.withValues(alpha: 0.08),
            )
            : _tag(
              _sourceNames(item.work!.sources),
              V2Colors.chipText,
              V2Colors.chip,
            );

    final card = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color:
            missing
                ? Colors.transparent
                : (item.isRead ? V2Colors.surfaceMuted : V2Colors.surface),
        borderRadius: BorderRadius.circular(V2Radii.input),
        border: Border.all(
          color: missing ? V2Colors.border : V2Colors.borderNeutral,
        ),
      ),
      child: Row(
        children: [
          if (_showCovers) ...[_cover(item), const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? l10n.unknown : item.title,
                  style: _text(
                    15,
                    missing ? FontWeight.w500 : FontWeight.w600,
                    missing ? V2Colors.textPrimary : V2Colors.primary,
                  ).copyWith(height: 1.25),
                ),
                if (item.sagaText != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.sagaText!,
                    style: _text(12, FontWeight.w400, V2Colors.textSubtle),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (item.year != null)
                      Text(
                        '${item.year}',
                        style: _text(11, FontWeight.w500, V2Colors.textSubtle),
                      ),
                    tag,
                  ],
                ),
              ],
            ),
          ),
          if (missing)
            IconButton(
              tooltip: l10n.catalog_add_to_library,
              onPressed: () => _showItemSheet(item),
              icon: Icon(Icons.add_circle_outline, color: V2Colors.primary),
            ),
        ],
      ),
    );

    return Opacity(
      opacity: item.hidden ? 0.5 : 1,
      child: GestureDetector(
        onTap:
            item.book != null
                ? () => _openBook(item.book!)
                : () => _showItemSheet(item),
        onLongPress: () => _showItemSheet(item),
        child: card,
      ),
    );
  }
}
