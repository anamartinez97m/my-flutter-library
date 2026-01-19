import 'package:sqflite/sqflite.dart';
import 'package:myrandomlibrary/model/book_rating_field.dart';

class BookRatingFieldRepository {
  final Database db;

  BookRatingFieldRepository(this.db);

  /// Get all rating fields for a specific book
  Future<List<BookRatingField>> getRatingFieldsForBook(int bookId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'book_rating_fields',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'field_name ASC',
    );
    return List.generate(maps.length, (i) => BookRatingField.fromMap(maps[i]));
  }

  /// Insert a new rating field
  Future<int> insertRatingField(BookRatingField field) async {
    return await db.insert('book_rating_fields', field.toMap());
  }

  /// Update an existing rating field
  Future<void> updateRatingField(BookRatingField field) async {
    await db.update(
      'book_rating_fields',
      field.toMap(),
      where: 'rating_field_id = ?',
      whereArgs: [field.ratingFieldId],
    );
  }

  /// Delete a rating field
  Future<void> deleteRatingField(int ratingFieldId) async {
    await db.delete(
      'book_rating_fields',
      where: 'rating_field_id = ?',
      whereArgs: [ratingFieldId],
    );
  }

  /// Delete all rating fields for a book
  Future<void> deleteAllRatingFieldsForBook(int bookId) async {
    await db.delete(
      'book_rating_fields',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }

  /// Get distinct field names used across all books (for autocomplete)
  Future<List<String>> getDistinctFieldNames() async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT field_name 
      FROM book_rating_fields 
      ORDER BY field_name ASC
    ''');
    return maps.map((map) => map['field_name'] as String).toList();
  }

  /// Calculate average rating for a book from all its rating fields
  Future<double> calculateAverageRating(int bookId) async {
    final fields = await getRatingFieldsForBook(bookId);
    if (fields.isEmpty) return 0.0;
    
    double sum = fields.fold(0.0, (prev, field) => prev + field.ratingValue);
    return sum / fields.length;
  }
}
