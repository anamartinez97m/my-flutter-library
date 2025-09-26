import 'package:flutter/material.dart';
import 'package:mylibrary/model/book.dart';

class BookListView extends StatelessWidget {
  final List<Book> books;

  const BookListView({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(
          height: 40,
          child: Center(
            child: Text(
              '${books[index].name} - ${books[index].formatValue} - ${books[index].languageValue}',
            ),
          ),
        );
      },
    );
  }
}
