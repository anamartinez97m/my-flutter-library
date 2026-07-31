import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/add_book.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';
import 'package:myrandomlibrary/utils/format_saga_helper.dart';
import 'package:myrandomlibrary/utils/status_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Figma design tokens ────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF43102B);
const _kBg = Color(0xFFFDF8F6);
const _kBorder = Color(0xFFCEC5BE);
const _kDivider = Color(0xFFE6E2DF);
const _kText = Color(0xFF5F5E5C);
const _kInactiveText = Color(0xFF514348);
const _kFabSmall = Color(0xFFECE7E5);

class NewHomeScreen extends StatefulWidget {
  final void Function(VoidCallback)? onRegisterClearSearch;

  const NewHomeScreen({super.key, this.onRegisterClearSearch});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSearchButtonIndex = 0;
  String _sortBy = 'name';
  bool _ascending = true;

  List<Map<String, dynamic>> _formatList = [];
  List<Map<String, dynamic>> _languageList = [];
  List<Map<String, dynamic>> _genreList = [];
  List<Map<String, dynamic>> _placeList = [];
  List<Map<String, dynamic>> _statusList = [];
  List<Map<String, dynamic>> _editorialList = [];
  List<Map<String, dynamic>> _sagaList = [];
  List<Map<String, dynamic>> _sagaUniverseList = [];
  List<Map<String, dynamic>> _formatSagaList = [];

  String? _selectedFormat,
      _selectedLanguage,
      _selectedGenre,
      _selectedPlace,
      _selectedStatus,
      _selectedTitle,
      _selectedIsbnAsin,
      _selectedAuthor,
      _selectedEditorial,
      _selectedSaga,
      _selectedSagaUniverse,
      _selectedFormatSaga,
      _selectedPagesEmpty,
      _selectedIsBundle,
      _selectedIsTandem,
      _selectedSagaFormatWithoutSaga,
      _selectedSagaFormatWithoutNSaga,
      _selectedSagaWithoutFormatSaga,
      _selectedPublicationYearEmpty,
      _selectedRating,
      _selectedPrice;

  Set<String> _enabledFilters = {};
  Set<String> _enabledCardFields = {
    'title',
    'author',
    'saga',
    'format',
    'language',
  };
  bool _isAdmin = false;

