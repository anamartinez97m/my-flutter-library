import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/books_by_year.dart';
import 'package:myrandomlibrary/widgets/statistics/total_books_card.dart';
import 'package:myrandomlibrary/widgets/statistics/responsive_stat_grid.dart';
import 'package:myrandomlibrary/widgets/statistics/latest_book_card.dart';
import 'package:myrandomlibrary/widgets/statistics/books_by_decade_card.dart';
import 'package:myrandomlibrary/widgets/statistics/rating_distribution_card.dart';
import 'package:myrandomlibrary/widgets/statistics/page_distribution_card.dart';
import 'package:myrandomlibrary/widgets/statistics/saga_completion_card.dart';
import 'package:myrandomlibrary/widgets/statistics/seasonal_reading_card.dart';
import 'package:myrandomlibrary/widgets/statistics/seasonal_preferences_card.dart';
import 'package:myrandomlibrary/widgets/statistics/monthly_heatmap_card.dart';
import 'package:myrandomlibrary/widgets/statistics/average_rating_card.dart';
import 'package:myrandomlibrary/widgets/statistics/book_extremes_card.dart';
import 'package:myrandomlibrary/widgets/statistics/reading_insights_card.dart';
import 'package:myrandomlibrary/widgets/statistics/reading_time_placeholder_card.dart';
import 'package:myrandomlibrary/widgets/statistics/reading_goals_card.dart';
import 'package:myrandomlibrary/widgets/statistics/book_competition_card.dart';
import 'package:myrandomlibrary/widgets/statistics/past_years_competition_card.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/screens/book_competition_screen.dart';
import 'package:myrandomlibrary/model/reading_session.dart';
import 'package:myrandomlibrary/repositories/reading_session_repository.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _showStatusAsPercentage = false;
  bool _showFormatAsPercentage = true;
  bool _showReadBooksDecade = false;
  bool _showReadBooksGenres = false;
  bool _showReadBooksEditorials = false;
  bool _showReadBooksAuthors = false;
  Map<int, int>? _booksReadPerYear;
  Map<int, int>? _pagesReadPerYear;
  
  // Competition data
  BookCompetition? _yearlyWinner;
  List<BookCompetition> _nominees = [];
  List<BookCompetition> _pastWinners = [];
  bool _isLoadingCompetition = true;
  
  // Reading sessions data for statistics
  Map<int, List<ReadingSession>> _bookSessions = {};
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadYearData();
    _loadCompetitionData();
    _loadReadingSessionsData();
  }

  Future<void> _loadYearData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final yearData = await repository.getBooksAndPagesPerYear();
      if (mounted) {
        setState(() {
          _booksReadPerYear = yearData['books'] as Map<int, int>;
          _pagesReadPerYear = yearData['pages'] as Map<int, int>;
        });
      }
    } catch (e) {
      debugPrint('Error loading year statistics: $e');
    }
  }

  Future<void> _loadCompetitionData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookCompetitionRepository(db);
      final currentYear = DateTime.now().year;
      
      // Try to get existing competition results
      final competitionResult = await repository.getCompetitionResults(currentYear);
      
      if (competitionResult != null) {
        _yearlyWinner = competitionResult.yearlyWinner;
        _nominees = _calculateCurrentNominees(competitionResult);
      } else {
        // No competition data exists for this year yet
        _nominees = [];
      }
      
      // Load past years winners
      _pastWinners = await repository.getPastYearsWinners(currentYear);
      
      if (mounted) {
        setState(() {
          _isLoadingCompetition = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading competition data: $e');
      if (mounted) {
        setState(() {
          _isLoadingCompetition = false;
        });
      }
    }
  }

  Future<void> _loadReadingSessionsData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final sessionRepository = ReadingSessionRepository(db);
      final provider = Provider.of<BookProvider?>(context, listen: false);
      
      if (provider != null && !provider.isLoading) {
        final books = provider.allBooks;
        final Map<int, List<ReadingSession>> bookSessions = {};
        
        for (var book in books) {
          if (book.bookId != null) {
            final sessions = await sessionRepository.getDisplaySessionsForBook(book.bookId!);
            if (sessions.isNotEmpty) {
              bookSessions[book.bookId!] = sessions;
            }
          }
        }
        
        if (mounted) {
          setState(() {
            _bookSessions = bookSessions;
            _isLoadingSessions = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading reading sessions for stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
        });
      }
    }
  }

  List<BookCompetition> _calculateCurrentNominees(CompetitionResult competitionResult) {
    List<BookCompetition> nominees = [];
    
    // If we have a yearly winner, return just that
    if (competitionResult.yearlyWinner != null) {
      return [competitionResult.yearlyWinner!];
    }
    
    // If we have both semifinal winners, return those
    if (competitionResult.semifinalWinners.length == 2) {
      return competitionResult.semifinalWinners.map((s) => s.winner).toList();
    }
    
    // If we have quarterly winners, return those plus any remaining monthly winners
    if (competitionResult.quarterlyWinners.isNotEmpty) {
      // Add quarterly winners
      nominees.addAll(competitionResult.quarterlyWinners.map((q) => q.winner));
      
      // Find months that don't belong to completed quarters
      Set<int> quarterMonths = {};
      for (final quarterWinner in competitionResult.quarterlyWinners) {
        final quarter = quarterWinner.quarter!;
        final startMonth = (quarter - 1) * 3 + 1;
        final endMonth = quarter * 3;
        for (int month = startMonth; month <= endMonth; month++) {
          quarterMonths.add(month);
        }
      }
      
      // Add monthly winners from months not in completed quarters
      for (final monthlyWinner in competitionResult.monthlyWinners) {
        if (!quarterMonths.contains(monthlyWinner.month)) {
          nominees.add(monthlyWinner.winner);
        }
      }
      
      return nominees;
    }
    
    // If we only have monthly winners, return those
    return competitionResult.monthlyWinners.map((m) => m.winner).toList();
  }

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return month >= 1 && month <= 12 ? monthNames[month] : '';
  }

  /// Try to parse date with multiple formats
  DateTime? _tryParseDate(String dateStr, {String? bookName}) {
    if (dateStr.trim().isEmpty) return null;

    final trimmed = dateStr.trim();

    // Try ISO8601 format first (handles YYYY-MM-DD and full timestamps like 2025-11-06T00:00:00.000)
    try {
      return DateTime.parse(trimmed);
    } catch (e) {
      // If ISO8601 fails, try other formats

      // Check if it contains slashes - likely YYYY/MM/DD format
      if (trimmed.contains('/')) {
        try {
          final parts = trimmed.split('/');
          if (parts.length == 3) {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);

            // Validate it's YYYY/MM/DD (year should be > 1900)
            if (year > 1900) {
              return DateTime(year, month, day);
            } else {
              // Try DD/MM/YYYY format
              return DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          }
        } catch (e) {
          if (bookName != null) {
            debugPrint(
              'Error parsing date "$dateStr" for book "$bookName": $e',
            );
          }
          return null;
        }
      }
    }

    if (bookName != null) {
      debugPrint('Could not parse date "$dateStr" for book "$bookName"');
    }
    return null;
  }

  /// Calculate reading velocity using three-case algorithm
  /// Case 1: Has timeRead data -> use sum of timeRead values + didReadToday only days
  /// Case 2: Only didReadToday data -> use didReadToday days only
  /// Case 3: No session data -> use date difference
  double _calculateReadingVelocity(List<Book> books, Map<int, List<ReadingSession>> bookSessions) {
    int totalPages = 0;
    int totalReadingDays = 0;

    for (var book in books) {
      // Only include books that have been read and have page data
      if (book.readCount == null || book.readCount! <= 0 || book.pages == null || book.pages! <= 0) {
        continue;
      }

      final sessions = bookSessions[book.bookId] ?? [];
      final dailyData = _mapSessionsToDailyReadings(sessions);
      
      if (dailyData.hasTimeReadData) {
        // Case 1: Has timeRead data
        totalReadingDays += dailyData.totalReadingDays;
      } else if (dailyData.hasDidReadData) {
        // Case 2: Only didReadToday data
        totalReadingDays += dailyData.totalReadingDays;
      } else {
        // Case 3: No session data, use dates
        if (book.dateReadInitial != null && book.dateReadFinal != null) {
          final startDate = _tryParseDate(book.dateReadInitial!, bookName: book.name);
          final endDate = _tryParseDate(book.dateReadFinal!, bookName: book.name);
          
          if (startDate != null && endDate != null && endDate.isAfter(startDate)) {
            totalReadingDays += endDate.difference(startDate).inDays + 1;
          }
        }
      }
      
      totalPages += book.pages!;
    }

    return (totalReadingDays > 0 && totalPages > 0) ? totalPages.toDouble() / totalReadingDays.toDouble() : 0.0;
  }

  /// Calculate average days to finish a book using three-case algorithm
  /// Case 1: Has timeRead data -> use sum of timeRead values + didReadToday only days
  /// Case 2: Only didReadToday data -> use didReadToday days only
  /// Case 3: No session data -> use date difference
  double _calculateAverageDaysToFinish(List<Book> books, Map<int, List<ReadingSession>> bookSessions) {
    double totalDays = 0.0;
    int booksWithValidData = 0;

    for (var book in books) {
      // Only include books that have been read
      if (book.readCount == null || book.readCount! <= 0) {
        continue;
      }

      final sessions = bookSessions[book.bookId] ?? [];
      final dailyData = _mapSessionsToDailyReadings(sessions);
      
      int readingDays = 0;
      
      if (dailyData.hasTimeReadData) {
        // Case 1: Has timeRead data
        readingDays = dailyData.totalReadingDays;
      } else if (dailyData.hasDidReadData) {
        // Case 2: Only didReadToday data
        readingDays = dailyData.totalReadingDays;
      } else {
        // Case 3: No session data, use dates
        if (book.dateReadInitial != null && book.dateReadFinal != null) {
          final startDate = _tryParseDate(book.dateReadInitial!, bookName: book.name);
          final endDate = _tryParseDate(book.dateReadFinal!, bookName: book.name);
          
          if (startDate != null && endDate != null && endDate.isAfter(startDate)) {
            readingDays = endDate.difference(startDate).inDays + 1;
          }
        }
      }
      
      if (readingDays > 0) {
        totalDays += readingDays;
        booksWithValidData++;
      }
    }

    return booksWithValidData > 0 ? totalDays / booksWithValidData : 0.0;
  }

  /// Get count of books used in average days calculation
  int _getBooksUsedInAverageDaysCalculation(List<Book> books, Map<int, List<ReadingSession>> bookSessions) {
    int count = 0;

    for (var book in books) {
      // Only include books that have been read
      if (book.readCount == null || book.readCount! <= 0) {
        continue;
      }

      final sessions = bookSessions[book.bookId] ?? [];
      final dailyData = _mapSessionsToDailyReadings(sessions);
      
      int readingDays = 0;
      
      if (dailyData.hasTimeReadData) {
        // Case 1: Has timeRead data
        readingDays = dailyData.totalReadingDays;
      } else if (dailyData.hasDidReadData) {
        // Case 2: Only didReadToday data
        readingDays = dailyData.totalReadingDays;
      } else {
        // Case 3: No session data, use dates
        if (book.dateReadInitial != null && book.dateReadFinal != null) {
          final startDate = _tryParseDate(book.dateReadInitial!, bookName: book.name);
          final endDate = _tryParseDate(book.dateReadFinal!, bookName: book.name);
          
          if (startDate != null && endDate != null && endDate.isAfter(startDate)) {
            readingDays = endDate.difference(startDate).inDays + 1;
          }
        }
      }
      
      if (readingDays > 0) {
        count++;
      }
    }

    return count;
  }

  /// Convert reading sessions to daily reading data for algorithm
  _DailyReadingData _mapSessionsToDailyReadings(List<ReadingSession> sessions) {
    final Map<String, List<ReadingSession>> dailySessions = {};
    
    for (var session in sessions) {
      if (session.startTime != null) {
        final dayKey = _getDayKey(session.startTime!);
        dailySessions[dayKey] ??= [];
        dailySessions[dayKey]!.add(session);
      }
    }

    int totalDaysWithTimeRead = 0;
    int totalDaysWithDidReadOnly = 0;
    int totalSecondsRead = 0;
    final Set<String> uniqueReadingDays = {};

    for (var entry in dailySessions.entries) {
      final daySessions = entry.value;
      final dayKey = entry.key;
      
      int dayTimeSeconds = 0;
      bool hasDidRead = false;
      
      for (var session in daySessions) {
        if (session.durationSeconds != null && session.durationSeconds! > 0) {
          dayTimeSeconds += session.durationSeconds!;
        }
        if (session.didRead) {
          hasDidRead = true;
        }
      }
      
      // Apply counting rules
      if (dayTimeSeconds > 0) {
        totalDaysWithTimeRead++;
        totalSecondsRead += dayTimeSeconds;
        uniqueReadingDays.add(dayKey);
      } else if (hasDidRead) {
        totalDaysWithDidReadOnly++;
        uniqueReadingDays.add(dayKey);
      }
    }

    return _DailyReadingData(
      totalDaysWithTimeRead: totalDaysWithTimeRead,
      totalDaysWithDidReadOnly: totalDaysWithDidReadOnly,
      totalSecondsRead: totalSecondsRead,
      totalReadingDays: uniqueReadingDays.length,
      hasTimeReadData: totalSecondsRead > 0,
      hasDidReadData: totalDaysWithDidReadOnly > 0 || 
                     (totalDaysWithTimeRead > 0 && totalDaysWithDidReadOnly >= 0),
    );
  }

  /// Get day key in YYYY-MM-DD format
  String _getDayKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final books = provider.allBooks; // Use all books, not filtered
    final totalCount = books.length;
    final latestBookName = provider.latestBookAdded;

    // Calculate statistics
    final statusCounts = <String, int>{};
    final languageCounts = <String, int>{};
    final formatCounts = <String, int>{};
    final genreCounts = <String, int>{};
    final editorialCounts = <String, int>{};
    final authorCounts = <String, int>{};

    for (var book in books) {
      // Get multiplier for bundle books
      final multiplier =
          (book.isBundle == true &&
                  book.bundleCount != null &&
                  book.bundleCount! > 0)
              ? book.bundleCount!
              : 1;

      // Status
      final status = book.statusValue ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + multiplier;

      // Language
      final language = book.languageValue;
      if (language != null && language.isNotEmpty && language != 'Unknown') {
        languageCounts[language] = (languageCounts[language] ?? 0) + multiplier;
      }

      // Format
      final format = book.formatValue;
      if (format != null && format.isNotEmpty) {
        formatCounts[format] = (formatCounts[format] ?? 0) + multiplier;
      }

      // Genre (filtered by read status)
      final isRead = book.readCount != null && book.readCount! > 0;
      final shouldIncludeGenre = _showReadBooksGenres ? isRead : true;
      if (shouldIncludeGenre) {
        final genre = book.genre;
        if (genre != null && genre.isNotEmpty) {
          genreCounts[genre] = (genreCounts[genre] ?? 0) + multiplier;
        }
      }

      // Editorial (filtered by read status)
      final shouldIncludeEditorial = _showReadBooksEditorials ? isRead : true;
      if (shouldIncludeEditorial) {
        final editorial = book.editorialValue;
        if (editorial != null && editorial.isNotEmpty) {
          editorialCounts[editorial] =
              (editorialCounts[editorial] ?? 0) + multiplier;
        }
      }

      // Author (filtered by read status)
      final shouldIncludeAuthor = _showReadBooksAuthors ? isRead : true;
      if (shouldIncludeAuthor) {
        final author = book.author;
        if (author != null && author.isNotEmpty) {
          authorCounts[author] = (authorCounts[author] ?? 0) + multiplier;
        }
      }
    }

    // Calculate reading velocity using three-case algorithm
    double readingVelocity = _calculateReadingVelocity(books, _bookSessions);
    
    // Calculate average days to finish using three-case algorithm
    double averageDaysToFinish = _calculateAverageDaysToFinish(books, _bookSessions);
    int booksUsedInAverageDays = _getBooksUsedInAverageDaysCalculation(books, _bookSessions);

    // Calculate average books read per year
    double averageBooksPerYear = 0.0;
    int yearsWithBooks = 0;

    if (_booksReadPerYear != null && _booksReadPerYear!.isNotEmpty) {
      final totalBooks = _booksReadPerYear!.values.reduce((a, b) => a + b);
      yearsWithBooks = _booksReadPerYear!.length;
      if (yearsWithBooks > 0) {
        averageBooksPerYear = totalBooks / yearsWithBooks;
      }
    }

    // Sort and get top entries
    final top5Genres =
        (genreCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(5)
            .toList();

    final top10Editorials =
        (editorialCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .toList();

    final top10Authors =
        (authorCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(10)
            .toList();

    // Use cached year data or empty maps
    final booksReadPerYear = _booksReadPerYear ?? {};
    final pagesReadPerYear = _pagesReadPerYear ?? {};

    // Sort years in descending order
    final sortedBooksReadYears =
        booksReadPerYear.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));
    final sortedPagesReadYears =
        pagesReadPerYear.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

    // Calculate books by decade (from original publication year)
    final Map<String, int> booksByDecade = {};

    for (var book in books) {
      // Filter based on toggle: if ON show only read books, if OFF show all books
      final isRead = book.readCount != null && book.readCount! > 0;
      final shouldInclude = _showReadBooksDecade ? isRead : true;

      if (shouldInclude && book.originalPublicationYear != null) {
        int pubYear = book.originalPublicationYear!;

        // Handle full date format (YYYYMMDD)
        if (pubYear > 9999) {
          pubYear = pubYear ~/ 10000; // Extract year from YYYYMMDD
        }

        // Calculate decade (e.g., 1990 -> "1990s")
        final decade = (pubYear ~/ 10) * 10;
        final decadeLabel = '${decade}s';

        // Count books (handle bundles)
        final multiplier =
            (book.isBundle == true &&
                    book.bundleCount != null &&
                    book.bundleCount! > 0)
                ? book.bundleCount!
                : 1;

        booksByDecade[decadeLabel] =
            (booksByDecade[decadeLabel] ?? 0) + multiplier;
      }
    }

    // Sort decades in descending order
    final sortedBooksByDecade =
        booksByDecade.entries.toList()..sort((a, b) {
          // Extract decade number from label (e.g., "1990s" -> 1990)
          final aDecade = int.parse(a.key.replaceAll('s', ''));
          final bDecade = int.parse(b.key.replaceAll('s', ''));
          return bDecade.compareTo(aDecade);
        });

    // #8: Books by Rating Distribution
    final Map<String, int> ratingDistribution = {
      '5.0': 0,
      '4.0-4.9': 0,
      '3.0-3.9': 0,
      '2.0-2.9': 0,
      '1.0-1.9': 0,
      '0.0-0.9': 0,
      'Unrated': 0,
    };
    for (var book in books) {
      if (book.myRating == null || book.myRating == 0) {
        ratingDistribution['Unrated'] =
            (ratingDistribution['Unrated'] ?? 0) + 1;
      } else if (book.myRating! >= 5.0) {
        ratingDistribution['5.0'] = (ratingDistribution['5.0'] ?? 0) + 1;
      } else if (book.myRating! >= 4.0) {
        ratingDistribution['4.0-4.9'] =
            (ratingDistribution['4.0-4.9'] ?? 0) + 1;
      } else if (book.myRating! >= 3.0) {
        ratingDistribution['3.0-3.9'] =
            (ratingDistribution['3.0-3.9'] ?? 0) + 1;
      } else if (book.myRating! >= 2.0) {
        ratingDistribution['2.0-2.9'] =
            (ratingDistribution['2.0-2.9'] ?? 0) + 1;
      } else if (book.myRating! >= 1.0) {
        ratingDistribution['1.0-1.9'] =
            (ratingDistribution['1.0-1.9'] ?? 0) + 1;
      } else {
        ratingDistribution['0.0-0.9'] =
            (ratingDistribution['0.0-0.9'] ?? 0) + 1;
      }
    }

    // #16: Page Count Distribution
    final Map<String, int> pageDistribution = {
      '0-100': 0,
      '101-200': 0,
      '201-300': 0,
      '301-400': 0,
      '401-500': 0,
      '500+': 0,
    };
    for (var book in books) {
      if (book.pages != null && book.pages! > 0) {
        if (book.pages! <= 100) {
          pageDistribution['0-100'] = (pageDistribution['0-100'] ?? 0) + 1;
        } else if (book.pages! <= 200) {
          pageDistribution['101-200'] = (pageDistribution['101-200'] ?? 0) + 1;
        } else if (book.pages! <= 300) {
          pageDistribution['201-300'] = (pageDistribution['201-300'] ?? 0) + 1;
        } else if (book.pages! <= 400) {
          pageDistribution['301-400'] = (pageDistribution['301-400'] ?? 0) + 1;
        } else if (book.pages! <= 500) {
          pageDistribution['401-500'] = (pageDistribution['401-500'] ?? 0) + 1;
        } else {
          pageDistribution['500+'] = (pageDistribution['500+'] ?? 0) + 1;
        }
      }
    }

    // #18: Saga Completion Rate
    final Map<String, Map<String, int>> sagaStats = {};
    for (var book in books) {
      if (book.saga != null && book.saga!.isNotEmpty) {
        if (!sagaStats.containsKey(book.saga!)) {
          sagaStats[book.saga!] = {'total': 0, 'read': 0};
        }
        sagaStats[book.saga!]!['total'] =
            (sagaStats[book.saga!]!['total'] ?? 0) + 1;
        if (book.readCount != null && book.readCount! > 0) {
          sagaStats[book.saga!]!['read'] =
              (sagaStats[book.saga!]!['read'] ?? 0) + 1;
        }
      }
    }
    final completedSagas =
        sagaStats.entries
            .where((e) => e.value['read'] == e.value['total'])
            .length;
    final partialSagas =
        sagaStats.entries
            .where(
              (e) =>
                  e.value['read']! > 0 && e.value['read'] != e.value['total'],
            )
            .length;
    final unstartedSagas =
        sagaStats.entries.where((e) => e.value['read'] == 0).length;

    // #20: Seasonal Reading Patterns
    final Map<String, int> seasonalReading = {
      'Winter': 0,
      'Spring': 0,
      'Summer': 0,
      'Fall': 0,
    };
    final Set<int> yearsWithReading = {};
    for (var book in books) {
      if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
        final endDate = _tryParseDate(book.dateReadFinal!, bookName: book.name);
        if (endDate != null) {
          yearsWithReading.add(endDate.year);
          final month = endDate.month;
          if (month >= 12 || month <= 2) {
            seasonalReading['Winter'] = (seasonalReading['Winter'] ?? 0) + 1;
          } else if (month >= 3 && month <= 5) {
            seasonalReading['Spring'] = (seasonalReading['Spring'] ?? 0) + 1;
          } else if (month >= 6 && month <= 8) {
            seasonalReading['Summer'] = (seasonalReading['Summer'] ?? 0) + 1;
          } else {
            seasonalReading['Fall'] = (seasonalReading['Fall'] ?? 0) + 1;
          }
        }
      }
    }
    final int yearsCount =
        yearsWithReading.isNotEmpty ? yearsWithReading.length : 1;

    // #12: Monthly Reading Heatmap data
    final Map<int, Map<int, int>> monthlyHeatmap = {}; // year -> month -> count
    for (var book in books) {
      // Skip child books of bundles (they're counted via the parent bundle)
      if (book.bundleParentId != null) {
        continue;
      }
      
      if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
        final endDate = _tryParseDate(book.dateReadFinal!, bookName: book.name);
        if (endDate != null) {
          final year = endDate.year;
          final month = endDate.month;
          if (!monthlyHeatmap.containsKey(year)) {
            monthlyHeatmap[year] = {};
          }
          
          // Count individual books in bundles, or 1 for regular books
          int bookCount = 1;
          if (book.isBundle == true && book.bundleCount != null && book.bundleCount! > 0) {
            bookCount = book.bundleCount!;
          }
          
          monthlyHeatmap[year]![month] =
              (monthlyHeatmap[year]![month] ?? 0) + bookCount;
        }
      }
    }

    // NEW STATISTICS

    // Average Rating
    double averageRating = 0.0;
    int ratedBooksCount = 0;
    for (var book in books) {
      if (book.myRating != null && book.myRating! > 0) {
        averageRating += book.myRating!;
        ratedBooksCount++;
      }
    }
    if (ratedBooksCount > 0) {
      averageRating = averageRating / ratedBooksCount;
    }

    // Oldest & Newest Book (by publication year)
    int? oldestYear;
    int? newestYear;
    String? oldestBookName;
    String? newestBookName;
    for (var book in books) {
      if (book.originalPublicationYear != null &&
          book.originalPublicationYear! > 0) {
        int pubYear = book.originalPublicationYear!;

        // Handle full date format (YYYYMMDD) - extract year only
        if (pubYear > 9999) {
          pubYear = pubYear ~/ 10000;
        }

        if (oldestYear == null || pubYear < oldestYear) {
          oldestYear = pubYear;
          oldestBookName = book.name;
        }
        if (newestYear == null || pubYear > newestYear) {
          newestYear = pubYear;
          newestBookName = book.name;
        }
      }
    }

    // Shortest & Longest Book (by pages)
    // Include individual books from bundles
    int? shortestPages;
    int? longestPages;
    String? shortestBookName;
    String? longestBookName;
    for (var book in books) {
      if (book.isBundle == true) {
        // Parse individual book pages from bundle
        if (book.bundlePages != null && book.bundlePages!.isNotEmpty) {
          try {
            final List<dynamic> pagesList = jsonDecode(book.bundlePages!);
            final List<String?>? titles =
                book.bundleTitles != null && book.bundleTitles!.isNotEmpty
                    ? (jsonDecode(book.bundleTitles!) as List<dynamic>)
                        .map((e) => e as String?)
                        .toList()
                    : null;

            for (int i = 0; i < pagesList.length; i++) {
              final pages =
                  pagesList[i] is int
                      ? pagesList[i] as int
                      : int.tryParse(pagesList[i]?.toString() ?? '');

              if (pages != null && pages > 0) {
                final bookTitle =
                    titles != null && i < titles.length && titles[i] != null
                        ? '${book.name} - ${titles[i]}'
                        : '${book.name} (Book ${i + 1})';

                // Shortest book
                if (shortestPages == null || pages < shortestPages) {
                  shortestPages = pages;
                  shortestBookName = bookTitle;
                }
                // Longest book
                if (longestPages == null || pages > longestPages) {
                  longestPages = pages;
                  longestBookName = bookTitle;
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing bundle pages for ${book.name}: $e');
          }
        }
      } else {
        // Regular book
        if (book.pages != null && book.pages! > 0) {
          // Shortest book
          if (shortestPages == null || book.pages! < shortestPages) {
            shortestPages = book.pages;
            shortestBookName = book.name;
          }
          // Longest book
          if (longestPages == null || book.pages! > longestPages) {
            longestPages = book.pages;
            longestBookName = book.name;
          }
        }
      }
    }

    // #31: Reading Streaks
    final List<DateTime> readDates = [];
    for (var book in books) {
      if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
        final endDate = _tryParseDate(book.dateReadFinal!, bookName: book.name);
        if (endDate != null) {
          readDates.add(endDate);
        }
      }
    }
    readDates.sort();

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;
    final today = DateTime.now();

    for (var date in readDates) {
      if (lastDate == null) {
        tempStreak = 1;
      } else {
        final daysDiff = date.difference(lastDate).inDays;
        if (daysDiff <= 1) {
          tempStreak++;
        } else {
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 1;
        }
      }
      lastDate = date;
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;

    // Calculate current streak
    if (lastDate != null) {
      final daysSinceLastRead = today.difference(lastDate).inDays;
      if (daysSinceLastRead <= 1) {
        currentStreak = tempStreak;
      }
    }

    // #32: DNF (Did Not Finish) Rate - Books with "Abandoned" status
    int dnfCount = 0;
    for (var book in books) {
      if (book.statusValue != null &&
          (book.statusValue!.toLowerCase().contains('abandoned') ||
              book.statusValue!.toLowerCase().contains('dnf'))) {
        dnfCount++;
      }
    }
    final dnfRate = totalCount > 0 ? (dnfCount / totalCount) * 100 : 0.0;

    // #33: Re-read Analysis
    int rereadCount = 0;
    final List<Map<String, dynamic>> rereadBooks = [];
    for (var book in books) {
      if (book.readCount != null && book.readCount! > 1) {
        rereadCount++;
        rereadBooks.add({'name': book.name, 'count': book.readCount});
      }
    }
    rereadBooks.sort(
      (a, b) => (b['count'] as int).compareTo(a['count'] as int),
    );
    final mostRereadBook = rereadBooks.isNotEmpty ? rereadBooks.first : null;

    // #34: Reading Time of Day (placeholder for future chronometer feature)
    // Will be implemented when time tracking is added

    // #39: Series vs Standalone
    int seriesBooks = 0;
    int standaloneBooks = 0;
    final Set<String> uniqueSeries = {};
    for (var book in books) {
      if (book.saga != null && book.saga!.isNotEmpty) {
        seriesBooks++;
        uniqueSeries.add(book.saga!);
      } else {
        standaloneBooks++;
      }
    }
    final seriesPercentage =
        totalCount > 0 ? (seriesBooks / totalCount) * 100 : 0.0;
    final seriesCount = uniqueSeries.length;

    // #53: Reading Goals Progress (placeholder for future goals feature)
    // Will be implemented when goal tracking is added

    // #54: Personal Bests
    int mostBooksInMonth = 0;
    String? bestMonth;
    for (var yearData in monthlyHeatmap.entries) {
      for (var monthData in yearData.value.entries) {
        if (monthData.value > mostBooksInMonth) {
          mostBooksInMonth = monthData.value;
          bestMonth = '${_getMonthName(monthData.key)} ${yearData.key}';
        }
      }
    }

    // Fastest book (shortest reading time)
    int? fastestDays;
    String? fastestBookName;
    for (var book in books) {
      if (book.dateReadInitial != null && book.dateReadFinal != null) {
        final startDate = _tryParseDate(
          book.dateReadInitial!,
          bookName: book.name,
        );
        final endDate = _tryParseDate(book.dateReadFinal!, bookName: book.name);
        if (startDate != null && endDate != null) {
          final days = endDate.difference(startDate).inDays + 1;
          if (days > 0 && (fastestDays == null || days < fastestDays)) {
            fastestDays = days;
            fastestBookName = book.name;
          }
        }
      }
    }

    // #55: Milestones
    final milestones = <String, dynamic>{};
    if (totalCount >= 100) milestones['100'] = true;
    if (totalCount >= 500) milestones['500'] = true;
    if (totalCount >= 1000) milestones['1000'] = true;
    final nextMilestoneOwned =
        totalCount < 100
            ? 100
            : totalCount < 500
            ? 500
            : totalCount < 1000
            ? 1000
            : ((totalCount ~/ 1000) + 1) * 1000;
    final booksToMilestoneOwned = nextMilestoneOwned - totalCount;

    // Books read milestone
    final readBooks =
        books.where((b) => b.readCount != null && b.readCount! > 0).length;
    final nextMilestoneRead =
        readBooks < 100
            ? 100
            : readBooks < 500
            ? 500
            : readBooks < 1000
            ? 1000
            : ((readBooks ~/ 1000) + 1) * 1000;
    final booksToMilestoneRead = nextMilestoneRead - readBooks;

    // #65: Binge Reading Patterns (books read in quick succession)
    final List<Map<String, dynamic>> bingeReading = [];
    final sortedReadBooks =
        books
            .where(
              (b) => b.dateReadFinal != null && b.dateReadFinal!.isNotEmpty,
            )
            .toList();

    sortedReadBooks.sort((a, b) {
      final dateA = _tryParseDate(a.dateReadFinal!, bookName: a.name);
      final dateB = _tryParseDate(b.dateReadFinal!, bookName: b.name);
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });

    int bingeCount = 0;
    for (int i = 1; i < sortedReadBooks.length; i++) {
      final prevDate = _tryParseDate(
        sortedReadBooks[i - 1].dateReadFinal!,
        bookName: sortedReadBooks[i - 1].name,
      );
      final currDate = _tryParseDate(
        sortedReadBooks[i].dateReadFinal!,
        bookName: sortedReadBooks[i].name,
      );
      if (prevDate != null && currDate != null) {
        final daysDiff = currDate.difference(prevDate).inDays;
        if (daysDiff <= 14) {
          // Books finished within 14 days
          bingeCount++;
        }
      }
    }
    final bingePercentage =
        sortedReadBooks.length > 1
            ? (bingeCount / (sortedReadBooks.length - 1)) * 100
            : 0.0;

    // #66: Mood Reading (Genre by Season)
    final Map<String, Map<String, int>> genreBySeason = {
      'Winter': {},
      'Spring': {},
      'Summer': {},
      'Fall': {},
    };
    for (var book in books) {
      if (book.dateReadFinal != null &&
          book.genre != null &&
          book.genre!.isNotEmpty) {
        final endDate = _tryParseDate(book.dateReadFinal!, bookName: book.name);
        if (endDate != null) {
          final month = endDate.month;
          String season;
          if (month >= 12 || month <= 2) {
            season = 'Winter';
          } else if (month >= 3 && month <= 5) {
            season = 'Spring';
          } else if (month >= 6 && month <= 8) {
            season = 'Summer';
          } else {
            season = 'Fall';
          }
          genreBySeason[season]![book.genre!] =
              (genreBySeason[season]![book.genre!] ?? 0) + 1;
        }
      }
    }

    // Find most popular genre per season
    final Map<String, String> topGenreBySeason = {};
    for (var season in genreBySeason.keys) {
      if (genreBySeason[season]!.isNotEmpty) {
        final topGenre = genreBySeason[season]!.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        topGenreBySeason[season] = topGenre.key;
      }
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TotalBooksCard(totalCount: totalCount)),
                const SizedBox(width: 8),
                Expanded(child: LatestBookCard(latestBookName: latestBookName)),
              ],
            ),
            const SizedBox(height: 16),
            // Book Competition Card
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookCompetitionScreen(year: DateTime.now().year),
                  ),
                ).then((_) {
                  // Refresh competition data when returning from competition screen
                  _loadCompetitionData();
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: BookCompetitionCard(
                currentYear: DateTime.now().year,
                yearlyWinner: _yearlyWinner,
                nominees: _nominees,
              ),
            ),
            const SizedBox(height: 16),
            // Books Read Per Year
            InkWell(
              onTap: () {
                // Navigate to the first year in the list
                if (sortedBooksReadYears.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BooksByYearScreen(
                            initialYear: sortedBooksReadYears.first.key,
                          ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Books Read Per Year',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (sortedBooksReadYears.isEmpty)
                        Center(
                          child: Text(AppLocalizations.of(context)!.no_data),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  sortedBooksReadYears.map((entry) {
                                    final maxValue = sortedBooksReadYears
                                        .map((e) => e.value)
                                        .reduce((a, b) => a > b ? a : b);
                                    final percentage = (entry.value / maxValue)
                                        .clamp(0.0, 1.0);
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) =>
                                                      BooksByYearScreen(
                                                        initialYear: entry.key,
                                                      ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                            horizontal: 4,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: 60,
                                                child: Text(
                                                  '${entry.key}',
                                                  style:
                                                      Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: LayoutBuilder(
                                                  builder: (
                                                    context,
                                                    constraints,
                                                  ) {
                                                    return Stack(
                                                      children: [
                                                        Container(
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .grey[200],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                        ),
                                                        Container(
                                                          width:
                                                              constraints
                                                                  .maxWidth *
                                                              percentage,
                                                          height: 24,
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                          ),
                                                        ),
                                                        Container(
                                                          height: 24,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                              ),
                                                          alignment:
                                                              Alignment
                                                                  .centerLeft,
                                                          child: Text(
                                                            '${entry.value}',
                                                            style: TextStyle(
                                                              color:
                                                                  percentage >
                                                                          0.15
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black87,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Pages Read Per Year
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Pages Read Per Year',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (sortedPagesReadYears.isEmpty)
                      Center(child: Text(AppLocalizations.of(context)!.no_data))
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                sortedPagesReadYears.map((entry) {
                                  final maxValue = sortedPagesReadYears
                                      .map((e) => e.value)
                                      .reduce((a, b) => a > b ? a : b);
                                  final percentage = (entry.value / maxValue)
                                      .clamp(0.0, 1.0);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            '${entry.key}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              return Stack(
                                                children: [
                                                  Container(
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width:
                                                        constraints.maxWidth *
                                                        percentage,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                  Container(
                                                    height: 24,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      '${entry.value}',
                                                      style: TextStyle(
                                                        color:
                                                            percentage > 0.15
                                                                ? Colors.white
                                                                : Colors
                                                                    .black87,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Books by Decade
            BooksByDecadeCard(
              sortedBooksByDecade: sortedBooksByDecade,
              showReadBooks: _showReadBooksDecade,
              onToggleChanged: (value) {
                setState(() {
                  _showReadBooksDecade = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Status Donut Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.books_by_status,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Text(
                              _showStatusAsPercentage ? '%' : '#',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Switch(
                              value: _showStatusAsPercentage,
                              onChanged: (value) {
                                setState(() {
                                  _showStatusAsPercentage = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 230,
                      child:
                          statusCounts.isEmpty
                              ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!.no_data,
                                ),
                              )
                              : PieChart(
                                PieChartData(
                                  sections:
                                      statusCounts.entries.map((entry) {
                                        final colors = [
                                          Colors.deepPurple,
                                          Colors.purple,
                                          Colors.purpleAccent,
                                          Colors.deepPurpleAccent,
                                        ];
                                        final index = statusCounts.keys
                                            .toList()
                                            .indexOf(entry.key);
                                        return PieChartSectionData(
                                          value: entry.value.toDouble(),
                                          title: '',
                                          radius: 50,
                                          color: colors[index % colors.length],
                                          badgeWidget: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color:
                                                    colors[index %
                                                        colors.length],
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              _showStatusAsPercentage
                                                  ? '${((entry.value / totalCount) * 100).toStringAsFixed(1)}%'
                                                  : '${entry.value}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    colors[index %
                                                        colors.length],
                                              ),
                                            ),
                                          ),
                                          badgePositionPercentageOffset: 1.4,
                                        );
                                      }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 45,
                                ),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children:
                          statusCounts.entries.map((entry) {
                            final colors = [
                              Colors.deepPurple,
                              Colors.purple,
                              Colors.purpleAccent,
                              Colors.deepPurpleAccent,
                            ];
                            final index = statusCounts.keys.toList().indexOf(
                              entry.key,
                            );
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Language Horizontal Bar Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.books_by_language,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (languageCounts.isEmpty)
                      Center(child: Text(AppLocalizations.of(context)!.no_data))
                    else
                      ...(languageCounts.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .map((entry) {
                            final maxValue = languageCounts.values.reduce(
                              (a, b) => a > b ? a : b,
                            );
                            final percentage = (entry.value / maxValue);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      entry.key,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: percentage,
                                          child: Container(
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 24,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '${entry.value}',
                                            style: TextStyle(
                                              color:
                                                  percentage > 0.15
                                                      ? Colors.white
                                                      : Colors.black87,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Format Pie Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.books_by_format,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            Text(
                              _showFormatAsPercentage ? '%' : '#',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Switch(
                              value: _showFormatAsPercentage,
                              onChanged: (value) {
                                setState(() {
                                  _showFormatAsPercentage = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 230,
                      child:
                          formatCounts.isEmpty
                              ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!.no_data,
                                ),
                              )
                              : PieChart(
                                PieChartData(
                                  sections:
                                      formatCounts.entries.map((entry) {
                                        final colors = [
                                          Colors.blue,
                                          Colors.cyan,
                                          Colors.teal,
                                          Colors.lightBlue,
                                        ];
                                        final index = formatCounts.keys
                                            .toList()
                                            .indexOf(entry.key);
                                        final percentage =
                                            (entry.value / totalCount) * 100;
                                        return PieChartSectionData(
                                          value: entry.value.toDouble(),
                                          title: '',
                                          radius: 50,
                                          color: colors[index % colors.length],
                                          badgeWidget: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color:
                                                    colors[index %
                                                        colors.length],
                                                width: 2,
                                              ),
                                            ),
                                            child: Text(
                                              _showFormatAsPercentage
                                                  ? '${percentage.toStringAsFixed(1)}%'
                                                  : '${entry.value}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    colors[index %
                                                        colors.length],
                                              ),
                                            ),
                                          ),
                                          badgePositionPercentageOffset: 1.4,
                                        );
                                      }).toList(),
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 45,
                                ),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children:
                          formatCounts.entries.map((entry) {
                            final colors = [
                              Colors.blue,
                              Colors.cyan,
                              Colors.teal,
                              Colors.lightBlue,
                            ];
                            final index = formatCounts.keys.toList().indexOf(
                              entry.key,
                            );
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reading Velocity Card
            if (readingVelocity > 0)
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Reading Velocity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            readingVelocity.toStringAsFixed(1),
                            style: Theme.of(
                              context,
                            ).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'pages/day',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on $booksUsedInAverageDays books with reading data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (readingVelocity > 0) const SizedBox(height: 16),
            // Average Days to Finish a Book Card
            if (averageDaysToFinish > 0)
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Average Time to Finish a Book',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            averageDaysToFinish.toStringAsFixed(1),
                            style: Theme.of(
                              context,
                            ).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'days',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on $booksUsedInAverageDays books with reading data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (averageDaysToFinish > 0) const SizedBox(height: 16),
            // Average Books Per Year Card
            if (averageBooksPerYear > 0)
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Average Books Per Year',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            averageBooksPerYear.toStringAsFixed(1),
                            style: Theme.of(
                              context,
                            ).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'books/year',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on $yearsWithBooks years of reading data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (averageBooksPerYear > 0) const SizedBox(height: 16),
            // Top 5 Genres Horizontal Bar Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.top_5_genres,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'All',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Switch(
                              value: _showReadBooksGenres,
                              onChanged: (value) {
                                setState(() {
                                  _showReadBooksGenres = value;
                                });
                              },
                            ),
                            Text(
                              'Read',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (top5Genres.isEmpty)
                      Center(child: Text(AppLocalizations.of(context)!.no_data))
                    else
                      ...top5Genres.map((entry) {
                        final maxValue = top5Genres.first.value;
                        final percentage = (entry.value / maxValue);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: percentage,
                                      child: Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 24,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${entry.value}',
                                        style: TextStyle(
                                          color:
                                              percentage > 0.15
                                                  ? Colors.white
                                                  : Colors.black87,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Top 10 Editorials Horizontal Bar Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.top_10_editorials,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'All',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Switch(
                              value: _showReadBooksEditorials,
                              onChanged: (value) {
                                setState(() {
                                  _showReadBooksEditorials = value;
                                });
                              },
                            ),
                            Text(
                              'Read',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...top10Editorials.map((entry) {
                      final maxValue = top10Editorials.first.value;
                      final percentage = (entry.value / maxValue);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage,
                                    child: Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 24,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${entry.value}',
                                      style: TextStyle(
                                        color:
                                            percentage > 0.15
                                                ? Colors.white
                                                : Colors.black87,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Top 10 Authors Horizontal Bar Chart
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.top_10_authors,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'All',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Switch(
                              value: _showReadBooksAuthors,
                              onChanged: (value) {
                                setState(() {
                                  _showReadBooksAuthors = value;
                                });
                              },
                            ),
                            Text(
                              'Read',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...top10Authors.map((entry) {
                      final maxValue = top10Authors.first.value;
                      final percentage = (entry.value / maxValue);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage,
                                    child: Container(
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 24,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${entry.value}',
                                      style: TextStyle(
                                        color:
                                            percentage > 0.15
                                                ? Colors.white
                                                : Colors.black87,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Separator for new statistics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      thickness: 2,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'ADVANCED STATISTICS',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 2,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Use widget components for advanced statistics with responsive layout
            ResponsiveStatGrid(
              children: [
                // Average Rating
                if (ratedBooksCount > 0)
                  AverageRatingCard(
                    averageRating: averageRating,
                    ratedBooksCount: ratedBooksCount,
                  ),
                // Book Extremes (Oldest/Newest, Shortest/Longest)
                BookExtremesCard(
                  oldestYear: oldestYear,
                  oldestBookName: oldestBookName,
                  newestYear: newestYear,
                  newestBookName: newestBookName,
                  shortestPages: shortestPages,
                  shortestBookName: shortestBookName,
                  longestPages: longestPages,
                  longestBookName: longestBookName,
                ),
                // Reading Insights (comprehensive card)
                ReadingInsightsCard(
                  currentStreak: currentStreak,
                  longestStreak: longestStreak,
                  dnfCount: dnfCount,
                  dnfRate: dnfRate,
                  rereadCount: rereadCount,
                  mostRereadBook: mostRereadBook,
                  seriesBooks: seriesBooks,
                  standaloneBooks: standaloneBooks,
                  seriesPercentage: seriesPercentage,
                  seriesCount: seriesCount,
                  mostBooksInMonth: mostBooksInMonth,
                  bestMonth: bestMonth,
                  fastestDays: fastestDays,
                  fastestBookName: fastestBookName,
                  nextMilestoneOwned: nextMilestoneOwned,
                  booksToMilestoneOwned: booksToMilestoneOwned,
                  nextMilestoneRead: nextMilestoneRead,
                  booksToMilestoneRead: booksToMilestoneRead,
                  bingePercentage: bingePercentage,
                  topGenreBySeason: topGenreBySeason,
                ),
                RatingDistributionCard(ratingDistribution: ratingDistribution),
                PageDistributionCard(pageDistribution: pageDistribution),
                if (sagaStats.isNotEmpty)
                  SagaCompletionCard(
                    completedSagas: completedSagas,
                    partialSagas: partialSagas,
                    unstartedSagas: unstartedSagas,
                  ),
                SeasonalReadingCard(
                  seasonalReading: seasonalReading,
                  yearsCount: yearsCount,
                ),
                // Monthly Reading Heatmap - Full calendar view (always full width)
              ],
            ),
            SeasonalPreferencesCard(seasonalReading: seasonalReading),
            const SizedBox(height: 16),
            MonthlyHeatmapCard(monthlyHeatmap: monthlyHeatmap),
            const SizedBox(height: 16),
            // Placeholder cards for future features
            ResponsiveStatGrid(
              children: [ReadingTimePlaceholderCard(), ReadingGoalsCard()],
            ),
            const SizedBox(height: 16),
            // Past Years Competition Card
            PastYearsCompetitionCard(pastWinners: _pastWinners),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Internal data structure representing the conceptual DailyReadings table
class _DailyReadingData {
  final int totalDaysWithTimeRead;      // Days where timeRead > 0
  final int totalDaysWithDidReadOnly;   // Days where didReadToday = true but no timeRead
  final int totalSecondsRead;           // Sum of all timeRead values (in seconds)
  final int totalReadingDays;           // Total unique reading days
  final bool hasTimeReadData;           // Whether any day has timeRead > 0
  final bool hasDidReadData;            // Whether any day has didReadToday = true

  _DailyReadingData({
    required this.totalDaysWithTimeRead,
    required this.totalDaysWithDidReadOnly,
    required this.totalSecondsRead,
    required this.totalReadingDays,
    required this.hasTimeReadData,
    required this.hasDidReadData,
  });
}
