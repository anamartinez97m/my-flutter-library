import 'package:sqflite/sqflite.dart';
import 'package:myrandomlibrary/model/reading_club.dart';

class ReadingClubRepository {
  final Database db;

  ReadingClubRepository(this.db);

  // Add a new reading club entry
  Future<int> addReadingClub(ReadingClub club) async {
    return await db.insert('reading_clubs', {
      'book_id': club.bookId,
      'club_name': club.clubName,
      'target_date': club.targetDate,
      'reading_progress': club.readingProgress,
    });
  }

  // Update an existing reading club entry
  Future<int> updateReadingClub(ReadingClub club) async {
    return await db.update(
      'reading_clubs',
      {
        'club_name': club.clubName,
        'target_date': club.targetDate,
        'reading_progress': club.readingProgress,
      },
      where: 'club_id = ?',
      whereArgs: [club.clubId],
    );
  }

  // Delete a reading club entry
  Future<int> deleteReadingClub(int clubId) async {
    return await db.delete(
      'reading_clubs',
      where: 'club_id = ?',
      whereArgs: [clubId],
    );
  }

  // Get all reading clubs for a specific book
  Future<List<ReadingClub>> getClubsForBook(int bookId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_clubs',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'target_date ASC, club_name ASC',
    );

    return List.generate(maps.length, (i) {
      return ReadingClub.fromMap(maps[i]);
    });
  }

  // Get all books in a specific club with book details
  Future<List<Map<String, dynamic>>> getBooksInClub(String clubName) async {
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        rc.*,
        b.name as book_name,
        s.value as statusValue,
        b.pages,
        (SELECT GROUP_CONCAT(a.name, ', ')
         FROM books_by_author ba
         INNER JOIN author a ON ba.author_id = a.author_id
         WHERE ba.book_id = b.book_id) as author
      FROM reading_clubs rc
      INNER JOIN book b ON rc.book_id = b.book_id
      LEFT JOIN status s ON b.status_id = s.status_id
      WHERE rc.club_name = ?
      ORDER BY rc.target_date ASC, b.name ASC
    ''', [clubName]);

    return result;
  }

  // Get all unique club names
  Future<List<String>> getAllClubNames() async {
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT DISTINCT club_name
      FROM reading_clubs
      ORDER BY club_name ASC
    ''');

    return result.map((row) => row['club_name'] as String).toList();
  }

  // Get all reading clubs with book details
  Future<List<Map<String, dynamic>>> getAllClubsWithBooks() async {
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        rc.*,
        b.name as book_name,
        s.value as statusValue,
        b.pages,
        (SELECT GROUP_CONCAT(a.name, ', ')
         FROM books_by_author ba
         INNER JOIN author a ON ba.author_id = a.author_id
         WHERE ba.book_id = b.book_id) as author
      FROM reading_clubs rc
      INNER JOIN book b ON rc.book_id = b.book_id
      LEFT JOIN status s ON b.status_id = s.status_id
      ORDER BY rc.club_name ASC, rc.target_date ASC, b.name ASC
    ''');

    return result;
  }

  // Get club statistics
  Future<Map<String, dynamic>> getClubStatistics(String clubName) async {
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_books,
        AVG(rc.reading_progress) as avg_progress,
        SUM(CASE WHEN rc.reading_progress >= 100 THEN 1 ELSE 0 END) as completed_books
      FROM reading_clubs rc
      WHERE rc.club_name = ?
    ''', [clubName]);

    if (result.isNotEmpty) {
      return result.first;
    }
    return {'total_books': 0, 'avg_progress': 0.0, 'completed_books': 0};
  }

  // Check if a book is already in a specific club
  Future<bool> isBookInClub(int bookId, String clubName) async {
    final List<Map<String, dynamic>> result = await db.query(
      'reading_clubs',
      where: 'book_id = ? AND club_name = ?',
      whereArgs: [bookId, clubName],
    );

    return result.isNotEmpty;
  }
}