  void clearSearch() {
    if (_searchController.text.isNotEmpty) {
      setState(() => _searchController.clear());
      Provider.of<BookProvider?>(
        context,
        listen: false,
      )?.searchBooks('', searchIndex: _selectedSearchButtonIndex);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.onRegisterClearSearch?.call(clearSearch);
    _loadEnabledFilters();
    _loadEnabledCardFields();
    _loadFilterOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<BookProvider?>(context, listen: false);
      if (p != null) {
        setState(() {
          _selectedFormat = p.currentFilters['format'];
          _selectedLanguage = p.currentFilters['language'];
          _selectedGenre = p.currentFilters['genre'];
          _selectedPlace = p.currentFilters['place'];
          _selectedStatus = p.currentFilters['status'];
          _selectedTitle = p.currentFilters['title'];
          _selectedIsbnAsin = p.currentFilters['isbn'];
          _selectedAuthor = p.currentFilters['author'];
          _selectedEditorial = p.currentFilters['editorial'];
          _selectedSaga = p.currentFilters['saga'];
          _selectedSagaUniverse = p.currentFilters['saga_universe'];
          _selectedFormatSaga = p.currentFilters['format_saga'];
          _selectedPagesEmpty = p.currentFilters['pages_empty'];
          _selectedIsBundle = p.currentFilters['is_bundle'];
          _selectedIsTandem = p.currentFilters['is_tandem'];
          _selectedSagaFormatWithoutSaga =
              p.currentFilters['saga_format_without_saga'];
          _selectedSagaFormatWithoutNSaga =
              p.currentFilters['saga_format_without_nsaga'];
          _selectedSagaWithoutFormatSaga =
              p.currentFilters['saga_without_format_saga'];
          _selectedPublicationYearEmpty =
              p.currentFilters['publication_year_empty'];
          _selectedRating = p.currentFilters['rating'];
          _selectedPrice = p.currentFilters['price'];
          _sortBy = p.currentSortBy;
          _ascending = p.currentSortAscending;
        });
      }
    });
  }

  Future<void> _loadEnabledFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('enabled_filters');
    final isAdmin = prefs.getBool('is_admin') ?? false;
    setState(() {
      _isAdmin = isAdmin;
      _enabledFilters =
          saved?.toSet() ??
          {
            'title',
            'isbn',
            'author',
            'status',
            'format',
            'genre',
            'language',
            'place',
            'editorial',
            'saga',
            'saga_universe',
            'format_saga',
            'pages_empty',
            'is_bundle',
            'is_tandem',
            'saga_without_format_saga',
            'publication_year_empty',
            'rating',
          };
    });
  }

  bool _isFilterEnabled(String key) => _enabledFilters.contains(key);

  Future<void> _loadEnabledCardFields() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('enabled_card_fields');
    if (!mounted) return;
    setState(() {
      _enabledCardFields =
          saved?.toSet() ?? {'title', 'author', 'saga', 'format', 'language'};
    });
  }

  Future<void> _loadFilterOptions() async {
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
      final sagas = await db.rawQuery('''
        SELECT DISTINCT saga as name FROM book
        WHERE saga IS NOT NULL AND saga != '' ORDER BY saga
      ''');
      final sagaUniverses = await db.rawQuery('''
        SELECT DISTINCT saga_universe as name FROM book
        WHERE saga_universe IS NOT NULL AND saga_universe != '' ORDER BY saga_universe
      ''');
      if (!mounted) return;
      setState(() {
        _formatList = format;
        _languageList = language;
        _genreList = genre;
        _placeList = place;
        _statusList = status;
        _editorialList = editorial;
        _formatSagaList = formatSaga;
        _sagaList = sagas;
        _sagaUniverseList = sagaUniverses;
      });
    } catch (e) {
      debugPrint('Error loading filter options: $e');
    }
  }

  // ── Filter sheet helpers ─────────────────────────────────────────────────────

  InputDecoration _figmaDropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF514348),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: _kBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF27231E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF27231E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF27231E)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
    );
  }

  Widget _filterDropdown({
    required BuildContext ctx,
    required BookProvider provider,
    required StateSetter setModalState,
    required String filterKey,
    required String label,
    required String? value,
    required void Function(String?) assign,
    required List<DropdownMenuItem<String>> extras,
    bool adminOnly = false,
    bool withEmpty = false,
  }) {
    if (adminOnly && !_isAdmin) return const SizedBox.shrink();
    if (!_isFilterEnabled(filterKey)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(ctx)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        menuMaxHeight: 300,
        decoration: _figmaDropdownDecoration(label),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.any)),
          if (withEmpty)
            DropdownMenuItem(value: '__EMPTY__', child: Text(l10n.empty)),
          ...extras,
        ],
        onChanged: (v) {
          setState(() => assign(v));
          v != null
              ? provider.filterBooks(filterKey, v)
              : provider.filterBooks('all', null);
          setModalState(() {});
        },
      ),
    );
  }

  Widget _yesNoDropdown({
    required BuildContext ctx,
    required BookProvider provider,
    required StateSetter setModalState,
    required String filterKey,
    required String label,
    required String? value,
    required void Function(String?) assign,
    bool adminOnly = false,
  }) {
    if (adminOnly && !_isAdmin) return const SizedBox.shrink();
    if (!_isFilterEnabled(filterKey)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(ctx)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        menuMaxHeight: 300,
        decoration: _figmaDropdownDecoration(label),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.any)),
          DropdownMenuItem(value: 'true', child: Text(l10n.yes)),
          DropdownMenuItem(value: 'false', child: Text(l10n.no)),
        ],
        onChanged: (v) {
          setState(() => assign(v));
          v != null
              ? provider.filterBooks(filterKey, v)
              : provider.filterBooks('all', null);
          setModalState(() {});
        },
      ),
    );
  }

  void _showFilterSortSheet(BuildContext context, BookProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (ctx, scrollController) => StatefulBuilder(
                  builder: (ctx, setModalState) {
                    final l10n = AppLocalizations.of(ctx)!;
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Container(
                        color: _kBg,
                        child: Column(
                          children: [
                            // ── Header ──────────────────────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: const BoxDecoration(
                                color: _kBg,
                                border: Border(
                                  bottom: BorderSide(color: _kDivider),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.sort_and_filter,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1C1B1A),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(ctx),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Color(0xFF1C1B1A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ── Scrollable content ───────────────────────────
                            Expanded(
                              child: ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  16,
                                ),
                                children: [
                                  // Sort section
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.sort,
                                        size: 18,
                                        color: Color(0xFF1C1B1A),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        l10n.sort_by,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1C1B1A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 17,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _kBg,
                                      border: Border.all(
                                        color: const Color(0xFF27231E),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _sortBy,
                                              isExpanded: true,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF1C1B1A),
                                              ),
                                              icon: const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Color(0xFF1C1B1A),
                                              ),
                                              items: [
                                                DropdownMenuItem(
                                                  value: 'name',
                                                  child: Text(l10n.book_name),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'author',
                                                  child: Text(l10n.author),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'created_at',
                                                  child: Text(
                                                    l10n.date_created,
                                                  ),
                                                ),
                                              ],
                                              onChanged: (v) {
                                                if (v != null) {
                                                  setState(() => _sortBy = v);
                                                  provider.sortBooks(
                                                    _sortBy,
                                                    _ascending,
                                                  );
                                                  setModalState(() {});
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        GestureDetector(
                                          onTap: () {
                                            setState(
                                              () => _ascending = !_ascending,
                                            );
                                            provider.sortBooks(
                                              _sortBy,
                                              _ascending,
                                            );
                                            setModalState(() {});
                                          },
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _kFabSmall,
                                              border: Border.all(
                                                color: const Color(0xFFD5C2C7),
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              _ascending
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward,
                                              size: 16,
                                              color: _kInactiveText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Divider(
                                    color: _kDivider,
                                    height: 1,
                                    thickness: 1,
                                  ),
                                  const SizedBox(height: 24),
                                  // Filters heading
                                  Text(
                                    l10n.filters,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1C1B1A),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'title',
                                    label: l10n.book_name,
                                    value: _selectedTitle,
                                    assign: (v) => _selectedTitle = v,
                                    extras: [],
                                    withEmpty: true,
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'isbn',
                                    label: l10n.isbn_asin,
                                    value: _selectedIsbnAsin,
                                    assign: (v) => _selectedIsbnAsin = v,
                                    extras: [],
                                    withEmpty: true,
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'author',
                                    label: l10n.author,
                                    value: _selectedAuthor,
                                    assign: (v) => _selectedAuthor = v,
                                    extras: [],
                                    withEmpty: true,
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'status',
                                    label: l10n.status,
                                    value: _selectedStatus,
                                    assign: (v) => _selectedStatus = v,
                                    extras:
                                        _statusList
                                            .where((i) => i['value'] != null)
                                            .map(
                                              (i) => DropdownMenuItem<String>(
                                                value: i['value'] as String,
                                                child: Text(
                                                  StatusHelper.getLocalizedLabel(
                                                    i['value'] as String,
                                                    l10n,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'format',
                                    label: l10n.format,
                                    value: _selectedFormat,
                                    assign: (v) => _selectedFormat = v,
                                    withEmpty: true,
                                    extras:
                                        _formatList
                                            .where((i) => i['value'] != null)
                                            .map(
                                              (i) => DropdownMenuItem<String>(
                                                value: i['value'] as String,
                                                child: Text(
                                                  i['value'] as String,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'genre',
                                    label: l10n.genre,
                                    value: _selectedGenre,
                                    assign: (v) => _selectedGenre = v,
                                    withEmpty: true,
                                    extras:
                                        _genreList
                                            .where((i) => i['value'] != null)
                                            .map(
                                              (i) => DropdownMenuItem<String>(
                                                value: i['value'] as String,
                                                child: Text(
                                                  i['value'] as String,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'language',
                                    label: l10n.language,
                                    value: _selectedLanguage,
                                    assign: (v) => _selectedLanguage = v,
                                    withEmpty: true,
                                    extras:
                                        _languageList
                                            .where((i) => i['value'] != null)
                                            .map(
                                              (i) => DropdownMenuItem<String>(
                                                value: i['value'] as String,
                                                child: Text(
                                                  i['value'] as String,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'place',
                                    label: l10n.place,
                                    value: _selectedPlace,
                                    assign: (v) => _selectedPlace = v,
                                    withEmpty: true,
                                    extras:
                                        _placeList
                                            .where((i) => i['value'] != null)
                                            .map(
                                              (i) => DropdownMenuItem<String>(
                                                value: i['value'] as String,
                                                child: Text(
                                                  i['value'] as String,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'editorial',
                                    label: l10n.editorial,
                                    value: _selectedEditorial,
                                    assign: (v) => _selectedEditorial = v,
                                    withEmpty: true,
                                    extras:
                                        _editorialList
                                            .where((i) => i['value'] != null)
                                            .map(
                                              (i) => DropdownMenuItem<String>(
                                                value: i['value'] as String,
                                                child: Text(
                                                  i['value'] as String,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'saga',
                                    label: l10n.saga,
                                    value: _selectedSaga,
                                    assign: (v) => _selectedSaga = v,
                                    withEmpty: true,
                                    extras:
                                        _sagaList
                                            .where((i) => i['name'] != null)
                                            .map(
                                              (i) => DropdownMenuItem<String>(
                                                value: i['name'] as String,
                                                child: Text(
                                                  i['name'] as String,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'saga_universe',
                                    label: l10n.saga_universe,
                                    value: _selectedSagaUniverse,
                                    assign: (v) => _selectedSagaUniverse = v,
                                    withEmpty: true,
                                    extras:
                                        _sagaUniverseList
                                            .where((i) => i['name'] != null)
                                            .map(
                                              (i) => DropdownMenuItem<String>(
                                                value: i['name'] as String,
                                                child: Text(
                                                  i['name'] as String,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'format_saga',
                                    label: l10n.format_saga,
                                    value: _selectedFormatSaga,
                                    assign: (v) => _selectedFormatSaga = v,
                                    withEmpty: true,
                                    extras:
                                        _formatSagaList
                                            .where((i) => i['value'] != null)
                                            .map(
                                              (i) => DropdownMenuItem<String>(
                                                value: i['value'] as String,
                                                child: Text(
                                                  FormatSagaHelper.getLocalizedLabel(
                                                    i['value'] as String,
                                                    l10n,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'pages_empty',
                                    label: l10n.pages,
                                    value: _selectedPagesEmpty,
                                    assign: (v) => _selectedPagesEmpty = v,
                                    withEmpty: true,
                                    adminOnly: true,
                                    extras: [
                                      DropdownMenuItem(
                                        value: '<100',
                                        child: Text(l10n.pages_range_under_100),
                                      ),
                                      DropdownMenuItem(
                                        value: '100-300',
                                        child: Text(l10n.pages_range_100_300),
                                      ),
                                      DropdownMenuItem(
                                        value: '300-500',
                                        child: Text(l10n.pages_range_300_500),
                                      ),
                                      DropdownMenuItem(
                                        value: '500-700',
                                        child: Text(l10n.pages_range_500_700),
                                      ),
                                      DropdownMenuItem(
                                        value: '700+',
                                        child: Text(l10n.pages_range_700_plus),
                                      ),
                                    ],
                                  ),
                                  _yesNoDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'is_bundle',
                                    label: l10n.bundle,
                                    value: _selectedIsBundle,
                                    assign: (v) => _selectedIsBundle = v,
                                  ),
                                  _yesNoDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'is_tandem',
                                    label: l10n.tandem,
                                    value: _selectedIsTandem,
                                    assign: (v) => _selectedIsTandem = v,
                                  ),
                                  _yesNoDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'saga_format_without_saga',
                                    label: l10n.saga_format_without_saga,
                                    value: _selectedSagaFormatWithoutSaga,
                                    assign:
                                        (v) =>
                                            _selectedSagaFormatWithoutSaga = v,
                                    adminOnly: true,
                                  ),
                                  _yesNoDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'saga_format_without_nsaga',
                                    label: l10n.saga_format_without_n_saga,
                                    value: _selectedSagaFormatWithoutNSaga,
                                    assign:
                                        (v) =>
                                            _selectedSagaFormatWithoutNSaga = v,
                                    adminOnly: true,
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'publication_year_empty',
                                    label: l10n.publication_year_empty,
                                    value: _selectedPublicationYearEmpty,
                                    assign:
                                        (v) =>
                                            _selectedPublicationYearEmpty = v,
                                    withEmpty: true,
                                    adminOnly: true,
                                    extras: [],
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'rating',
                                    label: l10n.rating_filter,
                                    value: _selectedRating,
                                    assign: (v) => _selectedRating = v,
                                    extras: const [
                                      DropdownMenuItem(
                                        value: '0-1',
                                        child: Text('0–1 ⭐'),
                                      ),
                                      DropdownMenuItem(
                                        value: '1-2',
                                        child: Text('1–2 ⭐'),
                                      ),
                                      DropdownMenuItem(
                                        value: '2-3',
                                        child: Text('2–3 ⭐'),
                                      ),
                                      DropdownMenuItem(
                                        value: '3-4',
                                        child: Text('3–4 ⭐'),
                                      ),
                                      DropdownMenuItem(
                                        value: '4-5',
                                        child: Text('4–5 ⭐'),
                                      ),
                                    ],
                                  ),
                                  _yesNoDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'saga_without_format_saga',
                                    label: l10n.saga_without_format_saga,
                                    value: _selectedSagaWithoutFormatSaga,
                                    assign:
                                        (v) =>
                                            _selectedSagaWithoutFormatSaga = v,
                                    adminOnly: true,
                                  ),
                                  _filterDropdown(
                                    ctx: ctx,
                                    provider: provider,
                                    setModalState: setModalState,
                                    filterKey: 'price',
                                    label: l10n.filter_price,
                                    value: _selectedPrice,
                                    assign: (v) => _selectedPrice = v,
                                    withEmpty: true,
                                    extras: [
                                      DropdownMenuItem(
                                        value: 'free',
                                        child: Text(l10n.price_free),
                                      ),
                                      DropdownMenuItem(
                                        value: '<5',
                                        child: Text(l10n.price_range_under_5),
                                      ),
                                      DropdownMenuItem(
                                        value: '5-15',
                                        child: Text(l10n.price_range_5_15),
                                      ),
                                      DropdownMenuItem(
                                        value: '15-30',
                                        child: Text(l10n.price_range_15_30),
                                      ),
                                      DropdownMenuItem(
                                        value: '30+',
                                        child: Text(l10n.price_range_30_plus),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // ── Footer ──────────────────────────────────────
                            Container(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                11,
                                20,
                                20 + MediaQuery.of(ctx).viewPadding.bottom,
                              ),
                              decoration: const BoxDecoration(
                                color: _kBg,
                                border: Border(
                                  top: BorderSide(color: _kDivider),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedFormat =
                                                _selectedLanguage =
                                                    _selectedGenre =
                                                        _selectedPlace =
                                                            _selectedStatus =
                                                                _selectedTitle =
                                                                    _selectedIsbnAsin =
                                                                        _selectedAuthor =
                                                                            _selectedEditorial =
                                                                                _selectedSaga =
                                                                                    _selectedSagaUniverse =
                                                                                        _selectedFormatSaga =
                                                                                            _selectedPagesEmpty =
                                                                                                _selectedIsBundle =
                                                                                                    _selectedIsTandem =
                                                                                                        _selectedSagaFormatWithoutSaga =
                                                                                                            _selectedSagaFormatWithoutNSaga =
                                                                                                                _selectedSagaWithoutFormatSaga =
                                                                                                                    _selectedPublicationYearEmpty =
                                                                                                                        _selectedRating =
                                                                                                                            _selectedPrice = null;
                                          });
                                          provider.clearAllFilters();
                                          setModalState(() {});
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF837378),
                                          ),
                                          shape: const StadiumBorder(),
                                          foregroundColor: _kPrimary,
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.26,
                                          ),
                                        ),
                                        child: Text(l10n.clear),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: SizedBox(
                                      height: 44,
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _kPrimary,
                                          foregroundColor: Colors.white,
                                          shape: const StadiumBorder(),
                                          elevation: 3,
                                          shadowColor: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.26,
                                          ),
                                        ),
                                        child: Text(l10n.apply),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);
    if (provider == null || provider.isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final searchLabels = [
      l10n.search_by_title,
      l10n.search_by_isbn,
      l10n.search_by_author,
      l10n.saga,
    ];

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Search section ─────────────────────────────────────────────────
          Container(
            color: _kBg,
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
            child: Column(
              children: [
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: searchLabels.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final sel = i == _selectedSearchButtonIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedSearchButtonIndex = i);
                          provider.searchBooks(
                            _searchController.text.trim(),
                            searchIndex: i,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? _kPrimary : Colors.white,
                            border: Border.all(
                              color: sel ? _kPrimary : _kBorder,
                            ),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            searchLabels[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : _kInactiveText,
                              letterSpacing: 0.26,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF27231E)),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search, color: _kText, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged:
                                (v) => provider.searchBooks(
                                  v.trim(),
                                  searchIndex: _selectedSearchButtonIndex,
                                ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: l10n.search_hint,
                              hintStyle: const TextStyle(
                                color: _kText,
                                fontSize: 14,
                              ),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF27231E),
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: const Icon(
                            Icons.close,
                            size: 14,
                            color: _kText,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            provider.searchBooks(
                              '',
                              searchIndex: _selectedSearchButtonIndex,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Book list ───────────────────────────────────────────────────────
          Expanded(
            child: Consumer<BookProvider>(
              builder: (ctx, p, _) {
                if (p.books.isEmpty) {
                  return Center(child: Text(l10n.no_books_found));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                  itemCount: p.books.length,
                  itemBuilder:
                      (ctx, i) => _NewBookCard(
                        book: p.books[i],
                        enabledCardFields: _enabledCardFields,
                      ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: FloatingActionButton(
              heroTag: 'new_filters',
              onPressed: () => _showFilterSortSheet(context, provider),
              backgroundColor: _kFabSmall,
              elevation: 3,
              shape: const CircleBorder(),
              child: const Icon(Icons.tune, color: _kInactiveText, size: 17),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'new_add_book',
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddBookScreen()),
                ),
            backgroundColor: _kPrimary,
            elevation: 6,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ── New book card ──────────────────────────────────────────────────────────────

class _NewBookCard extends StatelessWidget {
  final Book book;
  final Set<String> enabledCardFields;
  const _NewBookCard({required this.book, required this.enabledCardFields});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRead =
        book.statusValue?.toLowerCase() == 'yes' ||
        book.statusValue?.toLowerCase() == 'repeated';

    final meta = <_MetaItem>[];
    if (enabledCardFields.contains('saga') &&
        book.saga != null &&
        book.saga!.isNotEmpty) {
      final label =
          '${book.saga}${book.nSaga != null && book.nSaga!.isNotEmpty ? " #${book.nSaga}" : ""}';
      meta.add(_MetaItem(icon: Icons.auto_stories_outlined, text: label));
    }
    if (enabledCardFields.contains('format') &&
        book.formatValue != null &&
        book.formatValue!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.import_contacts_outlined,
          text: book.formatValue!.toUpperCase(),
        ),
      );
    }
    if (enabledCardFields.contains('language') &&
        book.languageValue != null &&
        book.languageValue!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.translate_outlined,
          text: book.languageValue!.toUpperCase(),
        ),
      );
    }
    if (enabledCardFields.contains('pages') && book.pages != null) {
      meta.add(
        _MetaItem(
          icon: Icons.menu_book_outlined,
          text: l10n.pages_field_label('${book.pages}').toUpperCase(),
        ),
      );
    }
    if (enabledCardFields.contains('genre') &&
        book.genre != null &&
        book.genre!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.category_outlined,
          text: book.genre!.toUpperCase(),
        ),
      );
    }
    if (enabledCardFields.contains('editorial') &&
        book.editorialValue != null &&
        book.editorialValue!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.apartment_outlined,
          text: book.editorialValue!.toUpperCase(),
        ),
      );
    }
    if (enabledCardFields.contains('isbn') &&
        (book.isbn != null || book.asin != null)) {
      meta.add(_MetaItem(icon: Icons.tag, text: (book.isbn ?? book.asin)!));
    }
    if (enabledCardFields.contains('publication_year') &&
        book.originalPublicationYear != null) {
      meta.add(
        _MetaItem(
          icon: Icons.calendar_today_outlined,
          text: '${book.originalPublicationYear}',
        ),
      );
    }
    if (enabledCardFields.contains('publication_date') &&
        book.notificationDatetime != null &&
        book.notificationDatetime!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.notifications_none_outlined,
          text: book.notificationDatetime!.split('T')[0],
        ),
      );
    }
    if (enabledCardFields.contains('rating') && book.myRating != null) {
      meta.add(_MetaItem(icon: Icons.star_outline, text: '${book.myRating}/5'));
    }
    if (enabledCardFields.contains('read_count') &&
        book.readCount != null &&
        book.readCount! > 0) {
      meta.add(
        _MetaItem(icon: Icons.repeat_outlined, text: 'x${book.readCount}'),
      );
    }
    if (enabledCardFields.contains('status') &&
        book.statusValue != null &&
        book.statusValue!.isNotEmpty) {
      meta.add(
        _MetaItem(
          icon: Icons.info_outline,
          text:
              StatusHelper.getLocalizedLabel(
                book.statusValue!,
                l10n,
              ).toUpperCase(),
        ),
      );
    }
    if (enabledCardFields.contains('progress') &&
        book.readingProgress != null &&
        book.readingProgress! > 0 &&
        (book.statusValue?.toLowerCase() == 'started' ||
            book.statusValue?.toLowerCase() == 'standby')) {
      final pct =
          book.progressType == 'pages' && book.pages != null && book.pages! > 0
              ? '${(book.readingProgress! * 100 / book.pages!).round()}%'
              : '${book.readingProgress}%';
      meta.add(_MetaItem(icon: Icons.trending_up, text: pct));
    }

    final bool hasProgress =
        (book.statusValue?.toLowerCase() == 'started' ||
            book.statusValue?.toLowerCase() == 'standby') &&
        book.readingProgress != null &&
        book.readingProgress! > 0;

    double progressFraction = 0;
    if (hasProgress) {
      progressFraction =
          book.progressType == 'pages' && book.pages != null && book.pages! > 0
              ? (book.readingProgress! / book.pages!).clamp(0.0, 1.0)
              : (book.readingProgress! / 100.0).clamp(0.0, 1.0);
    }

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isRead ? const Color(0xFFF5F3F2) : Colors.white,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 15, 17, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + icons row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          book.name ?? '',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (book.tbr == true)
                        const Icon(
                          Icons.bookmark_add,
                          size: 16,
                          color: _kPrimary,
                        ),
                      if (book.isBundle == true)
                        const Icon(
                          Icons.library_books,
                          size: 16,
                          color: _kPrimary,
                        ),
                      if (book.isTandem == true)
                        const Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: _kPrimary,
                        ),
                    ],
                  ),

                  // Author
                  if (enabledCardFields.contains('author') &&
                      book.author != null &&
                      book.author!.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      book.author!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kText,
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, thickness: 1, color: _kDivider),
                  ],

                  // Metadata grid
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children:
                          meta
                              .map(
                                (m) => SizedBox(
                                  width:
                                      (MediaQuery.of(context).size.width -
                                          40 -
                                          34 -
                                          8) /
                                      2,
                                  child: Row(
                                    children: [
                                      Icon(m.icon, size: 12, color: _kText),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          m.text,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _kText,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Progress bar
            if (hasProgress) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  backgroundColor: _kDivider,
                  valueColor: const AlwaysStoppedAnimation(_kPrimary),
                  minHeight: 4,
                ),
              ),
            ] else
              const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}

class _MetaItem {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});
}
