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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final books = provider.books;
    final totalCount = books.length;

    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.only(top: 25, bottom: 25),
              child: Center(
                child: SearchTextField(
                  controller: _searchController,
                  onSearch: (text) async {
                    await provider.searchBooks(text.trim());
                  },
                ),
              ),
            ),
          ),
          books.isNotEmpty
              ? Expanded(child: BookListView(books: books))
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class SearchTextField extends StatelessWidget {
  final Function(String) onSearch;
  final TextEditingController controller;

  const SearchTextField({
    super.key,
    required this.onSearch,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: controller.clear,
          icon: const Icon(Icons.clear),
        ),
        labelText: 'Title, ISBN or auth@r',
        hintText: 'Title, ISBN or auth@r',
        border: const OutlineInputBorder(),
      ),
      onSubmitted: onSearch,
    );
  }
}
