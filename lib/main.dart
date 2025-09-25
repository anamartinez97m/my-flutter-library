import 'package:flutter/material.dart';
import 'package:mylibrary/screens/navigation.dart';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
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
      home: const NavigationScreen(),
    );
  }
}
