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

  /// Get all available rating field names
  Future<List<String>> getAllFieldNames() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'rating_field_names',
      orderBy: 'name ASC',
    );
    return maps.map((map) => map['name'] as String).toList();
  }

  /// Add a new rating field name
  Future<void> addFieldName(String name) async {
    await db.insert('rating_field_names', {'name': name});
  }

  /// Update a rating field name
  Future<void> updateFieldName(String oldName, String newName) async {
    // Update in rating_field_names table
    await db.update(
      'rating_field_names',
      {'name': newName},
      where: 'name = ?',
      whereArgs: [oldName],
    );
    
    // Update in book_rating_fields table
    await db.rawUpdate(
      'UPDATE book_rating_fields SET field_name = ? WHERE field_name = ?',
      [newName, oldName],
    );
  }

  /// Delete a rating field name
  Future<void> deleteFieldName(String name) async {
    // Delete from rating_field_names table
    await db.delete(
      'rating_field_names',
      where: 'name = ?',
      whereArgs: [name],
    );
    
    // Delete all rating fields with this name from books
    await db.delete(
      'book_rating_fields',
      where: 'field_name = ?',
      whereArgs: [name],
    );
  }
}
