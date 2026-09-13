import 'package:sqflite/sqflite.dart';
import 'package:myrandomlibrary/model/tandem_reading.dart';
import 'package:myrandomlibrary/model/tandem_chapter.dart';

class TandemRepository {
  final Database db;

  TandemRepository(this.db);

  // ==================== TandemReading CRUD ====================

  /// Create a new tandem reading
  Future<int> createTandem(TandemReading tandem) async {
    return await db.insert('tandem_readings', {
      'book_a_id': tandem.bookAId,
      'book_b_id': tandem.bookBId,
      'title': tandem.title,
    });
  }

  /// Get a tandem reading by ID
  Future<TandemReading?> getTandemById(int tandemId) async {
    final result = await db.query(
      'tandem_readings',
      where: 'tandem_id = ?',
      whereArgs: [tandemId],
    );

    if (result.isEmpty) return null;
    return TandemReading.fromMap(result.first);
  }

  /// Get all tandem readings
  Future<List<TandemReading>> getAllTandems() async {
    final result = await db.query(
      'tandem_readings',
      orderBy: 'created_at DESC',
    );

    return result.map((row) => TandemReading.fromMap(row)).toList();
  }

  /// Get all tandem readings involving a specific book
  Future<List<TandemReading>> getTandemsForBook(int bookId) async {
    final result = await db.query(
      'tandem_readings',
      where: 'book_a_id = ? OR book_b_id = ?',
      whereArgs: [bookId, bookId],
      orderBy: 'created_at DESC',
    );

    return result.map((row) => TandemReading.fromMap(row)).toList();
  }

  /// Update a tandem reading
  Future<int> updateTandem(TandemReading tandem) async {
    return await db.update(
      'tandem_readings',
      {
        'book_a_id': tandem.bookAId,
        'book_b_id': tandem.bookBId,
        'title': tandem.title,
      },
      where: 'tandem_id = ?',
      whereArgs: [tandem.tandemId],
    );
  }

  /// Delete a tandem reading and its chapters
  Future<int> deleteTandem(int tandemId) async {
    // Delete chapters first (PRAGMA foreign_keys is OFF)
    await db.delete(
      'tandem_chapters',
      where: 'tandem_id = ?',
      whereArgs: [tandemId],
    );

    return await db.delete(
      'tandem_readings',
      where: 'tandem_id = ?',
      whereArgs: [tandemId],
    );
  }

  // ==================== TandemChapter CRUD ====================

  /// Add a chapter entry to a tandem
  Future<int> addChapter(TandemChapter chapter) async {
    return await db.insert('tandem_chapters', {
      'tandem_id': chapter.tandemId,
      'book_id': chapter.bookId,
      'start_chapter': chapter.startChapter,
      'end_chapter': chapter.endChapter,
      'order_index': chapter.orderIndex,
      'is_read': chapter.isRead ? 1 : 0,
    });
  }

  /// Get all chapters for a tandem, ordered by order_index
  Future<List<TandemChapter>> getChaptersForTandem(int tandemId) async {
    final result = await db.query(
      'tandem_chapters',
      where: 'tandem_id = ?',
      whereArgs: [tandemId],
      orderBy: 'order_index ASC',
    );

    return result.map((row) => TandemChapter.fromMap(row)).toList();
  }

  /// Update a chapter entry
  Future<int> updateChapter(TandemChapter chapter) async {
    return await db.update(
      'tandem_chapters',
      {
        'book_id': chapter.bookId,
        'start_chapter': chapter.startChapter,
        'end_chapter': chapter.endChapter,
        'order_index': chapter.orderIndex,
        'is_read': chapter.isRead ? 1 : 0,
      },
      where: 'tandem_chapter_id = ?',
      whereArgs: [chapter.tandemChapterId],
    );
  }

  /// Delete a chapter entry
  Future<int> deleteChapter(int tandemChapterId) async {
    return await db.delete(
      'tandem_chapters',
      where: 'tandem_chapter_id = ?',
      whereArgs: [tandemChapterId],
    );
  }

  /// Toggle the read status of a chapter
  Future<void> toggleChapterRead(int tandemChapterId, bool isRead) async {
    await db.update(
      'tandem_chapters',
      {'is_read': isRead ? 1 : 0},
      where: 'tandem_chapter_id = ?',
      whereArgs: [tandemChapterId],
    );
  }

  /// Reorder chapters within a tandem
  /// [orderedChapterIds] contains the chapter IDs in the desired new order
  Future<void> reorderChapters(int tandemId, List<int> orderedChapterIds) async {
    await db.transaction((txn) async {
      for (int i = 0; i < orderedChapterIds.length; i++) {
        await txn.update(
          'tandem_chapters',
          {'order_index': i},
          where: 'tandem_chapter_id = ? AND tandem_id = ?',
          whereArgs: [orderedChapterIds[i], tandemId],
        );
      }
    });
  }

  // ==================== Progress ====================

  /// Get progress for a tandem reading
  /// Returns { 'completed': X, 'total': Y }
  Future<Map<String, int>> getTandemProgress(int tandemId) async {
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN is_read = 1 THEN 1 ELSE 0 END) as completed
      FROM tandem_chapters
      WHERE tandem_id = ?
    ''', [tandemId]);

    if (result.isEmpty) {
      return {'completed': 0, 'total': 0};
    }

    return {
      'completed': (result.first['completed'] as int?) ?? 0,
      'total': (result.first['total'] as int?) ?? 0,
    };
  }
}
