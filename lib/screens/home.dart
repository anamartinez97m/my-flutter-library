import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/widgets/booklist.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  String? _selectedFormat;
  String? _selectedLanguage;
  String? _selectedGenre;
  String? _selectedPlace;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();

    // Sync filter and sort state with provider after the first frame
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

          // Restore sort state from provider
          _sortBy = provider.currentSortBy;
          _ascending = provider.currentSortAscending;
        });
      }
    });
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

      setState(() {
        _formatList = format;
        _languageList = language;
        _genreList = genre;
        _placeList = place;
        _statusList = status;
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
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 50,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort & Filter',
                          style: Theme.of(context).textTheme.titleMedium,
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
                                  AppLocalizations.of(context)!.date_created,
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
                        const SizedBox(height: 12),
                        // Format filter
                        DropdownButtonFormField<String>(
                          value: _selectedFormat,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.format,
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
                              child: Text(AppLocalizations.of(context)!.any),
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
                        const SizedBox(height: 12),
                        // Language filter
                        DropdownButtonFormField<String>(
                          value: _selectedLanguage,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.language,
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
                              child: Text(AppLocalizations.of(context)!.any),
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
                        const SizedBox(height: 12),
                        // Genre filter
                        DropdownButtonFormField<String>(
                          value: _selectedGenre,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.genre,
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
                              child: Text(AppLocalizations.of(context)!.any),
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
                        const SizedBox(height: 12),
                        // Place filter
                        DropdownButtonFormField<String>(
                          value: _selectedPlace,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.place,
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
                              child: Text(AppLocalizations.of(context)!.any),
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
                        const SizedBox(height: 12),
                        // Status filter
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.status,
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
                              child: Text(AppLocalizations.of(context)!.any),
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
                        const SizedBox(height: 16),
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
                                  });
                                  provider.filterBooks('all', null);
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
                        const SizedBox(height: 8),
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
            padding: const EdgeInsets.only(top: 16, bottom: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFilterSortSheet(context, provider),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.tune, color: Colors.white),
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
