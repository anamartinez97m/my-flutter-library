import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  final dbHelper = DatabaseHelper();
  final database = await dbHelper.database;
  
  print('Cleaning competition data for 2025...');
  
  // Delete quarterly, semifinal, and final winners for 2025
  await database.delete(
    'book_competition',
    where: 'year = ? AND competition_type IN (?, ?, ?)',
    whereArgs: [2025, 'quarterly', 'semifinal', 'final'],
  );
  
  print('Deleted quarterly, semifinal, and final winners for 2025');
  
  // Check what remains
  final remaining = await database.query(
    'book_competition',
    where: 'year = ?',
    whereArgs: [2025],
  );
  
  print('Remaining competition records for 2025: ${remaining.length}');
  for (final record in remaining) {
    print('  ${record['competition_type']} - ${record['book_name']}');
  }
  
  await database.close();
  print('Database cleanup completed');
}
