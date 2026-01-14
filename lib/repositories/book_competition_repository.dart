import 'dart:async';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:sqflite/sqflite.dart';

class BookCompetitionRepository {
  final Database _database;

  BookCompetitionRepository(this._database);

  // Get all books read in a specific month and year
  // This includes books that were started, in progress, or finished in that month
  Future<List<Book>> getBooksReadInMonth(int year, int month) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final List<Map<String, dynamic>> maps = await _database.rawQuery(
      '''
      SELECT DISTINCT b.* FROM book b
      INNER JOIN book_read_dates brd ON b.book_id = brd.book_id
      WHERE b.read_count > 0
      AND (
        -- Book finished in this month
        (brd.date_finished >= ? AND brd.date_finished <= ?)
        -- OR book was started in this month (date_started)
        OR (brd.date_started >= ? AND brd.date_started <= ?)
      )
      ORDER BY b.my_rating DESC, b.name ASC
    ''',
      [startDate, endDate, startDate, endDate],
    );

    return List.generate(maps.length, (i) {
      return Book.fromMap(maps[i]);
    });
  }

  // Get competition results for a specific year
  Future<CompetitionResult?> getCompetitionResults(int year) async {
    print('Repository: Getting competition results for year $year');

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
    final finalMaps = await _database.query(
      'book_competition',
      where: 'year = ? AND competition_type = ?',
      whereArgs: [year, 'final'],
      orderBy: 'competition_id DESC',
      limit: 1,
    );

    final yearlyWinner =
        finalMaps.isNotEmpty ? BookCompetition.fromMap(finalMaps.first) : null;

    return CompetitionResult(
      year: year,
      monthlyWinners: monthlyWinners,
      quarterlyWinners: quarterlyWinners,
      semifinalWinners: semifinalWinners,
      yearlyWinner: yearlyWinner,
    );
  }

  // Save a competition result (update if exists, insert if not)
  Future<void> saveCompetitionResult(BookCompetition competition) async {
    print('Repository: Saving competition result: ${competition.toMap()}');
    
    // Check if record already exists
    String whereClause = 'year = ? AND competition_type = ?';
    List<dynamic> whereArgs = [competition.year, competition.competitionType];
    
    if (competition.month != null) {
      whereClause += ' AND month = ?';
      whereArgs.add(competition.month);
    }
    if (competition.quarter != null) {
      whereClause += ' AND quarter = ?';
      whereArgs.add(competition.quarter);
    }
    if (competition.roundNumber != null) {
      whereClause += ' AND round_number = ?';
      whereArgs.add(competition.roundNumber);
    }
    
    final existing = await _database.query(
      'book_competition',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );
    
    if (existing.isNotEmpty) {
      // Update existing record
      final result = await _database.update(
        'book_competition',
        competition.toMap(),
        where: whereClause,
        whereArgs: whereArgs,
      );
      print('Repository: Updated existing record: $result');
    } else {
      // Insert new record
      final result = await _database.insert(
        'book_competition',
        competition.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Repository: Inserted new record: $result');
    }
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
      return existing.isNotEmpty
          ? BookCompetition.fromMap(existing.first)
          : null;
    }

    // Get books read in this month - don't automatically select a winner
    final books = await getBooksReadInMonth(year, month);
    if (books.isEmpty) return null;

    // Return null to indicate user needs to select winner
    return null;
  }

  // Save monthly winner selected by user
  Future<void> saveMonthlyWinner(
    int year,
    int month,
    int bookId,
    String bookName,
  ) async {
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

  // Save quarterly winner selected by user
  Future<void> saveQuarterlyWinner(
    int year,
    int quarter,
    int bookId,
    String bookName,
  ) async {
    print(
      'Repository: Saving quarterly winner - Year: $year, Quarter: $quarter, Book ID: $bookId, Book: $bookName',
    );

    final competition = BookCompetition(
      year: year,
      competitionType: 'quarterly',
      quarter: quarter,
      bookId: bookId,
      bookName: bookName,
      winnerBookId: bookId,
    );

    print('Repository: Competition object created: ${competition.toMap()}');

    await saveCompetitionResult(competition);

    print('Repository: Quarterly winner saved to database');
  }

  // Save semifinal winner selected by user
  Future<void> saveSemifinalWinner(
    int year,
    int roundNumber,
    int bookId,
    String bookName,
  ) async {
    final competition = BookCompetition(
      year: year,
      competitionType: 'semifinal',
      roundNumber: roundNumber,
      bookId: bookId,
      bookName: bookName,
      winnerBookId: bookId,
    );

    await saveCompetitionResult(competition);
  }

  // Save yearly winner selected by user
  Future<void> saveYearlyWinner(int year, int bookId, String bookName) async {
    final competition = BookCompetition(
      year: year,
      competitionType: 'final',
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

    // Don't auto-run quarterly competition - wait for user selection
    return null;
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

    // Don't auto-run semifinal competition - wait for user selection
    return null;
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

    // Don't auto-run final competition - wait for user selection
    return null;
  }

  // Run full competition for a year
  Future<CompetitionResult?> runFullCompetition(int year) async {
    // Run all stages
    await runFinalCompetition(year);

    // Return the complete results
    return await getCompetitionResults(year);
  }

  // Clean up competition data for a specific year (except monthly winners)
  Future<void> cleanupYearData(int year) async {
    print('Repository: Cleaning up competition data for year $year');
    
    final result = await _database.delete(
      'book_competition',
      where: 'year = ? AND competition_type IN (?, ?, ?)',
      whereArgs: [year, 'quarterly', 'semifinal', 'final'],
    );
    
    print('Repository: Deleted $result competition records for year $year');
  }

  // Get all years with competitions
  Future<List<int>> getYearsWithCompetitions() async {
    final maps = await _database.rawQuery('''
      SELECT DISTINCT year FROM book_competition 
      ORDER BY year DESC
    ''');

    return maps.map((map) => map['year'] as int).toList();
  }

  // Get books read per month for a given year
  Future<Map<int, List<Book>>> getBooksReadPerMonth(int year) async {
    final Map<int, List<Book>> booksPerMonth = {};

    for (int month = 1; month <= 12; month++) {
      final books = await getBooksReadInMonth(year, month);
      if (books.isNotEmpty) {
        booksPerMonth[month] = books;
      }
    }

    return booksPerMonth;
  }

  // Get past years winners (excluding current year)
  Future<List<BookCompetition>> getPastYearsWinners(int currentYear) async {
    final maps = await _database.query(
      'book_competition',
      where: 'year < ? AND competition_type = ?',
      whereArgs: [currentYear, 'final'],
      orderBy: 'year DESC',
    );

    return maps.map((map) => BookCompetition.fromMap(map)).toList();
  }
}
