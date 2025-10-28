import 'package:flutter/material.dart';
import 'package:mylibrary/db/database_helper.dart';
import 'package:mylibrary/providers/book_provider.dart';
import 'package:mylibrary/repositories/book_repository.dart';
import 'package:mylibrary/widgets/booklist.dart';
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
  
  String? _selectedFormat;
  String? _selectedLanguage;
  String? _selectedGenre;
  String? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      
      final format = await repository.getLookupValues('format');
      final language = await repository.getLookupValues('language');
      final genre = await repository.getLookupValues('genre');
      final place = await repository.getLookupValues('place');
      
      setState(() {
        _formatList = format;
        _languageList = language;
        _genreList = genre;
        _placeList = place;
      });
    } catch (e) {
      debugPrint('Error loading filter options: $e');
    }
  }

  void _showFilterSortSheet(BuildContext context, BookProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Sort & Filter',
                  style: Theme.of(context).textTheme.titleMedium),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.sort),
                title: DropdownButton<String>(
                  value: _sortBy,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'author', child: Text('Author')),
                    DropdownMenuItem(value: 'created_at', child: Text('Date')),
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
                  icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() => _ascending = !_ascending);
                    provider.sortBooks(_sortBy, _ascending);
                    setModalState(() {});
                  },
                ),
              ),
              const Divider(height: 24),
              Text('Filters',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              // Format filter
              DropdownButtonFormField<String>(
                value: _selectedFormat,
                decoration: const InputDecoration(
                  labelText: 'Format',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ..._formatList.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['value'] as String,
                      child: Text(item['value'] as String),
                    );
                  }).toList(),
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
                decoration: const InputDecoration(
                  labelText: 'Language',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ..._languageList.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['name'] as String,
                      child: Text(item['name'] as String),
                    );
                  }).toList(),
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
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ..._genreList.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['name'] as String,
                      child: Text(item['name'] as String),
                    );
                  }).toList(),
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
                decoration: const InputDecoration(
                  labelText: 'Place',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ..._placeList.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['name'] as String,
                      child: Text(item['name'] as String),
                    );
                  }).toList(),
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
                        });
                        provider.filterBooks('all', null);
                        setModalState(() {});
                      },
                      child: const Text('Clear'),
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
                      child: const Text('Apply Filters'),
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
              titles: const ['Title', 'ISBN', 'Auth@r'],
              initialSelectedIndex: _selectedSearchButtonIndex,
              onSelectionChanged: (index) {
                setState(() {
                  _selectedSearchButtonIndex = index;

                  // If there's existing text, re-run the search with the new category.
                  if (_searchController.text.trim().isNotEmpty) {
                    provider.searchBooks(
                      _searchController.text.trim(),
                      searchIndex: _selectedSearchButtonIndex,
                    );
                  } else {
                    // If no text, simply ensure all books are displayed.
                    provider.searchBooks(
                      '',
                      searchIndex: _selectedSearchButtonIndex,
                    );
                  }
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchTextField(
              controller: _searchController,
              onSearch: (String text) async {
                if (text == '') {
                  await provider.loadBooks();
                } else {
                  await provider.searchBooks(
                    _searchController.text.trim(),
                    searchIndex: _selectedSearchButtonIndex,
                  );
                }
              },
            ),
          ),
          Consumer<BookProvider>(
            builder: (context, provider, child) {
              return Expanded(
                child:
                    provider.isLoading == false && provider.books.isNotEmpty
                        ? BookListView(books: provider.books)
                        : const Center(child: Text('No books found')),
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
            prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
            suffixIcon: IconButton(
              onPressed: () {
                widget.controller.clear();
                widget.onSearch('');
              },
              icon: const Icon(Icons.clear),
            ),
            labelText: 'Search',
            hintText: 'Search for books...',
            border: InputBorder.none,
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
