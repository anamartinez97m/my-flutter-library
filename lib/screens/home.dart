import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/add_book.dart';
import 'package:myrandomlibrary/widgets/booklist.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final void Function(VoidCallback)? onRegisterClearSearch;

  const HomeScreen({super.key, this.onRegisterClearSearch});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSearchButtonIndex = 0;
  String _sortBy = 'name';
  bool _ascending = true;

  // Filter dropdowns
  List<Map<String, dynamic>> _formatList = [];
  List<Map<String, dynamic>> _languageList = [];
  List<Map<String, dynamic>> _genreList = [];
  List<Map<String, dynamic>> _placeList = [];
  List<Map<String, dynamic>> _statusList = [];
  List<Map<String, dynamic>> _editorialList = [];
  List<Map<String, dynamic>> _sagaList = [];
  List<Map<String, dynamic>> _sagaUniverseList = [];
  List<Map<String, dynamic>> _formatSagaList = [];

  String? _selectedFormat;
  String? _selectedLanguage;
  String? _selectedGenre;
  String? _selectedPlace;
  String? _selectedStatus;
  String? _selectedTitle;
  String? _selectedIsbnAsin;
  String? _selectedAuthor;
  String? _selectedEditorial;
  String? _selectedSaga;
  String? _selectedSagaUniverse;
  String? _selectedFormatSaga;
  String? _selectedPagesEmpty;
  String? _selectedIsBundle;
  String? _selectedIsTandem;
  String? _selectedSagaFormatWithoutSaga;
  String? _selectedSagaFormatWithoutNSaga;

  Set<String> _enabledFilters = {};

  void clearSearch() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _searchController.clear();
      });
      final provider = Provider.of<BookProvider?>(context, listen: false);
      provider?.searchBooks('', searchIndex: _selectedSearchButtonIndex);
    }
  }

  @override
  void initState() {
    super.initState();
    widget.onRegisterClearSearch?.call(clearSearch);
    _loadEnabledFilters();
    _loadFilterOptions();

    // Restore filter and sort state from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BookProvider?>(context, listen: false);
      if (provider != null) {
        setState(() {
          // Restore filter state from provider
          _selectedFormat = provider.currentFilters['format'];
          _selectedLanguage = provider.currentFilters['language'];
          _selectedGenre = provider.currentFilters['genre'];
          _selectedPlace = provider.currentFilters['place'];
          _selectedStatus = provider.currentFilters['status'];
          _selectedTitle = provider.currentFilters['title'];
          _selectedIsbnAsin = provider.currentFilters['isbn'];
          _selectedAuthor = provider.currentFilters['author'];
          _selectedEditorial = provider.currentFilters['editorial'];
          _selectedSaga = provider.currentFilters['saga'];
          _selectedSagaUniverse = provider.currentFilters['saga_universe'];
          _selectedFormatSaga = provider.currentFilters['format_saga'];
          _selectedPagesEmpty = provider.currentFilters['pages_empty'];
          _selectedIsBundle = provider.currentFilters['is_bundle'];
          _selectedIsTandem = provider.currentFilters['is_tandem'];
          _selectedSagaFormatWithoutSaga =
              provider.currentFilters['saga_format_without_saga'];
          _selectedSagaFormatWithoutNSaga =
              provider.currentFilters['saga_format_without_nsaga'];

          // Restore sort state from provider
          _sortBy = provider.currentSortBy;
          _ascending = provider.currentSortAscending;
        });
      }
    });
  }

  Future<void> _loadEnabledFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFilters = prefs.getStringList('enabled_filters');
    setState(() {
      if (savedFilters != null) {
        _enabledFilters = savedFilters.toSet();
      } else {
        // Default: enable all filters
        _enabledFilters = {
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
        };
      }
    });
  }

  bool _isFilterEnabled(String filterKey) {
    return _enabledFilters.contains(filterKey);
  }

  Future<void> _loadFilterOptions() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

      final format = await repository.getLookupValues('format');
      final language = await repository.getLookupValues('language');
      final genre = await repository.getLookupValues('genre');
      final place = await repository.getLookupValues('place');
      final status = await repository.getLookupValues('status');
      final editorial = await repository.getLookupValues('editorial');
      final formatSaga = await repository.getLookupValues('format_saga');

      // Get distinct sagas and saga universes
      final sagasResult = await db.rawQuery('''
        SELECT DISTINCT saga as name FROM book 
        WHERE saga IS NOT NULL AND saga != '' 
        ORDER BY saga
      ''');
      final sagaUniversesResult = await db.rawQuery('''
        SELECT DISTINCT saga_universe as name FROM book 
        WHERE saga_universe IS NOT NULL AND saga_universe != '' 
        ORDER BY saga_universe
      ''');

      setState(() {
        _formatList = format;
        _languageList = language;
        _genreList = genre;
        _placeList = place;
        _statusList = status;
        _editorialList = editorial;
        _formatSagaList = formatSaga;
        _sagaList = sagasResult;
        _sagaUniverseList = sagaUniversesResult;
      });
    } catch (e) {
      debugPrint('Error loading filter options: $e');
    }
  }

  void _showFilterSortSheet(BuildContext context, BookProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (context, scrollController) => StatefulBuilder(
                  builder:
                      (context, setModalState) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ListView(
                          controller: scrollController,
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context)!.sort_and_filter,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.sort),
                              title: DropdownButton<String>(
                                value: _sortBy,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: [
                                  DropdownMenuItem(
                                    value: 'name',
                                    child: Text(
                                      AppLocalizations.of(context)!.book_name,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'author',
                                    child: Text(
                                      AppLocalizations.of(context)!.author,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'created_at',
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.date_created,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _sortBy = value);
                                    provider.sortBooks(_sortBy, _ascending);
                                    setModalState(() {});
                                  }
                                },
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  _ascending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                ),
                                onPressed: () {
                                  setState(() => _ascending = !_ascending);
                                  provider.sortBooks(_sortBy, _ascending);
                                  setModalState(() {});
                                },
                              ),
                            ),
                            const Divider(height: 24),
                            Text(
                              AppLocalizations.of(context)!.filters,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            // Title filter
                            if (_isFilterEnabled('title')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedTitle,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.book_name,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedTitle = value);
                                  if (value != null) {
                                    provider.filterBooks('title', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // ISBN/ASIN filter
                            if (_isFilterEnabled('isbn')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedIsbnAsin,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.isbn_asin,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedIsbnAsin = value);
                                  if (value != null) {
                                    provider.filterBooks('isbn', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Author filter
                            if (_isFilterEnabled('author')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedAuthor,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.author,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedAuthor = value);
                                  if (value != null) {
                                    provider.filterBooks('author', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Status filter
                            if (_isFilterEnabled('status')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.status,
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  ..._statusList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['value'] as String,
                                      child: Text(item['value'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedStatus = value);
                                  if (value != null) {
                                    provider.filterBooks('status', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Format filter
                            if (_isFilterEnabled('format')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedFormat,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.format,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                  ..._formatList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['value'] as String,
                                      child: Text(item['value'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedFormat = value);
                                  if (value != null) {
                                    provider.filterBooks('format', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Genre filter
                            if (_isFilterEnabled('genre')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedGenre,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.genre,
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                  ..._genreList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['name'] as String,
                                      child: Text(item['name'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedGenre = value);
                                  if (value != null) {
                                    provider.filterBooks('genre', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Language filter
                            if (_isFilterEnabled('language')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedLanguage,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.language,
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                  ..._languageList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['name'] as String,
                                      child: Text(item['name'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedLanguage = value);
                                  if (value != null) {
                                    provider.filterBooks('language', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Place filter
                            if (_isFilterEnabled('place')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedPlace,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.place,
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                  ..._placeList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['name'] as String,
                                      child: Text(item['name'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedPlace = value);
                                  if (value != null) {
                                    provider.filterBooks('place', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Editorial filter
                            if (_isFilterEnabled('editorial')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedEditorial,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.editorial,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                  ..._editorialList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['name'] as String,
                                      child: Text(item['name'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedEditorial = value);
                                  if (value != null) {
                                    provider.filterBooks('editorial', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Saga filter
                            if (_isFilterEnabled('saga')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedSaga,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(context)!.saga,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                  ..._sagaList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['name'] as String,
                                      child: Text(item['name'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedSaga = value);
                                  if (value != null) {
                                    provider.filterBooks('saga', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Saga Universe filter
                            if (_isFilterEnabled('saga_universe')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedSagaUniverse,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(
                                        context,
                                      )!.saga_universe,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                  ..._sagaUniverseList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['name'] as String,
                                      child: Text(item['name'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedSagaUniverse = value);
                                  if (value != null) {
                                    provider.filterBooks(
                                      'saga_universe',
                                      value,
                                    );
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Format Saga filter
                            if (_isFilterEnabled('format_saga')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedFormatSaga,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.format_saga,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                  ..._formatSagaList.map((item) {
                                    return DropdownMenuItem<String>(
                                      value: item['value'] as String,
                                      child: Text(item['value'] as String),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedFormatSaga = value);
                                  if (value != null) {
                                    provider.filterBooks('format_saga', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Pages Empty filter
                            if (_isFilterEnabled('pages_empty')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedPagesEmpty,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.pages,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: '__EMPTY__',
                                    child: Text(
                                      AppLocalizations.of(context)!.empty,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedPagesEmpty = value);
                                  if (value != null) {
                                    provider.filterBooks('pages_empty', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Is Bundle filter
                            if (_isFilterEnabled('is_bundle')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedIsBundle,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.bundle,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'true',
                                    child: Text(
                                      AppLocalizations.of(context)!.yes,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'false',
                                    child: Text(
                                      AppLocalizations.of(context)!.no,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedIsBundle = value);
                                  if (value != null) {
                                    provider.filterBooks('is_bundle', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Is Tandem filter
                            if (_isFilterEnabled('is_tandem')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedIsTandem,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.tandem,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'true',
                                    child: Text(
                                      AppLocalizations.of(context)!.yes,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'false',
                                    child: Text(
                                      AppLocalizations.of(context)!.no,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _selectedIsTandem = value);
                                  if (value != null) {
                                    provider.filterBooks('is_tandem', value);
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Saga Format Without Saga filter
                            if (_isFilterEnabled('saga_format_without_saga')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedSagaFormatWithoutSaga,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(
                                        context,
                                      )!.saga_format_without_saga,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'true',
                                    child: Text(
                                      AppLocalizations.of(context)!.yes,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'false',
                                    child: Text(
                                      AppLocalizations.of(context)!.no,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(
                                    () =>
                                        _selectedSagaFormatWithoutSaga = value,
                                  );
                                  if (value != null) {
                                    provider.filterBooks(
                                      'saga_format_without_saga',
                                      value,
                                    );
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Saga Format Without N_Saga filter
                            if (_isFilterEnabled('saga_format_without_nsaga')) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedSagaFormatWithoutNSaga,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(
                                        context,
                                      )!.saga_format_without_n_saga,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      AppLocalizations.of(context)!.any,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'true',
                                    child: Text(
                                      AppLocalizations.of(context)!.yes,
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'false',
                                    child: Text(
                                      AppLocalizations.of(context)!.no,
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(
                                    () =>
                                        _selectedSagaFormatWithoutNSaga = value,
                                  );
                                  if (value != null) {
                                    provider.filterBooks(
                                      'saga_format_without_nsaga',
                                      value,
                                    );
                                  } else {
                                    provider.filterBooks('all', null);
                                  }
                                  setModalState(() {});
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFormat = null;
                                        _selectedLanguage = null;
                                        _selectedGenre = null;
                                        _selectedPlace = null;
                                        _selectedStatus = null;
                                        _selectedTitle = null;
                                        _selectedIsbnAsin = null;
                                        _selectedAuthor = null;
                                        _selectedEditorial = null;
                                        _selectedSaga = null;
                                        _selectedSagaUniverse = null;
                                        _selectedFormatSaga = null;
                                        _selectedPagesEmpty = null;
                                        _selectedIsBundle = null;
                                        _selectedIsTandem = null;
                                        _selectedSagaFormatWithoutSaga = null;
                                        _selectedSagaFormatWithoutNSaga = null;
                                      });
                                      provider.clearAllFilters();
                                      setModalState(() {});
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)!.clear,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.apply,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BookProvider? provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: SearchButtonsWidget(
              titles: [
                AppLocalizations.of(context)!.search_by_title,
                AppLocalizations.of(context)!.search_by_isbn,
                AppLocalizations.of(context)!.search_by_author,
                AppLocalizations.of(context)!.saga,
              ],
              initialSelectedIndex: _selectedSearchButtonIndex,
              onSelectionChanged: (index) {
                setState(() {
                  _selectedSearchButtonIndex = index;
                  // Re-run the search with the new category
                  // This will maintain filters and sorting
                  provider.searchBooks(
                    _searchController.text.trim(),
                    searchIndex: _selectedSearchButtonIndex,
                  );
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SearchTextField(
              controller: _searchController,
              onSearch: (String text) async {
                await provider.searchBooks(
                  text.trim(),
                  searchIndex: _selectedSearchButtonIndex,
                );
              },
            ),
          ),
          Consumer<BookProvider>(
            builder: (context, provider, child) {
              return Expanded(
                child:
                    provider.isLoading == false && provider.books.isNotEmpty
                        ? BookListView(books: provider.books)
                        : Center(
                          child: Text(
                            AppLocalizations.of(context)!.no_books_found,
                          ),
                        ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'add_book',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddBookScreen()),
              );
            },
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'filters',
            onPressed: () => _showFilterSortSheet(context, provider),
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.tune, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class SearchTextField extends StatefulWidget {
  final Function(String) onSearch;
  final TextEditingController controller;

  const SearchTextField({
    super.key,
    required this.onSearch,
    required this.controller,
  });

  @override
  State<SearchTextField> createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<SearchTextField> {
  void _onChanged(String value) {
    widget.onSearch(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                widget.controller.clear();
                widget.onSearch('');
              },
              icon: const Icon(Icons.clear),
            ),
            labelText: AppLocalizations.of(context)!.search_label,
            hintText: AppLocalizations.of(context)!.search_hint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          onChanged: _onChanged,
        ),
      ),
    );
  }
}

class SearchButtonsWidget extends StatefulWidget {
  final List<String> titles;
  final ValueChanged<int> onSelectionChanged;
  final int initialSelectedIndex;

  const SearchButtonsWidget({
    super.key,
    required this.titles,
    required this.onSelectionChanged,
    this.initialSelectedIndex = 0,
  });

  @override
  State<SearchButtonsWidget> createState() => _SearchButtonsWidgetState();
}

class _SearchButtonsWidgetState extends State<SearchButtonsWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.titles.length, (index) {
        final isSelected = widget.initialSelectedIndex == index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor:
                  isSelected
                      ? Colors.deepPurple.withValues(alpha: (255.0 * 0.1))
                      : null,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                side: BorderSide(
                  color:
                      isSelected ? Colors.deepPurple : Colors.deepPurpleAccent,
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
            onPressed: () {
              widget.onSelectionChanged(index);
            },
            child: Text(
              widget.titles[index],
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}
