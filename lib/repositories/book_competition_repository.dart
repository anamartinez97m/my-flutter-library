import 'dart:async';
import 'package:flutter/foundation.dart';
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
      SELECT DISTINCT b.book_id, s.value as statusValue, b.name, e.name as editorialValue,
        b.saga, b.n_saga, b.saga_universe, b.isbn, b.asin, l.name as languageValue,
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year,
        b.pages, b.created_at, b.date_read_initial, b.date_read_final,
        b.read_count,
        (SELECT AVG(brf.rating_value) FROM book_rating_fields brf WHERE brf.book_id = b.book_id AND brf.rating_value > 0) as my_rating,
        b.my_review,
        b.is_bundle, b.bundle_count, b.bundle_numbers, b.bundle_start_dates, b.bundle_end_dates, b.bundle_pages, b.bundle_publication_years, b.bundle_titles, b.bundle_authors,
        b.tbr, b.is_tandem, b.original_book_id,
        b.notification_enabled, b.notification_datetime, b.bundle_parent_id,
        b.reading_progress, b.progress_type,
        b.notes, b.price, b.rating_override,
        b.cover_url, b.description, b.metadata_source, b.metadata_fetched_at,
        GROUP_CONCAT(DISTINCT a.name) as author,
        GROUP_CONCAT(DISTINCT g.name) as genre
      FROM book b
      INNER JOIN book_read_dates brd ON b.book_id = brd.book_id
      LEFT JOIN books_by_author bba ON b.book_id = bba.book_id
      LEFT JOIN author a ON bba.author_id = a.author_id
      LEFT JOIN books_by_genre bbg ON b.book_id = bbg.book_id
      LEFT JOIN genre g ON bbg.genre_id = g.genre_id
      LEFT JOIN status s ON b.status_id = s.status_id
      LEFT JOIN editorial e ON b.editorial_id = e.editorial_id
      LEFT JOIN language l ON b.language_id = l.language_id
      LEFT JOIN place p ON b.place_id = p.place_id
      LEFT JOIN format f ON b.format_id = f.format_id
      LEFT JOIN format_saga fs ON b.format_saga_id = fs.format_id
      WHERE b.read_count > 0
      AND (
        -- Book finished in this month
        (brd.date_finished >= ? AND brd.date_finished <= ?)
        -- OR book was started in this month (date_started)
        OR (brd.date_started >= ? AND brd.date_started <= ?)
      )
      GROUP BY b.book_id
      ORDER BY my_rating DESC, b.name ASC
    ''',
      [startDate, endDate, startDate, endDate],
    );

    return List.generate(maps.length, (i) {
      return Book.fromMap(maps[i]);
    });
  }

  // Get competition results for a specific year
  Future<CompetitionResult?> getCompetitionResults(int year) async {
    debugPrint('Repository: Getting competition results for year $year');

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
    debugPrint('Repository: Saving competition result: ${competition.toMap()}');

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
      debugPrint('Repository: Updated existing record: $result');
    } else {
      // Insert new record
      final result = await _database.insert(
        'book_competition',
        competition.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('Repository: Inserted new record: $result');
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
    debugPrint(
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

    debugPrint(
      'Repository: Competition object created: ${competition.toMap()}',
    );

    await saveCompetitionResult(competition);

    debugPrint('Repository: Quarterly winner saved to database');
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
    debugPrint('Repository: Cleaning up competition data for year $year');

    final result = await _database.delete(
      'book_competition',
      where: 'year = ? AND competition_type IN (?, ?, ?)',
      whereArgs: [year, 'quarterly', 'semifinal', 'final'],
    );

    debugPrint(
      'Repository: Deleted $result competition records for year $year',
    );
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
