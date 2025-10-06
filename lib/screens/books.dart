import 'package:flutter/material.dart';
import 'package:mylibrary/providers/book_provider.dart';
import 'package:mylibrary/widgets/booklist.dart';
import 'package:provider/provider.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Column(
      children: <Widget>[
        provider.books.isNotEmpty
            ? Expanded(child: BookListView(books: provider.books))
            : const SizedBox.shrink(),
      ],
    );
  }
}
