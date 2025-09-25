import 'package:flutter/material.dart';
import 'package:mylibrary/widgets/booklist.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

Future<Database> _getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'my_library.db'),
    version: 1,
  );
  return db;
}

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<String> _books = [];

  @override
  void initState() {
    super.initState();
    getBooks();
  }

  Future<void> getBooks() async {
    final db = await _getDatabase();
    final result = await db.rawQuery(
      'select * from book b where b.name <> "" order by b.name;',
    );

    final List<String> booksNames =
        result.map((row) => row['name'] as String).toList();

    setState(() {
      _books = booksNames;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _books.isNotEmpty
            ? Expanded(child: BookListView(books: _books))
            : const SizedBox.shrink(),
      ],
    );
  }
}
