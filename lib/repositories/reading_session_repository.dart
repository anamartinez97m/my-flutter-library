import 'package:sqflite/sqflite.dart';
import 'package:myrandomlibrary/model/reading_session.dart';

class ReadingSessionRepository {
  final Database db;

  ReadingSessionRepository(this.db);

  /// Create a new reading session
  Future<int> createSession(ReadingSession session) async {
    return await db.insert('reading_sessions', session.toMap());
  }

  /// Get active reading session for a book
  Future<ReadingSession?> getActiveSession(int bookId) async {
    final results = await db.query(
      'reading_sessions',
      where: 'book_id = ? AND is_active = 1',
      whereArgs: [bookId],
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ReadingSession.fromMap(results.first);
  }

  /// Get all sessions for a book
  Future<List<ReadingSession>> getSessionsForBook(int bookId) async {
    final results = await db.query(
      'reading_sessions',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'start_time DESC',
    );

    return results.map((map) => ReadingSession.fromMap(map)).toList();
  }

  /// Update a reading session
  Future<int> updateSession(ReadingSession session) async {
    return await db.update(
      'reading_sessions',
      session.toMap(),
      where: 'session_id = ?',
      whereArgs: [session.sessionId],
    );
  }

  /// End an active session
  Future<void> endSession(int sessionId, DateTime endTime, int durationSeconds) async {
    await db.update(
      'reading_sessions',
      {
        'end_time': endTime.toIso8601String(),
        'duration_seconds': durationSeconds,
        'is_active': 0,
      },
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Get total reading time for a book (in seconds)
  Future<int> getTotalReadingTime(int bookId) async {
    final result = await db.rawQuery(
      'SELECT SUM(duration_seconds) as total FROM reading_sessions WHERE book_id = ? AND duration_seconds IS NOT NULL',
      [bookId],
    );

    if (result.isEmpty || result.first['total'] == null) return 0;
    return result.first['total'] as int;
  }

  /// Get total reading time for all books (in seconds)
  Future<int> getTotalReadingTimeAllBooks() async {
    final result = await db.rawQuery(
      'SELECT SUM(duration_seconds) as total FROM reading_sessions WHERE duration_seconds IS NOT NULL',
    );

    if (result.isEmpty || result.first['total'] == null) return 0;
    return result.first['total'] as int;
  }

  /// Get reading time statistics by date range
  Future<Map<String, int>> getReadingTimeByDateRange(DateTime start, DateTime end) async {
    final results = await db.rawQuery('''
      SELECT DATE(start_time) as date, SUM(duration_seconds) as total
      FROM reading_sessions
      WHERE start_time >= ? AND start_time <= ? AND duration_seconds IS NOT NULL
      GROUP BY DATE(start_time)
      ORDER BY date
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final Map<String, int> timeByDate = {};
    for (final row in results) {
      timeByDate[row['date'] as String] = row['total'] as int;
    }
    return timeByDate;
  }

  /// Delete a session
  Future<int> deleteSession(int sessionId) async {
    return await db.delete(
      'reading_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Delete all sessions for a book
  Future<int> deleteSessionsForBook(int bookId) async {
    return await db.delete(
      'reading_sessions',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }
}
