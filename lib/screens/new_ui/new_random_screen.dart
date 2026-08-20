import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_detail.dart';
import 'package:myrandomlibrary/screens/new_ui/new_genre_selection_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/new_option_selection_screen.dart';
import 'package:myrandomlibrary/widgets/chip_autocomplete_field.dart';
import 'package:provider/provider.dart';
import 'package:myrandomlibrary/widgets/shimmer_loading.dart';
import 'package:myrandomlibrary/widgets/random_shimmer.dart';

const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kBorder = Color(0xFFD5C2C7);
const _kCardBg = Color(0xB3FDF8F6);
const _kCardBorder = Color(0x4DD5C2C7);
const _kChipBg = Color(0x80F2EDEB);
const _kChipBorder = Color(0x80D5C2C7);
const _kChipSelected = Color(0xE643102B);
const _kCardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
];

class NewRandomScreen extends StatefulWidget {
  const NewRandomScreen({super.key});
  @override
  State<NewRandomScreen> createState() => _NewRandomScreenState();
}

class _NewRandomScreenState extends State<NewRandomScreen> {
  List<String> _filterFormat = [];
  String? _filterLanguage;
  List<String> _filterGenre = [];
  List<String> _filterPlace = [];
  List<String> _filterStatus = [];
  List<String> _filterEditorial = [];
  String? _filterFormatSaga;
  List<String> _filterPages = [];
  List<String> _filterYear = [];
  List<String> _filterAuthor = [];
  bool? _filterTBR;
  bool _genreUseAndLogic = true;
  bool _statusUseAndLogic = false;

  List<Map<String, dynamic>> _formatList = [];
  List<Map<String, dynamic>> _languageList = [];
  List<Map<String, dynamic>> _genreList = [];
  List<Map<String, dynamic>> _placeList = [];
  List<Map<String, dynamic>> _statusList = [];
  List<Map<String, dynamic>> _editorialList = [];
  List<Map<String, dynamic>> _authorList = [];

