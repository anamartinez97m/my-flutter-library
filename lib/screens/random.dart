import 'package:flutter/material.dart';

// Future<Database> _getDatabase() async {
//   final dbPath = await sql.getDatabasesPath();
//   final db = await sql.openDatabase(
//     path.join(dbPath, 'my_library.db'),
//     version: 1,
//   );
//   return db;
// }

class RandomScreen extends StatefulWidget {
  const RandomScreen({super.key});

  @override
  State<RandomScreen> createState() => _RandomScreenState();
}

class _RandomScreenState extends State<RandomScreen> {
  // List<String> _books = [];

  // @override
  // void initState() {
  //   super.initState();
  //   getBooks();
  // }

  // Future<void> getBooks() async {
  //   final db = await _getDatabase();
  //   final result = await db.rawQuery(
  //     'select * from book b where b.name <> "" order by b.name;',
  //   );

  //   final List<String> booksNames =
  //       result.map((row) => row['name'] as String).toList();

  //   setState(() {
  //     _books = booksNames;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Random Screen', style: TextStyle(fontSize: 24)),
    );
  }
}
