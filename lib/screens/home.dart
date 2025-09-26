import 'package:flutter/material.dart';
import 'package:mylibrary/model/book.dart';
import 'package:mylibrary/repository/bookRepository.dart';
import 'package:mylibrary/widgets/booklist.dart';
import 'dart:async';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _databaseTotalLength = 0;
  List<Book> _books = [];
  late final repo;

  @override
  void initState() {
    super.initState();
    getDatabase();
    databaseDataCount();
  }

  Future<void> getDatabase() async {
    final db = await _getDatabase();
    repo = BookRepository(db);
  }

  Future<void> databaseDataCount() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('select count(*) as count from book;');
    //print(result);
    final count = result.first['count'] as int;

    setState(() {
      _databaseTotalLength = count;
    });
  }

  Future<void> _search(String textInput) async {
    final books = await repo.searchBooks(textInput.trim());

    setState(() {
      _books = books;
    });
  }

  /*void addBook() {
    setState(() {
      
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Row(
            spacing: 50,
            children: <Widget>[
              SizedBox(
                child: const Center(
                  child: Text(
                    'The database contains the \nfollowing number of books:',
                  ),
                ),
              ),
              SizedBox(
                child: Center(
                  child: Text(
                    '$_databaseTotalLength',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            child: Padding(
              padding: const EdgeInsets.only(top: 25, bottom: 25),
              child: Center(child: SearchTextField(onSearch: _search)),
            ),
          ),
          _books.isNotEmpty
              ? Expanded(child: BookListView(books: _books))
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class SearchTextField extends StatelessWidget {
  final Function(String) onSearch;
  final _authorController = TextEditingController();

  SearchTextField({super.key, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _authorController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: _authorController.clear,
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