  Book? _randomBook;
  bool _isLoading = true;
  List<String> _selectedBookTitles = [];
  bool _useCustomList = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
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
      await repo.getLookupValues('format_saga');
      final author = await repo.getLookupValues('author');
      if (mounted) {
        setState(() {
          _formatList = format;
          _languageList = language;
          _genreList = genre;
          _placeList = place;
          _statusList = status;
          _editorialList = editorial;
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
    List<Book> filtered;
    if (_useCustomList && _selectedBookTitles.isNotEmpty) {
      filtered =
          provider.allBooks
              .where((b) => _selectedBookTitles.contains(b.name))
              .toList();
    } else {
      filtered =
          provider.allBooks.where((book) {
            if (_filterStatus.isNotEmpty) {
              if (book.statusValue == null ||
                  !_filterStatus.contains(book.statusValue)) {
                return false;
              }
            }
            if (_filterTBR != null && book.tbr != _filterTBR) return false;
            if (_filterFormat.isNotEmpty) {
              if (book.formatValue == null ||
                  !_filterFormat.contains(book.formatValue)) {
                return false;
              }
            }
            if (_filterLanguage != null &&
                book.languageValue != _filterLanguage) {
              return false;
            }
            if (_filterGenre.isNotEmpty) {
              final bookGenres =
                  book.genre?.split(',').map((g) => g.trim()).toList() ?? [];
              if (_genreUseAndLogic) {
                if (!_filterGenre.every((g) => bookGenres.contains(g))) {
                  return false;
                }
              } else {
                if (!_filterGenre.any((g) => bookGenres.contains(g))) {
                  return false;
                }
              }
            }
            if (_filterPlace.isNotEmpty) {
              if (book.placeValue == null ||
                  !_filterPlace.contains(book.placeValue)) {
                return false;
              }
            }
            if (_filterEditorial.isNotEmpty) {
              if (book.editorialValue == null ||
                  !_filterEditorial.contains(book.editorialValue)) {
                return false;
              }
            }
            if (_filterFormatSaga != null &&
                book.formatSagaValue != _filterFormatSaga) {
              return false;
            }
            if (_filterAuthor.isNotEmpty) {
              final authors =
                  book.author
                      ?.split(',')
                      .map((a) => a.trim())
                      .where((a) => a.isNotEmpty)
                      .toList() ??
                  [];
              if (!_filterAuthor.any((a) => authors.contains(a))) {
                return false;
              }
            }
            if (_filterPages.isNotEmpty && book.pages != null) {
              final p = book.pages!;
              if (!_filterPages.any((range) => _pagesInRange(p, range))) {
                return false;
              }
            }
            if (_filterYear.isNotEmpty &&
                book.originalPublicationYear != null) {
              final decade = (book.originalPublicationYear! ~/ 10) * 10;
              if (!_filterYear.any((y) => (int.tryParse(y) ?? -1) == decade)) {
                return false;
              }
            }
            return true;
          }).toList();
    }
    final sagaFiltered = _filterBySagaOrder(filtered, provider.allBooks);
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
  }

  List<Book> _filterBySagaOrder(List<Book> filtered, List<Book> allBooks) {
    final result = <Book>[];
    for (final book in filtered) {
      if (book.saga == null || book.saga!.isEmpty) {
        result.add(book);
        continue;
      }
      final bookNSaga = book.nSaga;
      if (bookNSaga == null || bookNSaga.isEmpty) {
        result.add(book);
        continue;
      }
      final currentNumber = int.tryParse(bookNSaga);
      if (currentNumber == null) {
        result.add(book);
        continue;
      }
      final sagaBooks =
          allBooks
              .where(
                (b) =>
                    b.saga == book.saga &&
                    b.nSaga != null &&
                    b.nSaga!.isNotEmpty,
              )
              .toList()
            ..sort(
              (a, b) => (int.tryParse(a.nSaga ?? '0') ?? 0).compareTo(
                int.tryParse(b.nSaga ?? '0') ?? 0,
              ),
            );
      bool canRecommend = true;
      for (final sb in sagaBooks) {
        final sbNum = int.tryParse(sb.nSaga ?? '0') ?? 0;
        if (sbNum < currentNumber) {
          final isRead =
              sb.statusValue != null &&
              (sb.statusValue!.toLowerCase().contains('read') ||
                  sb.statusValue!.toLowerCase().contains('leído') ||
                  sb.statusValue!.toLowerCase().contains('reread'));
          if (!isRead) {
            canRecommend = false;
            break;
          }
        }
      }
      if (canRecommend) result.add(book);
    }
    return result;
  }

  bool _pagesInRange(int pages, String range) {
    switch (range) {
      case '0-200':
        return pages >= 0 && pages <= 200;
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
      _filterFormat = [];
      _filterLanguage = null;
      _filterGenre = [];
      _filterPlace = [];
      _filterStatus = [];
      _filterEditorial = [];
      _filterFormatSaga = null;
      _filterPages = [];
      _filterYear = [];
      _filterAuthor = [];
      _filterTBR = null;
      _randomBook = null;
      _selectedBookTitles = [];
      _useCustomList = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: ShimmerLoading(child: RandomShimmer()),
      );
    }
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.discover_next_read,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.set_preferences_description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kPrimary),
            ),
            const SizedBox(height: 24),
            _buildSelectBooksCard(l10n),
            const SizedBox(height: 16),
            _buildFormatCard(l10n),
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
            if (_randomBook != null) ...[
              const SizedBox(height: 24),
              _buildResultCard(l10n),
            ],
            const SizedBox(height: 24),
            _buildActionButtons(l10n),
          ],
        ),
      ),
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
                  ? const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
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
            color: selected ? Colors.white : _kSub,
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

  Widget _buildSelectBooksCard(AppLocalizations l10n) {
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
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.library_books,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.select_books,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.select_books_card_subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: _kPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 16),
          Text(
            l10n.search_select_books_description,
            style: const TextStyle(fontSize: 12, color: _kSub),
          ),
          const SizedBox(height: 12),
          Consumer<BookProvider>(
            builder: (context, provider, _) {
              final titles =
                  provider.allBooks
                      .map((b) => b.name ?? '')
                      .where((n) => n.isNotEmpty)
                      .toList()
                    ..sort();
              return ChipAutocompleteField(
                labelText: l10n.select_books,
                prefixIcon: Icons.library_books,
                suggestions: titles,
                initialValues: _selectedBookTitles,
                hintText: l10n.type_to_search_books,
                onChanged:
                    (values) => setState(() {
                      _selectedBookTitles = values;
                      _useCustomList = values.isNotEmpty;
                    }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard(AppLocalizations l10n) {
    final allFormats = _formatList.map((f) => f['value'] as String).toList();
    if (allFormats.length <= 5) {
      return _sectionCard(
        icon: Icons.menu_book_outlined,
        title: l10n.format,
        child: _multiChipsField(
          selected: _filterFormat,
          options: allFormats,
          anyLabel: l10n.any,
          onChanged: (v) => setState(() => _filterFormat = v),
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
        selected: _filterFormat,
        popular: popular,
        allOptions: allFormats,
        anyLabel: l10n.any,
        multiSelect: true,
        onChanged: (v) => setState(() => _filterFormat = v),
      ),
    );
  }

  Widget _buildLanguageCard(AppLocalizations l10n) {
    return _sectionCard(
      icon: Icons.language,
      title: l10n.language,
      child: _singleChipsField<String>(
        selected: _filterLanguage,
        options: _languageList.map((e) => e['name'] as String).toList(),
        labelOf: (v) => v,
        anyLabel: l10n.all_label,
        onChanged: (v) => setState(() => _filterLanguage = v),
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
                selected: _filterGenre.isEmpty,
                onTap: () => setState(() => _filterGenre = []),
              ),
              ...popular.map(
                (g) => _smallChip(
                  label: g,
                  selected: _filterGenre.contains(g),
                  onTap: () {
                    final next = List<String>.from(_filterGenre);
                    if (next.contains(g)) {
                      next.remove(g);
                    } else {
                      next.add(g);
                    }
                    setState(() => _filterGenre = next);
                  },
                ),
              ),
            ],
          ),
          if (_filterGenre.length > 1) ...[
            const SizedBox(height: 8),
            _andOrToggle(
              useAndLogic: _genreUseAndLogic,
              onChanged: (v) => setState(() => _genreUseAndLogic = v),
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
                          initialSelected: _filterGenre,
                          initialUseAndLogic: _genreUseAndLogic,
                        ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _filterGenre = result.selected;
                    _genreUseAndLogic = result.useAndLogic;
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
            selected: _filterStatus,
            options: _statusList.map((s) => s['value'] as String).toList(),
            anyLabel: l10n.any,
            onChanged: (v) => setState(() => _filterStatus = v),
          ),
          if (_filterStatus.length > 1) ...[
            const SizedBox(height: 8),
            _andOrToggle(
              useAndLogic: _statusUseAndLogic,
              onChanged: (v) => setState(() => _statusUseAndLogic = v),
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
                  selected: _filterPlace,
                  options: allPlaces,
                  anyLabel: l10n.anywhere_label,
                  onChanged: (v) => setState(() => _filterPlace = v),
                );
              }
              final popular = _mostUsedOptions(
                allOptions: allPlaces,
                valuesOf: (b) => [if (b.placeValue != null) b.placeValue!],
              );
              return _seeAllOptionsField(
                l10n: l10n,
                fieldTitle: l10n.place,
                selected: _filterPlace,
                popular: popular,
                allOptions: allPlaces,
                anyLabel: l10n.anywhere_label,
                multiSelect: true,
                onChanged: (v) => setState(() => _filterPlace = v),
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
        selected: _filterTBR,
        options: const [true, false],
        labelOf: (v) => v ? l10n.yes_in_tbr : l10n.no_not_in_tbr,
        anyLabel: l10n.any,
        onChanged: (v) => setState(() => _filterTBR = v),
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
          selected: _filterEditorial,
          options: allEditorials,
          anyLabel: l10n.any,
          onChanged: (v) => setState(() => _filterEditorial = v),
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
        selected: _filterEditorial,
        popular: popular,
        allOptions: allEditorials,
        anyLabel: l10n.any,
        multiSelect: true,
        onChanged: (v) => setState(() => _filterEditorial = v),
      ),
    );
  }

  Widget _buildPagesCard(AppLocalizations l10n) {
    return _sectionCard(
      icon: Icons.description_outlined,
      title: l10n.pages,
      child: _multiChipsField(
        selected: _filterPages,
        options: const ['0-200', '200-400', '400-600', '600-900', '900+'],
        anyLabel: l10n.any,
        onChanged: (v) => setState(() => _filterPages = v),
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
    if (_decadeOptions.length <= 5) {
      return _sectionCard(
        icon: Icons.calendar_today_outlined,
        title: l10n.publication_year_decade,
        child: _multiChipsField(
          selected: _filterYear,
          options: _decadeOptions,
          anyLabel: l10n.any,
          labelBuilder: (v) => '${v}s',
          onChanged: (v) => setState(() => _filterYear = v),
        ),
      );
    }
    final popular = _mostUsedOptions(
      allOptions: _decadeOptions,
      valuesOf: (b) {
        final year = b.originalPublicationYear;
        if (year == null) return const <String>[];
        return [((year ~/ 10) * 10).toString()];
      },
    );
    return _sectionCard(
      icon: Icons.calendar_today_outlined,
      title: l10n.publication_year_decade,
      child: _seeAllOptionsField(
        l10n: l10n,
        fieldTitle: l10n.publication_year_decade,
        selected: _filterYear,
        popular: popular,
        allOptions: _decadeOptions,
        anyLabel: l10n.any,
        multiSelect: true,
        labelBuilder: (v) => '${v}s',
        onChanged: (v) => setState(() => _filterYear = v),
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
          selected: _filterAuthor,
          options: allAuthors,
          anyLabel: l10n.any,
          onChanged: (v) => setState(() => _filterAuthor = v),
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
        selected: _filterAuthor,
        popular: popular,
        allOptions: allAuthors,
        anyLabel: l10n.any,
        multiSelect: true,
        onChanged: (v) => setState(() => _filterAuthor = v),
      ),
    );
  }

  Widget _buildResultCard(AppLocalizations l10n) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewBookDetailScreen(book: _randomBook!),
            ),
          ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x4DCEC5BE)),
          boxShadow: _kCardShadow,
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_stories, size: 48, color: _kPrimary),
            const SizedBox(height: 16),
            Text(
              _randomBook!.name ?? l10n.unknown,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _kPrimary,
              ),
            ),
            if (_randomBook!.author != null) ...[
              const SizedBox(height: 6),
              Text(
                'by ${_randomBook!.author}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _kSub),
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _getRandomBook,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  l10n.try_another,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tap_to_view_details,
              style: const TextStyle(
                fontSize: 12,
                color: _kSub,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Column(
      children: [
        GestureDetector(
          onTap: _getRandomBook,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33430E29),
                  blurRadius: 8,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.casino, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _useCustomList
                        ? l10n.random_from_selected(
                          _selectedBookTitles.length.toString(),
                        )
                        : l10n.get_random_book,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.26,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _clearFilters,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: Text(
                l10n.clear_filters,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                  letterSpacing: 0.26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
