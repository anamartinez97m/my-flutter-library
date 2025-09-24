import 'package:flutter/material.dart';

import 'dart:async';
// import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

Future<void> copyDatabaseFromAssets() async {
  final dbPath = await sql.getDatabasesPath();
  final pathToDb = path.join(dbPath, 'my_library.db');

  //print('📂 Ruta donde debe estar la DB: $pathToDb');

  final exists = await File(pathToDb).exists();
  //print('exists: $exists');
  if (!exists) {
    final data = await rootBundle.load('assets/my_library.db');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File(pathToDb).writeAsBytes(bytes, flush: true);
  }
}

Future<Database> _getDatabase() async {
  final dbPath = await sql.getDatabasesPath();
  final db = await sql.openDatabase(
    path.join(dbPath, 'my_library.db'),
    version: 1,
  );
  return db;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await copyDatabaseFromAssets();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Library',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'My Library'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _databaseTotalLength = 0;
  List<String> _booksByAuthor = [];

  @override
  void initState() {
    super.initState();
    databaseData();
  }

  Future<void> databaseData() async {
    final db = await _getDatabase();
    final result = await db.rawQuery('select count(*) as count from book;');
    //print(result);
    final count = result.first['count'] as int;

    setState(() {
      _databaseTotalLength = count;
    });
  }

  Future<void> _searchAuthor(String textInput) async {
    String input = textInput.trim();
    final db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      select b.name from book b 
      left join books_by_author bba on b.book_id = bba.book_id 
      left join author a on bba.author_id = a.author_id 
      where lower(a.name) like ?
      order by b.name
      ''',
      ['%${input.toLowerCase()}%'],
    );
    print(result);
    final List<String> booksNames =
        result.map((row) => row['name'] as String).toList();

    setState(() {
      _booksByAuthor = booksNames;
    });
  }

  /*void addBook() {
    setState(() {
      
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
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
                  child: Center(
                    child: AuthorTextField(onSearch: _searchAuthor),
                  ),
                ),
              ),
              _booksByAuthor.isNotEmpty
                  ? Expanded(
                    child: AuthorListView(booksByAuthor: _booksByAuthor),
                  )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
      /*floatingActionButton: FloatingActionButton(
        onPressed: addBook,
        elevation: 3,
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),*/
    );
  }
}

class AuthorTextField extends StatelessWidget {
  final Function(String) onSearch;
  final _authorController = TextEditingController();

  AuthorTextField({super.key, required this.onSearch});

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
        labelText: 'Search auth@r',
        hintText: 'Enter auth@r',
        border: const OutlineInputBorder(),
      ),
      onSubmitted: onSearch,
    );
  }
}

class AuthorListView extends StatelessWidget {
  final List<String> booksByAuthor;

  const AuthorListView({super.key, required this.booksByAuthor});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: booksByAuthor.length,
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(
          height: 30,
          child: Center(child: Text(booksByAuthor[index])),
        );
      },
    );
  }
}
