import 'dart:async';

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
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final books = provider.books;

    return Scaffold(
      body: Column(
        children: <Widget>[
          SearchButtonsWidget(
            titles: const ['Title', 'ISBN', 'Auth@r'],
            onSelectionChanged: (index) {
              setState(() {
                _selectedSearchButtonIndex = index;
              });
            },
          ),
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.only(top: 25, bottom: 25),
              child: Center(
                child: SearchTextField(
                  controller: _searchController,
                  onSearch: (text) async {
                    await provider.searchBooks(
                      text.trim(),
                      searchIndex: _selectedSearchButtonIndex,
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child:
                provider.books.isNotEmpty
                    ? BookListView(books: provider.books)
                    : const Center(child: Text('No books found')),
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
  Timer? _debounce;

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: () {
            widget.controller.clear();
            widget.onSearch('');
          },
          icon: const Icon(Icons.clear),
        ),
        labelText: 'Search',
        hintText: 'Search',
        border: const OutlineInputBorder(),
      ),
      onChanged: _onChanged,
    );
  }
}

class SearchButtonsWidget extends StatefulWidget {
  final List<String> titles;
  final ValueChanged<int> onSelectionChanged;
  const SearchButtonsWidget({
    super.key,
    required this.titles,
    required this.onSelectionChanged,
  });

  @override
  State<SearchButtonsWidget> createState() => _SearchButtonsWidgetState();
}

class _SearchButtonsWidgetState extends State<SearchButtonsWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.titles.length, (index) {
        final isSelected = _selectedIndex == index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                side: BorderSide(
                  color: Colors.deepPurpleAccent,
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                _selectedIndex = index;
              });
              widget.onSelectionChanged(index);
            },
            child: Text(widget.titles[index]),
          ),
        );
      }),
    );
  }
}
