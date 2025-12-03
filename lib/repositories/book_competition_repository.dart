import 'dart:async';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:sqflite/sqflite.dart';

class BookCompetitionRepository {
  final Database _database;

  BookCompetitionRepository(this._database);

  // Get all books read in a specific month and year
  Future<List<Book>> getBooksReadInMonth(int year, int month) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final List<Map<String, dynamic>> maps = await _database.rawQuery(
      '''
      SELECT DISTINCT b.* FROM book b
      INNER JOIN book_read_dates brd ON b.book_id = brd.book_id
      WHERE brd.date_finished >= ? AND brd.date_finished <= ?
      AND b.read_count > 0
      ORDER BY b.my_rating DESC, b.name ASC
    ''',
      [startDate, endDate],
    );

    return List.generate(maps.length, (i) {
      return Book.fromMap(maps[i]);
    });
  }

  // Get competition results for a specific year
  Future<CompetitionResult?> getCompetitionResults(int year) async {
    // Get monthly winners
    final monthlyMaps = await _database.query(
      'book_competition',
      where: 'year = ? AND competition_type = ?',
      whereArgs: [year, 'monthly'],
      orderBy: 'month ASC',
    );

    final monthlyWinners =
        monthlyMaps
            .map(
              (map) => MonthlyWinner(
                month: map['month'] as int,
                winner: BookCompetition.fromMap(map),
              ),
            )
            .toList();

    // Get quarterly winners
    final quarterlyMaps = await _database.query(
      'book_competition',
      where: 'year = ? AND competition_type = ?',
      whereArgs: [year, 'quarterly'],
      orderBy: 'quarter ASC',
    );

    final quarterlyWinners =
        quarterlyMaps
            .map(
              (map) => QuarterlyWinner(
                quarter: map['quarter'] as int,
                winner: BookCompetition.fromMap(map),
              ),
            )
            .toList();

    // Get semifinal winners
    final semifinalMaps = await _database.query(
      'book_competition',
      where: 'year = ? AND competition_type = ?',
      whereArgs: [year, 'semifinal'],
      orderBy: 'round_number ASC',
    );

    final semifinalWinners =
        semifinalMaps
            .map(
              (map) => SemifinalWinner(
                roundNumber: map['round_number'] as int,
                winner: BookCompetition.fromMap(map),
              ),
            )
            .toList();

    // Get yearly winner
    final yearlyMaps = await _database.query(
      'book_competition',
      where: 'year = ? AND competition_type = ?',
      whereArgs: [year, 'final'],
      limit: 1,
    );

    final yearlyWinner =
        yearlyMaps.isNotEmpty
            ? BookCompetition.fromMap(yearlyMaps.first)
            : null;

    return CompetitionResult(
      year: year,
      monthlyWinners: monthlyWinners,
      quarterlyWinners: quarterlyWinners,
      semifinalWinners: semifinalWinners,
      yearlyWinner: yearlyWinner,
    );
  }

  // Save a competition result
  Future<void> saveCompetitionResult(BookCompetition competition) async {
    await _database.insert(
      'book_competition',
      competition.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Check if competition exists for a specific year and type
  Future<bool> competitionExists(
    int year,
    String competitionType, {
    int? month,
    int? quarter,
    int? roundNumber,
  }) async {
    String whereClause = 'year = ? AND competition_type = ?';
    List<dynamic> whereArgs = [year, competitionType];

    if (month != null) {
      whereClause += ' AND month = ?';
      whereArgs.add(month);
    }
    if (quarter != null) {
      whereClause += ' AND quarter = ?';
      whereArgs.add(quarter);
    }
    if (roundNumber != null) {
      whereClause += ' AND round_number = ?';
      whereArgs.add(roundNumber);
    }

    final results = await _database.query(
      'book_competition',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return results.isNotEmpty;
  }

  // Get nominees for a year (books that won at least one monthly competition)
  Future<List<BookCompetition>> getYearNominees(int year) async {
    final maps = await _database.query(
      'book_competition',
      where: 'year = ? AND competition_type = ? AND winner_book_id = book_id',
      whereArgs: [year, 'monthly'],
      orderBy: 'month ASC',
    );

    return maps.map((map) => BookCompetition.fromMap(map)).toList();
  }

  // Run monthly competition for a specific month and year
  Future<BookCompetition?> runMonthlyCompetition(int year, int month) async {
    // Check if already exists
    if (await competitionExists(year, 'monthly', month: month)) {
      final existing = await _database.query(
        'book_competition',
        where: 'year = ? AND competition_type = ? AND month = ?',
        whereArgs: [year, 'monthly', month],
        limit: 1,
      );
      return existing.isNotEmpty ? BookCompetition.fromMap(existing.first) : null;
    }

    // Get books read in this month - don't automatically select a winner
    final books = await getBooksReadInMonth(year, month);
    if (books.isEmpty) return null;

    // Return null to indicate user needs to select winner
    return null;
  }

  // Save monthly winner selected by user
  Future<void> saveMonthlyWinner(int year, int month, int bookId, String bookName) async {
    final competition = BookCompetition(
      year: year,
      competitionType: 'monthly',
      month: month,
      bookId: bookId,
      bookName: bookName,
      winnerBookId: bookId,
    );

    await saveCompetitionResult(competition);
  }

  // Run quarterly competition
  Future<BookCompetition?> runQuarterlyCompetition(
    int year,
    int quarter,
  ) async {
    // Check if already exists
    if (await competitionExists(year, 'quarterly', quarter: quarter)) {
      final existing = await _database.query(
        'book_competition',
        where: 'year = ? AND competition_type = ? AND quarter = ?',
        whereArgs: [year, 'quarterly', quarter],
        limit: 1,
      );
      return existing.isNotEmpty
          ? BookCompetition.fromMap(existing.first)
          : null;
    }

    // Get monthly winners for this quarter
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = quarter * 3;

    final monthlyWinners = <BookCompetition>[];
    for (int month = startMonth; month <= endMonth; month++) {
      final monthlyWinner = await runMonthlyCompetition(year, month);
      if (monthlyWinner != null) {
        monthlyWinners.add(monthlyWinner);
      }
    }

    if (monthlyWinners.length < 2) return null;

    // Competition between monthly winners
    final winner = monthlyWinners.reduce((a, b) {
      // Get book details to compare ratings
      return a.bookName.compareTo(b.bookName) < 0
          ? a
          : b; // Simple alphabetical for now
    });

    final competition = BookCompetition(
      year: year,
      competitionType: 'quarterly',
      quarter: quarter,
      bookId: winner.bookId,
      bookName: winner.bookName,
      winnerBookId: winner.bookId,
    );

    await saveCompetitionResult(competition);
    return competition;
  }

  // Run semifinal competition
  Future<BookCompetition?> runSemifinalCompetition(
    int year,
    int roundNumber,
  ) async {
    // Check if already exists
    if (await competitionExists(year, 'semifinal', roundNumber: roundNumber)) {
      final existing = await _database.query(
        'book_competition',
        where: 'year = ? AND competition_type = ? AND round_number = ?',
        whereArgs: [year, 'semifinal', roundNumber],
        limit: 1,
      );
      return existing.isNotEmpty
          ? BookCompetition.fromMap(existing.first)
          : null;
    }

    // Get quarterly winners
    final quarterlyWinners = <BookCompetition>[];
    for (int quarter = 1; quarter <= 4; quarter++) {
      final quarterlyWinner = await runQuarterlyCompetition(year, quarter);
      if (quarterlyWinner != null) {
        quarterlyWinners.add(quarterlyWinner);
      }
    }

    if (quarterlyWinners.length < 2) return null;

    // Semifinal 1: Q1 vs Q3, Semifinal 2: Q2 vs Q4
    BookCompetition winner;
    if (roundNumber == 1) {
      // Q1 vs Q3
      final q1Winner =
          quarterlyWinners.length >= 1 ? quarterlyWinners[0] : null;
      final q3Winner =
          quarterlyWinners.length >= 3 ? quarterlyWinners[2] : null;
      if (q1Winner == null || q3Winner == null) return null;
      winner =
          q1Winner.bookName.compareTo(q3Winner.bookName) < 0
              ? q1Winner
              : q3Winner;
    } else {
      // Q2 vs Q4
      final q2Winner =
          quarterlyWinners.length >= 2 ? quarterlyWinners[1] : null;
      final q4Winner =
          quarterlyWinners.length >= 4 ? quarterlyWinners[3] : null;
      if (q2Winner == null || q4Winner == null) return null;
      winner =
          q2Winner.bookName.compareTo(q4Winner.bookName) < 0
              ? q2Winner
              : q4Winner;
    }

    final competition = BookCompetition(
      year: year,
      competitionType: 'semifinal',
      roundNumber: roundNumber,
      bookId: winner.bookId,
      bookName: winner.bookName,
      winnerBookId: winner.bookId,
    );

    await saveCompetitionResult(competition);
    return competition;
  }

  // Run final competition
  Future<BookCompetition?> runFinalCompetition(int year) async {
    // Check if already exists
    if (await competitionExists(year, 'final')) {
      final existing = await _database.query(
        'book_competition',
        where: 'year = ? AND competition_type = ?',
        whereArgs: [year, 'final'],
        limit: 1,
      );
      return existing.isNotEmpty
          ? BookCompetition.fromMap(existing.first)
          : null;
    }

    // Get semifinal winners
    final semifinal1 = await runSemifinalCompetition(year, 1);
    final semifinal2 = await runSemifinalCompetition(year, 2);

    if (semifinal1 == null || semifinal2 == null) return null;

    // Final competition
    final winner =
        semifinal1.bookName.compareTo(semifinal2.bookName) < 0
            ? semifinal1
            : semifinal2;

    final competition = BookCompetition(
      year: year,
      competitionType: 'final',
      roundNumber: 3,
      bookId: winner.bookId,
      bookName: winner.bookName,
      winnerBookId: winner.bookId,
    );

    await saveCompetitionResult(competition);
    return competition;
  }

  // Run full competition for a year
  Future<CompetitionResult?> runFullCompetition(int year) async {
    // Run all stages
    await runFinalCompetition(year);

    // Return the complete results
    return await getCompetitionResults(year);
  }

  // Get all years with competitions
  Future<List<int>> getYearsWithCompetitions() async {
    final maps = await _database.rawQuery('''
      SELECT DISTINCT year FROM book_competition 
      ORDER BY year DESC
    ''');

    return maps.map((map) => map['year'] as int).toList();
  }
}
