import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/config/new_ui_design_tokens.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:myrandomlibrary/widgets/chip_autocomplete_field.dart';
import 'package:provider/provider.dart';

class NewRandomScreen extends StatefulWidget {
  const NewRandomScreen({super.key});
  @override
  State<NewRandomScreen> createState() => _NewRandomScreenState();
}

class _NewRandomScreenState extends State<NewRandomScreen> {
  List<String> _filterFormat = [];
  String? _filterLanguage;
  List<String> _filterGenre = [];
  String? _filterPlace;
  List<String> _filterStatus = [];
  String? _filterEditorial;
  String? _filterFormatSaga;
  String? _filterPages;
  String? _filterYear;
  String? _filterAuthor;
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
            if (_filterPlace != null && book.placeValue != _filterPlace) {
              return false;
            }
            if (_filterEditorial != null &&
                book.editorialValue != _filterEditorial) {
              return false;
            }
            if (_filterFormatSaga != null &&
                book.formatSagaValue != _filterFormatSaga) {
              return false;
            }
            if (_filterAuthor != null &&
                !(book.author?.contains(_filterAuthor!) ?? false)) {
              return false;
            }
            if (_filterPages != null && book.pages != null) {
              final p = book.pages!;
              switch (_filterPages) {
                case '0-200':
                  if (p < 0 || p > 200) return false;
                  break;
                case '200-400':
                  if (p < 200 || p > 400) return false;
                  break;
                case '400-600':
                  if (p < 400 || p > 600) return false;
                  break;
                case '600-900':
                  if (p < 600 || p > 900) return false;
                  break;
                case '900+':
                  if (p < 900) return false;
                  break;
              }
            }
            if (_filterYear != null && book.originalPublicationYear != null) {
              final decade = (book.originalPublicationYear! ~/ 10) * 10;
              final fd = int.tryParse(_filterYear!);
              if (fd != null && decade != fd) return false;
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

  void _clearFilters() {
    setState(() {
      _filterFormat = [];
      _filterLanguage = null;
      _filterGenre = [];
      _filterPlace = null;
      _filterStatus = [];
      _filterEditorial = null;
      _filterFormatSaga = null;
      _filterPages = null;
      _filterYear = null;
      _filterAuthor = null;
      _filterTBR = null;
      _randomBook = null;
      _selectedBookTitles = [];
      _useCustomList = false;
    });
  }

  InputDecoration _deco(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: NewUiDesignTokens.textSecondary,
      letterSpacing: 0.55,
    ),
    floatingLabelStyle: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: NewUiDesignTokens.textSecondary,
      letterSpacing: 0.55,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: NewUiDesignTokens.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: NewUiDesignTokens.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        color: NewUiDesignTokens.primary,
        width: 1.5,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: NewUiDesignTokens.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: NewUiDesignTokens.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.random_book_picker,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: NewUiDesignTokens.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.random_book_description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: NewUiDesignTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildMainCard(l10n),
                  if (_randomBook != null) ...[
                    const SizedBox(height: 24),
                    _buildResultCard(l10n),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _buildActionBar(l10n),
        ],
      ),
    );
  }

  Widget _buildMainCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NewUiDesignTokens.borderFaint),
        boxShadow: const [
          BoxShadow(
            color: NewUiDesignTokens.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.filters,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: NewUiDesignTokens.textHighEmphasis,
                  ),
                ),
                const SizedBox(height: 24),
                _buildFiltersList(l10n),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Divider(color: NewUiDesignTokens.border, height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _buildCustomBookSection(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersList(AppLocalizations l10n) {
    return Column(
      children: [
        _buildMultiField(
          label: l10n.format,
          selected: _filterFormat,
          items: _formatList.map((f) => f['value'] as String).toList(),
          onChanged: (v) => setState(() => _filterFormat = v),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String?>(
          value: _filterLanguage,
          isExpanded: true,
          decoration: _deco(l10n.language),
          style: const TextStyle(
            fontSize: 16,
            color: NewUiDesignTokens.textHighEmphasis,
          ),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.any)),
            ..._languageList.map(
              (e) => DropdownMenuItem<String?>(
                value: e['name'] as String,
                child: Text(e['name'] as String),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _filterLanguage = v),
        ),
        const SizedBox(height: 20),
        _buildMultiField(
          label: l10n.genre,
          selected: _filterGenre,
          items: _genreList.map((g) => g['name'] as String).toList(),
          onChanged: (v) => setState(() => _filterGenre = v),
          andLogic: _filterGenre.length > 1 ? _genreUseAndLogic : null,
          onAndLogicToggle: (v) => setState(() => _genreUseAndLogic = v),
          andLabel: l10n.and_all_genres,
          orLabel: l10n.or_any_genre,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String?>(
          value: _filterPlace,
          isExpanded: true,
          decoration: _deco(l10n.place),
          style: const TextStyle(
            fontSize: 16,
            color: NewUiDesignTokens.textHighEmphasis,
          ),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.any)),
            ..._placeList.map(
              (e) => DropdownMenuItem<String?>(
                value: e['name'] as String,
                child: Text(e['name'] as String),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _filterPlace = v),
        ),
        const SizedBox(height: 20),
        _buildMultiField(
          label: l10n.status,
          selected: _filterStatus,
          items: _statusList.map((s) => s['value'] as String).toList(),
          onChanged: (v) => setState(() => _filterStatus = v),
          andLogic: _filterStatus.length > 1 ? _statusUseAndLogic : null,
          onAndLogicToggle: (v) => setState(() => _statusUseAndLogic = v),
          andLabel: l10n.and_not_practical,
          orLabel: l10n.or_any_status,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<bool?>(
          value: _filterTBR,
          isExpanded: true,
          decoration: _deco(l10n.tbr_filter_label),
          style: const TextStyle(
            fontSize: 16,
            color: NewUiDesignTokens.textHighEmphasis,
          ),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.any)),
            DropdownMenuItem(value: true, child: Text(l10n.yes_in_tbr)),
            DropdownMenuItem(value: false, child: Text(l10n.no_not_in_tbr)),
          ],
          onChanged: (v) => setState(() => _filterTBR = v),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String?>(
          value: _filterEditorial,
          isExpanded: true,
          decoration: _deco(l10n.editorial),
          style: const TextStyle(
            fontSize: 16,
            color: NewUiDesignTokens.textHighEmphasis,
          ),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.any)),
            ..._editorialList.map(
              (e) => DropdownMenuItem<String?>(
                value: e['name'] as String,
                child: Text(e['name'] as String),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _filterEditorial = v),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String?>(
          value: _filterPages,
          isExpanded: true,
          decoration: _deco(l10n.pages),
          style: const TextStyle(
            fontSize: 16,
            color: NewUiDesignTokens.textHighEmphasis,
          ),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.any)),
            const DropdownMenuItem(value: '0-200', child: Text('0-200')),
            const DropdownMenuItem(value: '200-400', child: Text('200-400')),
            const DropdownMenuItem(value: '400-600', child: Text('400-600')),
            const DropdownMenuItem(value: '600-900', child: Text('600-900')),
            const DropdownMenuItem(value: '900+', child: Text('900+')),
          ],
          onChanged: (v) => setState(() => _filterPages = v),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String?>(
          value: _filterYear,
          isExpanded: true,
          decoration: _deco(l10n.publication_year_decade),
          style: const TextStyle(
            fontSize: 16,
            color: NewUiDesignTokens.textHighEmphasis,
          ),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.any)),
            ...[
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
            ].map(
              (y) => DropdownMenuItem<String?>(value: y, child: Text('${y}s')),
            ),
          ],
          onChanged: (v) => setState(() => _filterYear = v),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String?>(
          value: _filterAuthor,
          isExpanded: true,
          decoration: _deco(l10n.author),
          style: const TextStyle(
            fontSize: 16,
            color: NewUiDesignTokens.textHighEmphasis,
          ),
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.any)),
            ..._authorList.map(
              (a) => DropdownMenuItem<String?>(
                value: a['name'] as String,
                child: Text(a['name'] as String),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _filterAuthor = v),
        ),
      ],
    );
  }

  Widget _buildMultiField({
    required String label,
    required List<String> selected,
    required List<String> items,
    required ValueChanged<List<String>> onChanged,
    bool? andLogic,
    ValueChanged<bool>? onAndLogicToggle,
    String? andLabel,
    String? orLabel,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        InkWell(
          onTap: () async {
            final r = await showDialog<List<String>>(
              context: context,
              builder:
                  (ctx) => _MultiSelectDialog(
                    title: label,
                    items: items,
                    initialSelected: selected,
                  ),
            );
            if (r != null) onChanged(r);
          },
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: _deco(label).copyWith(
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: NewUiDesignTokens.textSecondary,
              ),
            ),
            child: Text(
              selected.isEmpty ? l10n.any : selected.join(', '),
              style: const TextStyle(
                fontSize: 16,
                color: NewUiDesignTokens.textHighEmphasis,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (andLogic != null && onAndLogicToggle != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    andLogic
                        ? (andLabel ?? l10n.and_all_genres)
                        : (orLabel ?? l10n.or_any_genre),
                    style: const TextStyle(
                      fontSize: 11,
                      color: NewUiDesignTokens.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: NewUiDesignTokens.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ToggleButtons(
                  isSelected: [andLogic, !andLogic],
                  onPressed: (i) => onAndLogicToggle(i == 0),
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 40,
                  ),
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
          ),
        ],
      ],
    );
  }

  Widget _buildCustomBookSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.or_select_specific_books,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: NewUiDesignTokens.textHighEmphasis,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.search_select_books_description,
          style: const TextStyle(
            fontSize: 14,
            color: NewUiDesignTokens.textSecondary,
          ),
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
    );
  }

  Widget _buildResultCard(AppLocalizations l10n) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(book: _randomBook!),
            ),
          ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NewUiDesignTokens.borderFaint),
          boxShadow: const [
            BoxShadow(
              color: NewUiDesignTokens.shadowColor,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.auto_stories,
              size: 48,
              color: NewUiDesignTokens.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _randomBook!.name ?? l10n.unknown,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: NewUiDesignTokens.primary,
              ),
            ),
            if (_randomBook!.author != null) ...[
              const SizedBox(height: 6),
              Text(
                'by ${_randomBook!.author}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: NewUiDesignTokens.textSecondary,
                ),
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
                  color: NewUiDesignTokens.primary,
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
                color: NewUiDesignTokens.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: NewUiDesignTokens.background,
        border: Border(top: BorderSide(color: NewUiDesignTokens.actionBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _getRandomBook,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: NewUiDesignTokens.primary,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.casino, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _useCustomList
                            ? l10n.random_from_selected(
                              _selectedBookTitles.length.toString(),
                            )
                            : l10n.get_random_book,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _clearFilters,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: NewUiDesignTokens.clearButton,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Center(
                  child: Text(
                    l10n.clear,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: NewUiDesignTokens.textSecondary,
                      letterSpacing: 0.26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> initialSelected;
  const _MultiSelectDialog({
    required this.title,
    required this.items,
    required this.initialSelected,
  });
  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late List<String> _selected;
  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.items.length,
          itemBuilder: (_, i) {
            final item = widget.items[i];
            return CheckboxListTile(
              title: Text(item),
              value: _selected.contains(item),
              onChanged:
                  (checked) => setState(() {
                    if (checked == true) {
                      _selected.add(item);
                    } else {
                      _selected.remove(item);
                    }
                  }),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _selected.clear()),
          child: Text(l10n.clear_all),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
