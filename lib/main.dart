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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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
    final db = await _getDatabase();
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      select b.name from book b 
      left join books_by_author bba on b.book_id = bba.book_id 
      left join author a on bba.author_id = a.author_id 
      where a.name like ?
      ''',
      ['%$textInput%'],
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(16),
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
                  //AuthorListView(booksByAuthor: _booksByAuthor),
                ),
              ),
            ),
            SizedBox(
              child: Center(
                child:
                    _booksByAuthor.isNotEmpty
                        ? Text('$_booksByAuthor')
                        : const SizedBox.shrink(),
              ),
            ),
          ],
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

/// An example of the outlined text field type.
///
/// A Outlined [TextField] with default settings matching the spec:
/// https://m3.material.io/components/text-fields/specs#68b00bd6-ab40-4b4f-93d9-ed1fbbc5d06e
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
        labelText: 'Auth@r',
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
    if (booksByAuthor.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: booksByAuthor.length,
      itemBuilder: (BuildContext context, int index) {
        return SizedBox(
          height: 50,
          child: Center(child: Text('Entry ${booksByAuthor[index]}')),
        );
      },
    );
  }
}
