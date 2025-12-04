import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:myrandomlibrary/model/year_challenge.dart';

class YearChallengeRepository {
  final Database db;

  YearChallengeRepository(this.db);

  /// Create a new year challenge
  Future<int> createChallenge(YearChallenge challenge) async {
    try {
      return await db.insert('year_challenges', challenge.toMap());
    } catch (e) {
      debugPrint('year_challenges table does not exist: $e');
      rethrow;
    }
  }

  /// Get challenge for a specific year
  Future<YearChallenge?> getChallengeForYear(int year) async {
    try {
      final results = await db.query(
        'year_challenges',
        where: 'year = ?',
        whereArgs: [year],
      );

      if (results.isEmpty) return null;
      return YearChallenge.fromMap(results.first);
    } catch (e) {
      debugPrint('year_challenges table does not exist: $e');
      return null;
    }
  }

  /// Get all challenges
  Future<List<YearChallenge>> getAllChallenges() async {
    try {
      final results = await db.query(
        'year_challenges',
        orderBy: 'year DESC',
      );

      return results.map((map) => YearChallenge.fromMap(map)).toList();
    } catch (e) {
      debugPrint('year_challenges table does not exist: $e');
      return [];
    }
  }

  /// Update a challenge
  Future<int> updateChallenge(YearChallenge challenge) async {
    try {
      return await db.update(
        'year_challenges',
        challenge.toMap(),
        where: 'challenge_id = ?',
        whereArgs: [challenge.challengeId],
      );
    } catch (e) {
      debugPrint('year_challenges table does not exist: $e');
      return 0;
    }
  }

  /// Delete a challenge
  Future<int> deleteChallenge(int challengeId) async {
    try {
      return await db.delete(
        'year_challenges',
        where: 'challenge_id = ?',
        whereArgs: [challengeId],
      );
    } catch (e) {
      debugPrint('year_challenges table does not exist: $e');
      return 0;
    }
  }

  /// Get challenge progress for a year
  Future<Map<String, dynamic>> getChallengeProgress(int year) async {
    final challenge = await getChallengeForYear(year);
    if (challenge == null) {
      return {
        'hasChallenge': false,
        'targetBooks': 0,
        'targetPages': 0,
        'booksRead': 0,
        'pagesRead': 0,
        'booksProgress': 0.0,
        'pagesProgress': 0.0,
      };
    }

    // Count books read in the year
    final booksResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT COALESCE(orig.book_id, b.book_id)) as count,
             SUM(COALESCE(orig.pages, b.pages, 0)) as total_pages
      FROM book b
      INNER JOIN book_read_dates rd ON b.book_id = rd.book_id
      LEFT JOIN book orig ON b.original_book_id = orig.book_id
      WHERE CAST(substr(rd.date_finished, 1, 4) AS INTEGER) = ?
        AND rd.date_finished IS NOT NULL 
        AND rd.date_finished != ""
    ''', [year]);

    final booksRead = booksResult.first['count'] as int? ?? 0;
    final pagesRead = booksResult.first['total_pages'] as int? ?? 0;

    return {
      'hasChallenge': true,
      'targetBooks': challenge.targetBooks,
      'targetPages': challenge.targetPages ?? 0,
      'booksRead': booksRead,
      'pagesRead': pagesRead,
      'booksProgress': challenge.targetBooks > 0 ? (booksRead / challenge.targetBooks) : 0.0,
      'pagesProgress': (challenge.targetPages != null && challenge.targetPages! > 0) 
          ? (pagesRead / challenge.targetPages!) 
          : 0.0,
    };
  }
}
