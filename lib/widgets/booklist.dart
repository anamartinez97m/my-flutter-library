import 'package:flutter/material.dart';

class BookListView extends StatelessWidget {
  final List<String> books;

  const BookListView({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(height: 40, child: Center(child: Text(books[index])));
      },
    );
  }
}
