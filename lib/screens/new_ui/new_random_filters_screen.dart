import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/new_genre_selection_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/new_option_selection_screen.dart';
import 'package:myrandomlibrary/utils/format_saga_helper.dart';
import 'package:myrandomlibrary/utils/saga_order_filter.dart';
import 'package:myrandomlibrary/widgets/random_pick_scaffold.dart';
import 'package:provider/provider.dart';

const _kPrimary = V2Colors.primary;
const _kSub = V2Colors.textSecondary;
const _kBorder = V2Colors.border;
final _kCardBg = V2Colors.background.withValues(alpha: 0.7);
final _kCardBorder = V2Colors.border.withValues(alpha: 0.3);
final _kChipBg = V2Colors.chip.withValues(alpha: 0.5);
final _kChipBorder = V2Colors.border.withValues(alpha: 0.5);
final _kChipSelected = V2Colors.primary.withValues(alpha: 0.9);
const _kAvoid = Color(0xFF8B4A3C);
const _kAvoidBg = Color(0xFFFFF0EC);
const _kAvoidBorder = Color(0xFFE3A99C);
const _kCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
];

/// Filter selections of the random screen, kept by [NewRandomScreen] so they
/// survive closing and reopening [NewRandomFiltersScreen].
class RandomFilters {
  List<String> format = [];
  String? language;
  List<String> genre = [];
  List<String> place = [];
  List<String> status = [];
  List<String> editorial = [];
  List<String> formatSaga = [];
  List<String> pages = [];
  List<String> year = [];
  List<String> author = [];
  List<String> excludedGenres = [];
  List<String> excludedFormats = [];
  List<String> excludedAuthors = [];
  bool? tbr;
  bool genreUseAndLogic = true;
  bool statusUseAndLogic = false;

  void clear() {
    format = [];
    language = null;
    genre = [];
    place = [];
    status = [];
    editorial = [];
    formatSaga = [];
    pages = [];
    year = [];
    author = [];
    excludedGenres = [];
    excludedFormats = [];
    excludedAuthors = [];
    tbr = null;
  }
}

class NewRandomFiltersScreen extends StatefulWidget {
  final RandomFilters filters;

  const NewRandomFiltersScreen({super.key, required this.filters});

  @override
  State<NewRandomFiltersScreen> createState() => _NewRandomFiltersScreenState();
}

class _NewRandomFiltersScreenState extends State<NewRandomFiltersScreen> {
  RandomFilters get _f => widget.filters;

  List<Map<String, dynamic>> _formatList = [];
  List<Map<String, dynamic>> _languageList = [];
  List<Map<String, dynamic>> _genreList = [];
  List<Map<String, dynamic>> _placeList = [];
  List<Map<String, dynamic>> _statusList = [];
  List<Map<String, dynamic>> _editorialList = [];
  List<Map<String, dynamic>> _formatSagaList = [];
  List<Map<String, dynamic>> _authorList = [];

