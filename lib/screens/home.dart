import 'package:flutter/material.dart';
import 'package:mylibrary/providers/book_provider.dart';
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