  final _scrollController = ScrollController();
  Book? _randomBook;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repo = BookRepository(db);
      final format = await repo.getLookupValues('format');
      final language = await repo.getLookupValues('language');
      final genre = await repo.getLookupValues('genre');
      final place = await repo.getLookupValues('place');
      final status = await repo.getLookupValues('status');
      final editorial = await repo.getLookupValues('editorial');
      final formatSaga = await repo.getLookupValues('format_saga');
      final author = await repo.getLookupValues('author');
      if (mounted) {
        setState(() {
          _formatList = format;
          _languageList = language;
          _genreList = genre;
          _placeList = place;
          _statusList = status;
          _editorialList = editorial;
          _formatSagaList = formatSaga;
          _authorList = author;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading filters: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _getRandomBook() {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    if (provider == null) return;
    var filtered =
        provider.allBooks.where((book) {
          if (_f.status.isNotEmpty) {
            if (book.statusValue == null ||
                !_f.status.contains(book.statusValue)) {
              return false;
            }
          }
          if (_f.tbr != null && book.tbr != _f.tbr) return false;
          if (_f.format.isNotEmpty) {
            if (book.formatValue == null ||
                !_f.format.contains(book.formatValue)) {
              return false;
            }
          }
          if (_f.language != null && book.languageValue != _f.language) {
            return false;
          }
          if (_f.genre.isNotEmpty) {
            final bookGenres =
                book.genre?.split(',').map((g) => g.trim()).toList() ?? [];
            if (_f.genreUseAndLogic) {
              if (!_f.genre.every((g) => bookGenres.contains(g))) {
                return false;
              }
            } else {
              if (!_f.genre.any((g) => bookGenres.contains(g))) {
                return false;
              }
            }
          }
          if (_f.place.isNotEmpty) {
            if (book.placeValue == null ||
                !_f.place.contains(book.placeValue)) {
              return false;
            }
          }
          if (_f.editorial.isNotEmpty) {
            if (book.editorialValue == null ||
                !_f.editorial.contains(book.editorialValue)) {
              return false;
            }
          }
          if (_f.formatSaga.isNotEmpty) {
            if (book.formatSagaValue == null ||
                !_f.formatSaga.contains(book.formatSagaValue)) {
              return false;
            }
          }
          if (_f.author.isNotEmpty) {
            final authors =
                book.author
                    ?.split(',')
                    .map((a) => a.trim())
                    .where((a) => a.isNotEmpty)
                    .toList() ??
                [];
            if (!_f.author.any((a) => authors.contains(a))) {
              return false;
            }
          }
          final pages = _bookPages(book, provider.allBooks);
          if (_f.pages.isNotEmpty &&
              pages.isNotEmpty &&
              !_f.pages.any(
                (range) => pages.any((p) => _pagesInRange(p, range)),
              )) {
            return false;
          }
          final publicationYears = _bookPublicationYears(
            book,
            provider.allBooks,
          );
          if (_f.year.isNotEmpty &&
              publicationYears.isNotEmpty &&
              !_f.year.any(
                (year) => publicationYears.any(
                  (publicationYear) =>
                      (int.tryParse(year) ?? -1) ==
                      (publicationYear ~/ 10) * 10,
                ),
              )) {
            return false;
          }
          return true;
        }).toList();
    filtered = filtered.where((book) => !_isExcluded(book)).toList();
    final sagaFiltered = filterBySagaOrder(filtered, provider.allBooks);
    if (sagaFiltered.isEmpty) {
      setState(() => _randomBook = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.no_books_match_filters),
        ),
      );
      return;
    }
    setState(
      () => _randomBook = sagaFiltered[Random().nextInt(sagaFiltered.length)],
    );
    scrollToRandomResult(_scrollController);
  }

  bool _isExcluded(Book book) {
    if (book.formatValue != null &&
        _f.excludedFormats.contains(book.formatValue)) {
      return true;
    }

    final genres =
        book.genre
            ?.split(',')
            .map((genre) => genre.trim())
            .where((genre) => genre.isNotEmpty) ??
        const <String>[];
    if (genres.any(_f.excludedGenres.contains)) return true;

    final authors =
        book.author
            ?.split(',')
            .map((author) => author.trim())
            .where((author) => author.isNotEmpty) ??
        const <String>[];
    return authors.any(_f.excludedAuthors.contains);
  }

  List<int> _bookPages(Book book, List<Book> allBooks) => _bookNumericValues(
    primaryValue: book.pages,
    bundleValues: book.bundlePages,
    childValues: allBooks
        .where((child) => child.bundleParentId == book.bookId)
        .map((child) => child.pages),
  );

  List<int> _bookPublicationYears(Book book, List<Book> allBooks) =>
      _bookNumericValues(
        primaryValue: book.originalPublicationYear,
        bundleValues: book.bundlePublicationYears,
        childValues: allBooks
            .where((child) => child.bundleParentId == book.bookId)
            .map((child) => child.originalPublicationYear),
      ).where((year) => year >= 1000 && year <= 9999).toList();

  List<int> _bookNumericValues({
    required int? primaryValue,
    required String? bundleValues,
    Iterable<int?> childValues = const [],
  }) {
    final values = <int>{
      if (primaryValue != null) primaryValue,
      ...childValues.whereType<int>(),
    };
    if (bundleValues != null && bundleValues.isNotEmpty) {
      try {
        final decoded = jsonDecode(bundleValues);
        if (decoded is List) {
          values.addAll(
            decoded
                .map((value) => int.tryParse(value.toString()))
                .whereType<int>(),
          );
        }
      } on FormatException {
        return values.toList();
      }
    }
    return values.toList();
  }

  bool _pagesInRange(int pages, String range) {
    switch (range) {
      case '0-100':
        return pages >= 0 && pages <= 100;
      case '100-200':
        return pages >= 100 && pages <= 200;
      case '200-400':
        return pages >= 200 && pages <= 400;
      case '400-600':
        return pages >= 400 && pages <= 600;
      case '600-900':
        return pages >= 600 && pages <= 900;
      case '900+':
        return pages >= 900;
      default:
        return false;
    }
  }

  void _clearFilters() {
    setState(() {
      _f.clear();
      _randomBook = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RandomPickScaffold(
      title: l10n.filters,
      isLoading: _isLoading,
      scrollController: _scrollController,
      randomBook: _randomBook,
      onPick: _getRandomBook,
      pickLabel: l10n.get_random_book,
      onClear: _clearFilters,
      children: [
        _buildFormatCard(l10n),
        const SizedBox(height: 16),
        _buildFormatSagaCard(l10n),
        const SizedBox(height: 16),
        _buildLanguageCard(l10n),
        const SizedBox(height: 16),
        _buildGenreCard(l10n),
        const SizedBox(height: 16),
        _buildStatusPlaceCard(l10n),
        const SizedBox(height: 16),
        _buildTBRCard(l10n),
        const SizedBox(height: 16),
        _buildEditorialCard(l10n),
        const SizedBox(height: 16),
        _buildPagesCard(l10n),
        const SizedBox(height: 16),
        _buildDecadeCard(l10n),
        const SizedBox(height: 16),
        _buildAuthorCard(l10n),
        const SizedBox(height: 16),
        _buildAvoidCard(l10n),
      ],
    );
  }

  // ── Shared building blocks ──────────────────────────────────────────────

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kCardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                  letterSpacing: 0.26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _smallChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _kChipSelected : _kChipBg,
          borderRadius: BorderRadius.circular(9999),
          border: selected ? null : Border.all(color: _kChipBorder),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.55,
            color: selected ? V2Colors.surface : _kSub,
          ),
        ),
      ),
    );
  }

  Widget _andOrToggle({
    required bool useAndLogic,
    required ValueChanged<bool> onChanged,
    required String andLabel,
    required String orLabel,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            useAndLogic ? andLabel : orLabel,
            style: const TextStyle(
              fontSize: 11,
              color: _kSub,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ToggleButtons(
            isSelected: [useAndLogic, !useAndLogic],
            onPressed: (i) => onChanged(i == 0),
            borderRadius: BorderRadius.circular(8),
            constraints: const BoxConstraints(minHeight: 32, minWidth: 40),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('AND', style: TextStyle(fontSize: 10)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('OR', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _multiChipsField({
    required List<String> selected,
    required List<String> options,
    required String anyLabel,
    required ValueChanged<List<String>> onChanged,
    String Function(String)? labelBuilder,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _smallChip(
          label: anyLabel,
          selected: selected.isEmpty,
          onTap: () => onChanged([]),
        ),
        ...options.map((o) {
          final label = labelBuilder?.call(o) ?? o;
          return _smallChip(
            label: label,
            selected: selected.contains(o),
            onTap: () {
              final next = List<String>.from(selected);
              if (next.contains(o)) {
                next.remove(o);
              } else {
                next.add(o);
              }
              onChanged(next);
            },
          );
        }),
      ],
    );
  }

  Widget _singleChipsField<T>({
    required T? selected,
    required List<T> options,
    required String Function(T) labelOf,
    required String anyLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _smallChip(
          label: anyLabel,
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        ...options.map(
          (o) => _smallChip(
            label: labelOf(o),
            selected: selected == o,
            onTap: () => onChanged(selected == o ? null : o),
          ),
        ),
      ],
    );
  }

  // ── Sections ─────────────────────────────────────────────────────────────

  Widget _buildFormatCard(AppLocalizations l10n) {
    final allFormats = _formatList.map((f) => f['value'] as String).toList();
    if (allFormats.length <= 5) {
      return _sectionCard(
        icon: Icons.menu_book_outlined,
        title: l10n.format,
        child: _multiChipsField(
          selected: _f.format,
          options: allFormats,
          anyLabel: l10n.any,
          onChanged: (v) => setState(() => _f.format = v),
        ),
      );
    }
    final popular = _mostUsedOptions(
      allOptions: allFormats,
      valuesOf: (b) => [if (b.formatValue != null) b.formatValue!],
    );
    return _sectionCard(
      icon: Icons.menu_book_outlined,
      title: l10n.format,
      child: _seeAllOptionsField(
        l10n: l10n,
        fieldTitle: l10n.format,
        selected: _f.format,
        popular: popular,
        allOptions: allFormats,
        anyLabel: l10n.any,
        multiSelect: true,
        onChanged: (v) => setState(() => _f.format = v),
      ),
    );
  }

  Widget _buildFormatSagaCard(AppLocalizations l10n) {
    final allFormatSagas =
        _formatSagaList
            .map((e) => e['value'] as String?)
            .whereType<String>()
            .toList();
    if (allFormatSagas.length <= 5) {
      return _sectionCard(
        icon: Icons.auto_stories_outlined,
        title: l10n.format_saga,
        child: _multiChipsField(
          selected: _f.formatSaga,
          options: allFormatSagas,
          anyLabel: l10n.any,
          labelBuilder: (v) => FormatSagaHelper.getLocalizedLabel(v, l10n),
          onChanged: (v) => setState(() => _f.formatSaga = v),
        ),
      );
    }
    final popular = _mostUsedOptions(
      allOptions: allFormatSagas,
      valuesOf: (b) => [if (b.formatSagaValue != null) b.formatSagaValue!],
    );
    return _sectionCard(
      icon: Icons.auto_stories_outlined,
      title: l10n.format_saga,
      child: _seeAllOptionsField(
        l10n: l10n,
        fieldTitle: l10n.format_saga,
        selected: _f.formatSaga,
        popular: popular,
        allOptions: allFormatSagas,
        anyLabel: l10n.any,
        multiSelect: true,
        labelBuilder: (v) => FormatSagaHelper.getLocalizedLabel(v, l10n),
        onChanged: (v) => setState(() => _f.formatSaga = v),
      ),
    );
  }

  Widget _buildLanguageCard(AppLocalizations l10n) {
    return _sectionCard(
      icon: Icons.language,
      title: l10n.language,
      child: _singleChipsField<String>(
        selected: _f.language,
        options: _languageList.map((e) => e['name'] as String).toList(),
        labelOf: (v) => v,
        anyLabel: l10n.all_label,
        onChanged: (v) => setState(() => _f.language = v),
      ),
    );
  }

  /// Ranks [allOptions] by how often they occur across the library (as
  /// reported by [valuesOf] for each book) and returns the top [limit].
  List<String> _mostUsedOptions({
    required List<String> allOptions,
    required Iterable<String> Function(Book) valuesOf,
    int limit = 4,
  }) {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final counts = <String, int>{};
    if (provider != null) {
      for (final book in provider.allBooks) {
        for (final v in valuesOf(book)) {
          if (v.isEmpty) continue;
          counts[v] = (counts[v] ?? 0) + 1;
        }
      }
    }
    final sorted = List<String>.from(allOptions)..sort((a, b) {
      final diff = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
      if (diff != 0) return diff;
      return a.compareTo(b);
    });
    return sorted.where((o) => (counts[o] ?? 0) > 0).take(limit).toList();
  }

  List<String> _mostReadGenres(List<String> allGenreNames, {int limit = 4}) {
    return _mostUsedOptions(
      allOptions: allGenreNames,
      valuesOf:
          (book) =>
              book.genre
                  ?.split(',')
                  .map((g) => g.trim())
                  .where((g) => g.isNotEmpty) ??
              const <String>[],
      limit: limit,
    );
  }

  /// Builds a compact filter section that only shows the most-used options
  /// (plus an "any"/clear chip) with a "See all (N)" link that opens the
  /// full [NewOptionSelectionScreen] picker. Used for filters that have
  /// more than a handful of possible values.
  Widget _seeAllOptionsField({
    required AppLocalizations l10n,
    required String fieldTitle,
    required List<String> selected,
    required List<String> popular,
    required List<String> allOptions,
    required String anyLabel,
    required bool multiSelect,
    required ValueChanged<List<String>> onChanged,
    String Function(String)? labelBuilder,
  }) {
    String labelOf(String v) => labelBuilder != null ? labelBuilder(v) : v;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _smallChip(
              label: anyLabel,
              selected: selected.isEmpty,
              onTap: () => onChanged([]),
            ),
            ...popular.map(
              (o) => _smallChip(
                label: labelOf(o),
                selected: selected.contains(o),
                onTap: () {
                  if (multiSelect) {
                    final next = List<String>.from(selected);
                    if (next.contains(o)) {
                      next.remove(o);
                    } else {
                      next.add(o);
                    }
                    onChanged(next);
                  } else {
                    onChanged(selected.contains(o) ? [] : [o]);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push<OptionSelectionResult>(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => NewOptionSelectionScreen(
                        title: l10n.select_field_options(fieldTitle),
                        searchHint: l10n.search_field_options(fieldTitle),
                        popularLabel: l10n.most_used_label,
                        allLabel: l10n.all_field_options(fieldTitle),
                        anyLabel: anyLabel,
                        allOptions: allOptions,
                        popularOptions: popular,
                        initialSelected: selected,
                        multiSelect: multiSelect,
                        labelBuilder: labelBuilder,
                      ),
                ),
              );
              if (result != null) onChanged(result.selected);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.see_all_count(allOptions.length.toString()),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _kPrimary,
                    letterSpacing: 0.55,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 12, color: _kPrimary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreCard(AppLocalizations l10n) {
    final allGenreNames = _genreList.map((g) => g['name'] as String).toList();
    final popular = _mostReadGenres(allGenreNames);
    return _sectionCard(
      icon: Icons.category_outlined,
      title: l10n.genre,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallChip(
                label: l10n.surprise_me,
                selected: _f.genre.isEmpty,
                onTap: () => setState(() => _f.genre = []),
              ),
              ...popular.map(
                (g) => _smallChip(
                  label: g,
                  selected: _f.genre.contains(g),
                  onTap: () {
                    final next = List<String>.from(_f.genre);
                    if (next.contains(g)) {
                      next.remove(g);
                    } else {
                      next.add(g);
                    }
                    setState(() => _f.genre = next);
                  },
                ),
              ),
            ],
          ),
          if (_f.genre.length > 1) ...[
            const SizedBox(height: 8),
            _andOrToggle(
              useAndLogic: _f.genreUseAndLogic,
              onChanged: (v) => setState(() => _f.genreUseAndLogic = v),
              andLabel: l10n.and_all_genres,
              orLabel: l10n.or_any_genre,
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push<GenreSelectionResult>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => NewGenreSelectionScreen(
                          allGenres: allGenreNames,
                          popularGenres: popular,
                          initialSelected: _f.genre,
                          initialUseAndLogic: _f.genreUseAndLogic,
                        ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _f.genre = result.selected;
                    _f.genreUseAndLogic = result.useAndLogic;
                  });
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.see_all_count(allGenreNames.length.toString()),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _kPrimary,
                      letterSpacing: 0.55,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 12, color: _kPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPlaceCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kCardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, size: 15, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                l10n.status,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                  letterSpacing: 0.26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _multiChipsField(
            selected: _f.status,
            options: _statusList.map((s) => s['value'] as String).toList(),
            anyLabel: l10n.any,
            onChanged: (v) => setState(() => _f.status = v),
          ),
          if (_f.status.length > 1) ...[
            const SizedBox(height: 8),
            _andOrToggle(
              useAndLogic: _f.statusUseAndLogic,
              onChanged: (v) => setState(() => _f.statusUseAndLogic = v),
              andLabel: l10n.and_not_practical,
              orLabel: l10n.or_any_status,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: _kPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.place,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                  letterSpacing: 0.26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final allPlaces =
                  _placeList.map((e) => e['name'] as String).toList();
              if (allPlaces.length <= 5) {
                return _multiChipsField(
                  selected: _f.place,
                  options: allPlaces,
                  anyLabel: l10n.anywhere_label,
                  onChanged: (v) => setState(() => _f.place = v),
                );
              }
              final popular = _mostUsedOptions(
                allOptions: allPlaces,
                valuesOf: (b) => [if (b.placeValue != null) b.placeValue!],
              );
              return _seeAllOptionsField(
                l10n: l10n,
                fieldTitle: l10n.place,
                selected: _f.place,
                popular: popular,
                allOptions: allPlaces,
                anyLabel: l10n.anywhere_label,
                multiSelect: true,
                onChanged: (v) => setState(() => _f.place = v),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTBRCard(AppLocalizations l10n) {
    return _sectionCard(
      icon: Icons.bookmark_border,
      title: l10n.tbr_filter_label,
      child: _singleChipsField<bool>(
        selected: _f.tbr,
        options: const [true, false],
        labelOf: (v) => v ? l10n.yes_in_tbr : l10n.no_not_in_tbr,
        anyLabel: l10n.any,
        onChanged: (v) => setState(() => _f.tbr = v),
      ),
    );
  }

  Widget _buildEditorialCard(AppLocalizations l10n) {
    final allEditorials =
        _editorialList.map((e) => e['name'] as String).toList();
    if (allEditorials.length <= 5) {
      return _sectionCard(
        icon: Icons.business_outlined,
        title: l10n.editorial,
        child: _multiChipsField(
          selected: _f.editorial,
          options: allEditorials,
          anyLabel: l10n.any,
          onChanged: (v) => setState(() => _f.editorial = v),
        ),
      );
    }
    final popular = _mostUsedOptions(
      allOptions: allEditorials,
      valuesOf: (b) => [if (b.editorialValue != null) b.editorialValue!],
    );
    return _sectionCard(
      icon: Icons.business_outlined,
      title: l10n.editorial,
      child: _seeAllOptionsField(
        l10n: l10n,
        fieldTitle: l10n.editorial,
        selected: _f.editorial,
        popular: popular,
        allOptions: allEditorials,
        anyLabel: l10n.any,
        multiSelect: true,
        onChanged: (v) => setState(() => _f.editorial = v),
      ),
    );
  }

  Widget _buildPagesCard(AppLocalizations l10n) {
    return _sectionCard(
      icon: Icons.description_outlined,
      title: l10n.pages,
      child: _multiChipsField(
        selected: _f.pages,
        options: const [
          '0-100',
          '100-200',
          '200-400',
          '400-600',
          '600-900',
          '900+',
        ],
        anyLabel: l10n.any,
        onChanged: (v) => setState(() => _f.pages = v),
      ),
    );
  }

  static const _decadeOptions = [
    '1900',
    '1910',
    '1920',
    '1930',
    '1940',
    '1950',
    '1960',
    '1970',
    '1980',
    '1990',
    '2000',
    '2010',
    '2020',
  ];

  Widget _buildDecadeCard(AppLocalizations l10n) {
    final provider = Provider.of<BookProvider?>(context, listen: false);
    final decadeOptions = <String>{..._decadeOptions};
    if (provider != null) {
      for (final book in provider.allBooks) {
        decadeOptions.addAll(
          _bookPublicationYears(
            book,
            provider.allBooks,
          ).map((year) => '${(year ~/ 10) * 10}'),
        );
      }
    }
    final allDecades =
        decadeOptions.toList()
          ..sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    if (allDecades.length <= 5) {
      return _sectionCard(
        icon: Icons.calendar_today_outlined,
        title: l10n.publication_year_decade,
        child: _multiChipsField(
          selected: _f.year,
          options: allDecades,
          anyLabel: l10n.any,
          labelBuilder: (v) => '${v}s',
          onChanged: (v) => setState(() => _f.year = v),
        ),
      );
    }
    final popular = _mostUsedOptions(
      allOptions: allDecades,
      valuesOf:
          (book) => _bookPublicationYears(
            book,
            provider?.allBooks ?? [],
          ).map((year) => '${(year ~/ 10) * 10}'),
    );
    return _sectionCard(
      icon: Icons.calendar_today_outlined,
      title: l10n.publication_year_decade,
      child: _seeAllOptionsField(
        l10n: l10n,
        fieldTitle: l10n.publication_year_decade,
        selected: _f.year,
        popular: popular,
        allOptions: allDecades,
        anyLabel: l10n.any,
        multiSelect: true,
        labelBuilder: (v) => '${v}s',
        onChanged: (v) => setState(() => _f.year = v),
      ),
    );
  }

  Widget _buildAuthorCard(AppLocalizations l10n) {
    final allAuthors = _authorList.map((a) => a['name'] as String).toList();
    if (allAuthors.length <= 5) {
      return _sectionCard(
        icon: Icons.person_outline,
        title: l10n.author,
        child: _multiChipsField(
          selected: _f.author,
          options: allAuthors,
          anyLabel: l10n.any,
          onChanged: (v) => setState(() => _f.author = v),
        ),
      );
    }
    final popular = _mostUsedOptions(
      allOptions: allAuthors,
      valuesOf:
          (b) =>
              b.author
                  ?.split(',')
                  .map((a) => a.trim())
                  .where((a) => a.isNotEmpty) ??
              const <String>[],
    );
    return _sectionCard(
      icon: Icons.person_outline,
      title: l10n.author,
      child: _seeAllOptionsField(
        l10n: l10n,
        fieldTitle: l10n.author,
        selected: _f.author,
        popular: popular,
        allOptions: allAuthors,
        anyLabel: l10n.any,
        multiSelect: true,
        onChanged: (v) => setState(() => _f.author = v),
      ),
    );
  }

  Future<void> _openAvoidPicker({
    required AppLocalizations l10n,
    required String fieldTitle,
    required List<String> options,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) async {
    final result = await Navigator.push<OptionSelectionResult>(
      context,
      MaterialPageRoute(
        builder:
            (_) => NewOptionSelectionScreen(
              title: l10n.select_field_options(fieldTitle),
              searchHint: l10n.search_field_options(fieldTitle),
              popularLabel: l10n.most_used_label,
              allLabel: l10n.all_field_options(fieldTitle),
              anyLabel: l10n.any,
              allOptions: options,
              popularOptions: const [],
              initialSelected: selected,
              multiSelect: true,
            ),
      ),
    );
    if (result != null) onChanged(result.selected);
  }

  Widget _avoidSelectionRow({
    required String label,
    required List<String> selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ),
            if (selected.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kAvoidBg,
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: _kAvoidBorder),
                ),
                child: Text(
                  '${selected.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kAvoid,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18, color: _kPrimary),
          ],
        ),
      ),
    );
  }

  Widget _avoidChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: _kAvoidBg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: _kAvoidBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_circle_outline, size: 15, color: _kAvoid),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kAvoid,
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(9999),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.close, size: 13, color: _kAvoid),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvoidCard(AppLocalizations l10n) {
    final formats = _formatList.map((item) => item['value'] as String).toList();
    final genres = _genreList.map((item) => item['name'] as String).toList();
    final authors = _authorList.map((item) => item['name'] as String).toList();
    final hasExclusions =
        _f.excludedGenres.isNotEmpty ||
        _f.excludedFormats.isNotEmpty ||
        _f.excludedAuthors.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kCardBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.block, size: 17, color: _kAvoid),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.avoid_from_recommendation,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                    letterSpacing: 0.26,
                  ),
                ),
              ),
              Text(
                l10n.optional,
                style: const TextStyle(fontSize: 11, color: _kSub),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.avoid_recommendation_description,
            style: const TextStyle(fontSize: 12, color: _kSub, height: 1.35),
          ),
          if (hasExclusions) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                ..._f.excludedGenres.map(
                  (value) => _avoidChip(
                    value,
                    () => setState(() => _f.excludedGenres.remove(value)),
                  ),
                ),
                ..._f.excludedFormats.map(
                  (value) => _avoidChip(
                    value,
                    () => setState(() => _f.excludedFormats.remove(value)),
                  ),
                ),
                ..._f.excludedAuthors.map(
                  (value) => _avoidChip(
                    value,
                    () => setState(() => _f.excludedAuthors.remove(value)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: _kBorder),
          _avoidSelectionRow(
            label: l10n.genre,
            selected: _f.excludedGenres,
            onTap:
                () => _openAvoidPicker(
                  l10n: l10n,
                  fieldTitle: l10n.genre,
                  options: genres,
                  selected: _f.excludedGenres,
                  onChanged:
                      (values) => setState(() => _f.excludedGenres = values),
                ),
          ),
          const Divider(height: 1, color: _kBorder),
          _avoidSelectionRow(
            label: l10n.format,
            selected: _f.excludedFormats,
            onTap:
                () => _openAvoidPicker(
                  l10n: l10n,
                  fieldTitle: l10n.format,
                  options: formats,
                  selected: _f.excludedFormats,
                  onChanged:
                      (values) => setState(() => _f.excludedFormats = values),
                ),
          ),
          const Divider(height: 1, color: _kBorder),
          _avoidSelectionRow(
            label: l10n.author,
            selected: _f.excludedAuthors,
            onTap:
                () => _openAvoidPicker(
                  l10n: l10n,
                  fieldTitle: l10n.author,
                  options: authors,
                  selected: _f.excludedAuthors,
                  onChanged:
                      (values) => setState(() => _f.excludedAuthors = values),
                ),
          ),
        ],
      ),
    );
  }
}
