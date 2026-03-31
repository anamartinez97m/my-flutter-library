import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/reading_session.dart';
import 'package:myrandomlibrary/model/read_date.dart';

/// Holds all computed statistics data for the statistics screen.
class StatisticsData {
  final int totalCount;
  final Map<String, int> statusCounts;
  final Map<String, int> languageCounts;
  final Map<String, int> formatCounts;
  final Map<String, int> formatCountsCurrentYear;
  final Map<String, int> placeCounts;
  final Map<String, Map<String, int>> formatByLanguageCounts;
  final List<MapEntry<int, int>> sortedBooksReadYears;
  final List<MapEntry<int, int>> sortedPagesReadYears;
  final Map<String, int> ratingDistribution;
  final Map<String, int> pageDistribution;
  final Map<String, Map<String, dynamic>> sagaStats;
  final int completedSagas;
  final int partialSagas;
  final int unstartedSagas;
  final Map<String, int> seasonalReading;
  final Map<int, Map<String, int>> seasonalReadingPerYear;
  final int yearsCount;
  final Map<int, Map<int, int>> monthlyHeatmap;
  final double averageRating;
  final int ratedBooksCount;
  final int? oldestYear;
  final String? oldestBookName;
  final int? newestYear;
  final String? newestBookName;
  final int? shortestPages;
  final String? shortestBookName;
  final int? longestPages;
  final String? longestBookName;
  final int currentStreak;
  final int longestStreak;
  final int dnfCount;
  final double dnfRate;
  final int rereadCount;
  final Map<String, dynamic>? mostRereadBook;
  final int totalBooksInSeries;
  final int standaloneBooks;
  final int totalBooksInSeriesRead;
  final int standaloneBooksRead;
  final int seriesCount;
  final int seriesCountRead;
  final double seriesPercentage;
  final int mostBooksInMonth;
  final String? bestMonth;
  final int? fastestDays;
  final String? fastestBookName;
  final int nextMilestoneOwned;
  final int booksToMilestoneOwned;
  final int nextMilestoneRead;
  final int booksToMilestoneRead;
  final double bingePercentage;
  final Map<String, String> topGenreBySeason;
  final double readingVelocity;
  final double averageDaysToFinish;
  final int booksUsedInAverageDays;
  final double averageBooksPerYear;
  final int yearsWithBooks;
  final int totalBooksRead;
  final int booksReadThisYear;
  final Map<int, Map<String, int>>
  dailyHeatmap; // year -> "YYYY-MM-DD" -> count
  final int daysReadThisYear;
  final PriceStatsData? priceStats;
  // Reading time of day: slot label -> {count, totalMinutes}
  final Map<String, Map<String, dynamic>> readingTimeOfDay;

  const StatisticsData({
    required this.totalCount,
    required this.statusCounts,
    required this.languageCounts,
    required this.formatCounts,
    required this.formatCountsCurrentYear,
    required this.placeCounts,
    required this.formatByLanguageCounts,
    required this.sortedBooksReadYears,
    required this.sortedPagesReadYears,
    required this.ratingDistribution,
    required this.pageDistribution,
    required this.sagaStats,
    required this.completedSagas,
    required this.partialSagas,
    required this.unstartedSagas,
    required this.seasonalReading,
    required this.seasonalReadingPerYear,
    required this.yearsCount,
    required this.monthlyHeatmap,
    required this.averageRating,
    required this.ratedBooksCount,
    required this.oldestYear,
    required this.oldestBookName,
    required this.newestYear,
    required this.newestBookName,
    required this.shortestPages,
    required this.shortestBookName,
    required this.longestPages,
    required this.longestBookName,
    required this.currentStreak,
    required this.longestStreak,
    required this.dnfCount,
    required this.dnfRate,
    required this.rereadCount,
    required this.mostRereadBook,
    required this.totalBooksInSeries,
    required this.standaloneBooks,
    required this.totalBooksInSeriesRead,
    required this.standaloneBooksRead,
    required this.seriesCount,
    required this.seriesCountRead,
    required this.seriesPercentage,
    required this.mostBooksInMonth,
    required this.bestMonth,
    required this.fastestDays,
    required this.fastestBookName,
    required this.nextMilestoneOwned,
    required this.booksToMilestoneOwned,
    required this.nextMilestoneRead,
    required this.booksToMilestoneRead,
    required this.bingePercentage,
    required this.topGenreBySeason,
    required this.readingVelocity,
    required this.averageDaysToFinish,
    required this.booksUsedInAverageDays,
    required this.averageBooksPerYear,
    required this.yearsWithBooks,
    required this.totalBooksRead,
    required this.booksReadThisYear,
    required this.dailyHeatmap,
    required this.daysReadThisYear,
    this.priceStats,
    required this.readingTimeOfDay,
  });
}

/// Holds computed price statistics data.
class PriceStatsData {
  final Map<String, double> avgPriceByFormat; // format -> avg price
  final Map<String, int> countByFormat; // format -> count of priced books
  final Map<int, double> totalSpentByYear; // year -> total spent
  final Map<int, double> avgPriceByYear; // year -> avg price
  final Map<int, Map<int, double>> totalSpentByMonth; // year -> month -> total
  final String? mostExpensiveName;
  final double? mostExpensivePrice;
  final String? leastExpensiveName;
  final double? leastExpensivePrice;
  final double totalSpent;
  // Price range evolution: year -> range label -> count
  final Map<int, Map<String, int>> priceRangesByYear;
  // Min/max price per year for line chart
  final Map<int, double> minPriceByYear;
  final Map<int, double> maxPriceByYear;

  const PriceStatsData({
    required this.avgPriceByFormat,
    required this.countByFormat,
    required this.totalSpentByYear,
    required this.avgPriceByYear,
    required this.totalSpentByMonth,
    this.mostExpensiveName,
    this.mostExpensivePrice,
    this.leastExpensiveName,
    this.leastExpensivePrice,
    required this.totalSpent,
    required this.priceRangesByYear,
    required this.minPriceByYear,
    required this.maxPriceByYear,
  });
}

/// Internal data structure representing the conceptual DailyReadings table
class DailyReadingData {
  final int totalDaysWithTimeRead;
  final int totalDaysWithDidReadOnly;
  final int totalSecondsRead;
  final int totalReadingDays;
  final bool hasTimeReadData;
  final bool hasDidReadData;

  DailyReadingData({
    required this.totalDaysWithTimeRead,
    required this.totalDaysWithDidReadOnly,
    required this.totalSecondsRead,
    required this.totalReadingDays,
    required this.hasTimeReadData,
    required this.hasDidReadData,
  });
}

/// Computes all statistics from raw data.
class StatisticsCalculator {
  final List<Book> books;
  final Map<int, List<ReadingSession>> bookSessions;
  final Map<int, List<ReadDate>> bookReadDates;
  final Map<String, int?> formatSagaMapping;
  final Map<int, int>? booksReadPerYear;
  final Map<int, int>? pagesReadPerYear;

  StatisticsCalculator({
    required this.books,
    required this.bookSessions,
    required this.bookReadDates,
    required this.formatSagaMapping,
    required this.booksReadPerYear,
    required this.pagesReadPerYear,
  });

  StatisticsData compute() {
    final totalCount = books.length;
    final currentYear = DateTime.now().year;

    final statusCounts = <String, int>{};
    final languageCounts = <String, int>{};
    final formatCounts = <String, int>{};
    final formatCountsCurrentYear = <String, int>{};
    final placeCounts = <String, int>{};
    final formatByLanguageCounts = <String, Map<String, int>>{};

    for (var book in books) {
      final multiplier =
          (book.isBundle == true &&
                  book.bundleCount != null &&
                  book.bundleCount! > 0)
              ? book.bundleCount!
              : 1;
      final status = book.statusValue ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + multiplier;
      final language = book.languageValue;
      if (language != null && language.isNotEmpty && language != 'Unknown') {
        languageCounts[language] = (languageCounts[language] ?? 0) + multiplier;
      }
      final format = book.formatValue;
      if (format != null && format.isNotEmpty) {
        formatCounts[format] = (formatCounts[format] ?? 0) + multiplier;
        if (language != null && language.isNotEmpty && language != 'Unknown') {
          formatByLanguageCounts.putIfAbsent(format, () => {});
          formatByLanguageCounts[format]![language] =
              (formatByLanguageCounts[format]![language] ?? 0) + multiplier;
        }
      }
      final place = book.placeValue;
      if (place != null && place.isNotEmpty) {
        placeCounts[place] = (placeCounts[place] ?? 0) + multiplier;
      }
      if (book.isBundle == true) {
        // skip bundles for current year format
      } else if (book.bookId != null && format != null && format.isNotEmpty) {
        final readDates = bookReadDates[book.bookId!] ?? [];
        bool hasCurrentYearRead = false;
        for (var readDate in readDates) {
          if (readDate.dateFinished != null &&
              readDate.dateFinished!.isNotEmpty) {
            final endDate = _tryParseDate(
              readDate.dateFinished!,
              bookName: book.name,
            );
            if (endDate != null && endDate.year == currentYear) {
              hasCurrentYearRead = true;
              break;
            }
          }
        }
        if (hasCurrentYearRead) {
          formatCountsCurrentYear[format] =
              (formatCountsCurrentYear[format] ?? 0) + 1;
        }
      }
    }

    double readingVelocity = _calculateReadingVelocity();
    double averageDaysToFinish = _calculateAverageDaysToFinish();
    int booksUsedInAverageDays = _getBooksUsedInAverageDaysCalculation();

    double averageBooksPerYear = 0.0;
    int yearsWithBooks = 0;
    if (booksReadPerYear != null && booksReadPerYear!.isNotEmpty) {
      final totalBooksVal = booksReadPerYear!.values.reduce((a, b) => a + b);
      yearsWithBooks = booksReadPerYear!.length;
      if (yearsWithBooks > 0)
        averageBooksPerYear = totalBooksVal / yearsWithBooks;
    }

    final booksReadPerYearMap = booksReadPerYear ?? {};
    final pagesReadPerYearMap = pagesReadPerYear ?? {};
    final sortedBooksReadYears =
        booksReadPerYearMap.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));
    final sortedPagesReadYears =
        pagesReadPerYearMap.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key));

    final ratingDistribution = _computeRatingDistribution();
    final pageDistribution = _computePageDistribution();

    final sagaResult = _computeSagaStats();
    final seasonalResult = _computeSeasonalReading();
    final monthlyHeatmap = _computeMonthlyHeatmap();

    double averageRating = 0.0;
    int ratedBooksCount = 0;
    for (var book in books) {
      if (book.myRating != null && book.myRating! > 0) {
        averageRating += book.myRating!;
        ratedBooksCount++;
      }
    }
    if (ratedBooksCount > 0) averageRating = averageRating / ratedBooksCount;

    final extremes = _computeBookExtremes();
    final streaks = _computeStreaks();
    final dnfResult = _computeDnf();
    final rereadResult = _computeRereads();
    final seriesResult = _computeSeriesVsStandalone();
    final personalBests = _computePersonalBests(monthlyHeatmap);
    final milestones = _computeMilestones();
    final bingeResult = _computeBingeReading();
    final moodResult = _computeMoodReading();
    final dailyHeatmapResult = _computeDailyReadingHeatmap();
    final priceStats = _computePriceStats();
    final readingTimeOfDay = _computeReadingTimeOfDay();

    // Quick stats
    final totalBooksRead =
        books.where((b) => b.readCount != null && b.readCount! > 0).length;
    int booksReadThisYear = 0;
    for (var yearEntry in monthlyHeatmap.entries) {
      if (yearEntry.key == currentYear) {
        booksReadThisYear = yearEntry.value.values.fold(0, (a, b) => a + b);
      }
    }

    return StatisticsData(
      totalCount: totalCount,
      statusCounts: statusCounts,
      languageCounts: languageCounts,
      formatCounts: formatCounts,
      formatCountsCurrentYear: formatCountsCurrentYear,
      placeCounts: placeCounts,
      formatByLanguageCounts: formatByLanguageCounts,
      sortedBooksReadYears: sortedBooksReadYears,
      sortedPagesReadYears: sortedPagesReadYears,
      ratingDistribution: ratingDistribution,
      pageDistribution: pageDistribution,
      sagaStats: sagaResult['sagaStats'] as Map<String, Map<String, dynamic>>,
      completedSagas: sagaResult['completedSagas'] as int,
      partialSagas: sagaResult['partialSagas'] as int,
      unstartedSagas: sagaResult['unstartedSagas'] as int,
      seasonalReading: seasonalResult['seasonalReading'] as Map<String, int>,
      seasonalReadingPerYear:
          seasonalResult['seasonalReadingPerYear']
              as Map<int, Map<String, int>>,
      yearsCount: seasonalResult['yearsCount'] as int,
      monthlyHeatmap: monthlyHeatmap,
      averageRating: averageRating,
      ratedBooksCount: ratedBooksCount,
      oldestYear: extremes['oldestYear'] as int?,
      oldestBookName: extremes['oldestBookName'] as String?,
      newestYear: extremes['newestYear'] as int?,
      newestBookName: extremes['newestBookName'] as String?,
      shortestPages: extremes['shortestPages'] as int?,
      shortestBookName: extremes['shortestBookName'] as String?,
      longestPages: extremes['longestPages'] as int?,
      longestBookName: extremes['longestBookName'] as String?,
      currentStreak: streaks['currentStreak'] as int,
      longestStreak: streaks['longestStreak'] as int,
      dnfCount: dnfResult['dnfCount'] as int,
      dnfRate: dnfResult['dnfRate'] as double,
      rereadCount: rereadResult['rereadCount'] as int,
      mostRereadBook: rereadResult['mostRereadBook'] as Map<String, dynamic>?,
      totalBooksInSeries: seriesResult['totalBooksInSeries'] as int,
      standaloneBooks: seriesResult['standaloneBooks'] as int,
      totalBooksInSeriesRead: seriesResult['totalBooksInSeriesRead'] as int,
      standaloneBooksRead: seriesResult['standaloneBooksRead'] as int,
      seriesCount: seriesResult['seriesCount'] as int,
      seriesCountRead: seriesResult['seriesCountRead'] as int,
      seriesPercentage: seriesResult['seriesPercentage'] as double,
      mostBooksInMonth: personalBests['mostBooksInMonth'] as int,
      bestMonth: personalBests['bestMonth'] as String?,
      fastestDays: personalBests['fastestDays'] as int?,
      fastestBookName: personalBests['fastestBookName'] as String?,
      nextMilestoneOwned: milestones['nextMilestoneOwned'] as int,
      booksToMilestoneOwned: milestones['booksToMilestoneOwned'] as int,
      nextMilestoneRead: milestones['nextMilestoneRead'] as int,
      booksToMilestoneRead: milestones['booksToMilestoneRead'] as int,
      bingePercentage: bingeResult,
      topGenreBySeason: moodResult,
      readingVelocity: readingVelocity,
      averageDaysToFinish: averageDaysToFinish,
      booksUsedInAverageDays: booksUsedInAverageDays,
      averageBooksPerYear: averageBooksPerYear,
      yearsWithBooks: yearsWithBooks,
      totalBooksRead: totalBooksRead,
      booksReadThisYear: booksReadThisYear,
      dailyHeatmap:
          dailyHeatmapResult['dailyHeatmap'] as Map<int, Map<String, int>>,
      daysReadThisYear: dailyHeatmapResult['daysReadThisYear'] as int,
      priceStats: priceStats,
      readingTimeOfDay: readingTimeOfDay,
    );
  }

  // --- Helper methods ---

  DateTime? _tryParseDate(String dateStr, {String? bookName}) {
    if (dateStr.trim().isEmpty) return null;
    final trimmed = dateStr.trim();
    try {
      return DateTime.parse(trimmed);
    } catch (e) {
      if (trimmed.contains('/')) {
        try {
          final parts = trimmed.split('/');
          if (parts.length == 3) {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            if (year > 1900) {
              return DateTime(year, month, day);
            } else {
              return DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          }
        } catch (e) {
          if (bookName != null)
            debugPrint(
              'Error parsing date "$dateStr" for book "$bookName": $e',
            );
          return null;
        }
      }
    }
    if (bookName != null)
      debugPrint('Could not parse date "$dateStr" for book "$bookName"');
    return null;
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

  String _getDayKey(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  DailyReadingData _mapSessionsToDailyReadings(List<ReadingSession> sessions) {
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
        if (session.durationSeconds != null && session.durationSeconds! > 0)
          dayTimeSeconds += session.durationSeconds!;
        if (session.didRead) hasDidRead = true;
      }
      if (dayTimeSeconds > 0) {
        totalDaysWithTimeRead++;
        totalSecondsRead += dayTimeSeconds;
        uniqueReadingDays.add(dayKey);
      } else if (hasDidRead) {
        totalDaysWithDidReadOnly++;
        uniqueReadingDays.add(dayKey);
      }
    }
    return DailyReadingData(
      totalDaysWithTimeRead: totalDaysWithTimeRead,
      totalDaysWithDidReadOnly: totalDaysWithDidReadOnly,
      totalSecondsRead: totalSecondsRead,
      totalReadingDays: uniqueReadingDays.length,
      hasTimeReadData: totalSecondsRead > 0,
      hasDidReadData:
          totalDaysWithDidReadOnly > 0 ||
          (totalDaysWithTimeRead > 0 && totalDaysWithDidReadOnly >= 0),
    );
  }

  double _calculateReadingVelocity() {
    int totalPages = 0;
    int totalReadingDays = 0;
    for (var book in books) {
      if (book.readCount == null ||
          book.readCount! <= 0 ||
          book.pages == null ||
          book.pages! <= 0)
        continue;
      final sessions = bookSessions[book.bookId] ?? [];
      final dailyData = _mapSessionsToDailyReadings(sessions);
      if (dailyData.hasTimeReadData) {
        totalReadingDays += dailyData.totalReadingDays;
      } else if (dailyData.hasDidReadData) {
        totalReadingDays += dailyData.totalReadingDays;
      } else {
        if (book.bookId != null) {
          final readDates = bookReadDates[book.bookId!] ?? [];
          for (var readDate in readDates) {
            if (readDate.dateStarted != null &&
                readDate.dateStarted!.isNotEmpty &&
                readDate.dateFinished != null &&
                readDate.dateFinished!.isNotEmpty) {
              final startDate = _tryParseDate(
                readDate.dateStarted!,
                bookName: book.name,
              );
              final endDate = _tryParseDate(
                readDate.dateFinished!,
                bookName: book.name,
              );
              if (startDate != null &&
                  endDate != null &&
                  endDate.isAfter(startDate)) {
                totalReadingDays += endDate.difference(startDate).inDays + 1;
              }
            }
          }
        }
      }
      totalPages += book.pages!;
    }
    return (totalReadingDays > 0 && totalPages > 0)
        ? totalPages.toDouble() / totalReadingDays.toDouble()
        : 0.0;
  }

  double _calculateAverageDaysToFinish() {
    double totalDays = 0.0;
    int booksWithValidData = 0;
    for (var book in books) {
      if (book.readCount == null || book.readCount! <= 0) continue;
      final sessions = bookSessions[book.bookId] ?? [];
      final dailyData = _mapSessionsToDailyReadings(sessions);
      int readingDays = 0;
      if (dailyData.hasTimeReadData) {
        readingDays = dailyData.totalReadingDays;
      } else if (dailyData.hasDidReadData) {
        readingDays = dailyData.totalReadingDays;
      } else {
        if (book.bookId != null) {
          final readDates = bookReadDates[book.bookId!] ?? [];
          if (readDates.isNotEmpty) {
            final lastReadDate = readDates.last;
            if (lastReadDate.dateStarted != null &&
                lastReadDate.dateStarted!.isNotEmpty &&
                lastReadDate.dateFinished != null &&
                lastReadDate.dateFinished!.isNotEmpty) {
              final startDate = _tryParseDate(
                lastReadDate.dateStarted!,
                bookName: book.name,
              );
              final endDate = _tryParseDate(
                lastReadDate.dateFinished!,
                bookName: book.name,
              );
              if (startDate != null &&
                  endDate != null &&
                  endDate.isAfter(startDate)) {
                readingDays = endDate.difference(startDate).inDays + 1;
              }
            }
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

  int _getBooksUsedInAverageDaysCalculation() {
    int count = 0;
    for (var book in books) {
      if (book.readCount == null || book.readCount! <= 0) continue;
      final sessions = bookSessions[book.bookId] ?? [];
      final dailyData = _mapSessionsToDailyReadings(sessions);
      int readingDays = 0;
      if (dailyData.hasTimeReadData) {
        readingDays = dailyData.totalReadingDays;
      } else if (dailyData.hasDidReadData) {
        readingDays = dailyData.totalReadingDays;
      } else {
        if (book.bookId != null) {
          final readDates = bookReadDates[book.bookId!] ?? [];
          if (readDates.isNotEmpty) {
            final lastReadDate = readDates.last;
            if (lastReadDate.dateStarted != null &&
                lastReadDate.dateStarted!.isNotEmpty &&
                lastReadDate.dateFinished != null &&
                lastReadDate.dateFinished!.isNotEmpty) {
              final startDate = _tryParseDate(
                lastReadDate.dateStarted!,
                bookName: book.name,
              );
              final endDate = _tryParseDate(
                lastReadDate.dateFinished!,
                bookName: book.name,
              );
              if (startDate != null &&
                  endDate != null &&
                  endDate.isAfter(startDate)) {
                readingDays = endDate.difference(startDate).inDays + 1;
              }
            }
          }
        }
      }
      if (readingDays > 0) count++;
    }
    return count;
  }

  Map<String, int> _computeRatingDistribution() {
    final Map<String, int> rd = {
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
        rd['Unrated'] = (rd['Unrated'] ?? 0) + 1;
      } else if (book.myRating! >= 5.0) {
        rd['5.0'] = (rd['5.0'] ?? 0) + 1;
      } else if (book.myRating! >= 4.0) {
        rd['4.0-4.9'] = (rd['4.0-4.9'] ?? 0) + 1;
      } else if (book.myRating! >= 3.0) {
        rd['3.0-3.9'] = (rd['3.0-3.9'] ?? 0) + 1;
      } else if (book.myRating! >= 2.0) {
        rd['2.0-2.9'] = (rd['2.0-2.9'] ?? 0) + 1;
      } else if (book.myRating! >= 1.0) {
        rd['1.0-1.9'] = (rd['1.0-1.9'] ?? 0) + 1;
      } else {
        rd['0.0-0.9'] = (rd['0.0-0.9'] ?? 0) + 1;
      }
    }
    return rd;
  }

  Map<String, int> _computePageDistribution() {
    final Map<String, int> pd = {
      '0-100': 0,
      '101-200': 0,
      '201-300': 0,
      '301-400': 0,
      '401-500': 0,
      '500+': 0,
    };
    for (var book in books) {
      if (book.pages != null && book.pages! > 0) {
        if (book.pages! <= 100)
          pd['0-100'] = (pd['0-100'] ?? 0) + 1;
        else if (book.pages! <= 200)
          pd['101-200'] = (pd['101-200'] ?? 0) + 1;
        else if (book.pages! <= 300)
          pd['201-300'] = (pd['201-300'] ?? 0) + 1;
        else if (book.pages! <= 400)
          pd['301-400'] = (pd['301-400'] ?? 0) + 1;
        else if (book.pages! <= 500)
          pd['401-500'] = (pd['401-500'] ?? 0) + 1;
        else
          pd['500+'] = (pd['500+'] ?? 0) + 1;
      }
    }
    return pd;
  }

  int _getExpectedTotal(String? formatSagaValue) {
    if (formatSagaValue == null || formatSagaValue.isEmpty) return -1;
    final expectedBooks = formatSagaMapping[formatSagaValue];
    if (expectedBooks == null) return -1;
    return expectedBooks;
  }

  Map<String, dynamic> _computeSagaStats() {
    final Map<String, Map<String, dynamic>> sagaStats = {};
    for (var book in books) {
      if (book.saga != null && book.saga!.isNotEmpty) {
        if (book.statusValue != null &&
            book.statusValue!.toLowerCase() == 'repeated')
          continue;
        if (!sagaStats.containsKey(book.saga!)) {
          final expectedTotal = _getExpectedTotal(book.formatSagaValue);
          sagaStats[book.saga!] = {
            'total': expectedTotal,
            'read': 0,
            'formatSaga': book.formatSagaValue ?? '',
          };
        }
        if (book.readCount != null && book.readCount! > 0) {
          sagaStats[book.saga!]!['read'] =
              (sagaStats[book.saga!]!['read'] as int) + 1;
        }
      }
    }
    final completedSagas =
        sagaStats.entries.where((e) {
          final total = e.value['total'] as int;
          final read = e.value['read'] as int;
          if (total == -1) return false;
          return read == total;
        }).length;
    final partialSagas =
        sagaStats.entries.where((e) {
          final total = e.value['total'] as int;
          final read = e.value['read'] as int;
          if (total == -1) return read > 0;
          return read > 0 && read < total;
        }).length;
    final unstartedSagas =
        sagaStats.entries.where((e) => (e.value['read'] as int) == 0).length;
    return {
      'sagaStats': sagaStats,
      'completedSagas': completedSagas,
      'partialSagas': partialSagas,
      'unstartedSagas': unstartedSagas,
    };
  }

  Map<String, dynamic> _computeSeasonalReading() {
    final Map<int, Map<String, int>> seasonalReadingPerYear = {};
    final Map<String, int> seasonalReading = {
      'Winter': 0,
      'Spring': 0,
      'Summer': 0,
      'Fall': 0,
    };
    for (var book in books) {
      if (book.dateReadFinal != null && book.dateReadFinal!.isNotEmpty) {
        final endDate = _tryParseDate(book.dateReadFinal!, bookName: book.name);
        if (endDate != null) {
          final year = endDate.year;
          final month = endDate.month;
          seasonalReadingPerYear.putIfAbsent(
            year,
            () => {'Winter': 0, 'Spring': 0, 'Summer': 0, 'Fall': 0},
          );
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
          seasonalReading[season] = (seasonalReading[season] ?? 0) + 1;
          seasonalReadingPerYear[year]![season] =
              (seasonalReadingPerYear[year]![season] ?? 0) + 1;
        }
      }
    }
    final int yearsCount =
        seasonalReadingPerYear.isNotEmpty ? seasonalReadingPerYear.length : 1;
    return {
      'seasonalReading': seasonalReading,
      'seasonalReadingPerYear': seasonalReadingPerYear,
      'yearsCount': yearsCount,
    };
  }

  Map<int, Map<int, int>> _computeMonthlyHeatmap() {
    final Map<int, Map<int, int>> monthlyHeatmap = {};
    for (var book in books) {
      if (book.isBundle == true) continue;
      if (book.bookId == null) continue;
      final readDates = bookReadDates[book.bookId!] ?? [];
      for (var readDate in readDates) {
        if (readDate.dateFinished != null &&
            readDate.dateFinished!.isNotEmpty) {
          final endDate = _tryParseDate(
            readDate.dateFinished!,
            bookName: book.name,
          );
          if (endDate != null) {
            final year = endDate.year;
            final month = endDate.month;
            monthlyHeatmap.putIfAbsent(year, () => {});
            monthlyHeatmap[year]![month] =
                (monthlyHeatmap[year]![month] ?? 0) + 1;
          }
        }
      }
    }
    return monthlyHeatmap;
  }

  Map<String, dynamic> _computeBookExtremes() {
    int? oldestYear, newestYear, shortestPages, longestPages;
    String? oldestBookName, newestBookName, shortestBookName, longestBookName;
    for (var book in books) {
      if (book.originalPublicationYear != null &&
          book.originalPublicationYear! > 0) {
        int pubYear = book.originalPublicationYear!;
        if (pubYear > 9999) pubYear = pubYear ~/ 10000;
        if (oldestYear == null || pubYear < oldestYear) {
          oldestYear = pubYear;
          oldestBookName = book.name;
        }
        if (newestYear == null || pubYear > newestYear) {
          newestYear = pubYear;
          newestBookName = book.name;
        }
      }
      if (book.isBundle == true) {
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
                if (shortestPages == null || pages < shortestPages) {
                  shortestPages = pages;
                  shortestBookName = bookTitle;
                }
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
        if (book.pages != null && book.pages! > 0) {
          if (shortestPages == null || book.pages! < shortestPages) {
            shortestPages = book.pages;
            shortestBookName = book.name;
          }
          if (longestPages == null || book.pages! > longestPages) {
            longestPages = book.pages;
            longestBookName = book.name;
          }
        }
      }
    }
    return {
      'oldestYear': oldestYear,
      'oldestBookName': oldestBookName,
      'newestYear': newestYear,
      'newestBookName': newestBookName,
      'shortestPages': shortestPages,
      'shortestBookName': shortestBookName,
      'longestPages': longestPages,
      'longestBookName': longestBookName,
    };
  }

  Map<String, int> _computeStreaks() {
    final Set<String> uniqueReadingDays = {};
    for (var bookSessionList in bookSessions.values) {
      for (var session in bookSessionList) {
        if (session.startTime != null) {
          uniqueReadingDays.add(
            DateFormat('yyyy-MM-dd').format(session.startTime!),
          );
        }
      }
    }
    final sortedReadingDays =
        uniqueReadingDays.map((dateStr) => DateTime.parse(dateStr)).toList()
          ..sort();
    int currentStreak = 0, longestStreak = 0, tempStreak = 0;
    DateTime? lastDate;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    for (var date in sortedReadingDays) {
      if (lastDate == null) {
        tempStreak = 1;
      } else {
        final daysDiff = date.difference(lastDate).inDays;
        if (daysDiff == 1) {
          tempStreak++;
        } else if (daysDiff == 0) {
          continue;
        } else {
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 1;
        }
      }
      lastDate = date;
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;
    if (lastDate != null) {
      final daysSinceLastRead = todayDateOnly.difference(lastDate).inDays;
      if (daysSinceLastRead == 0 || daysSinceLastRead == 1)
        currentStreak = tempStreak;
    }
    return {'currentStreak': currentStreak, 'longestStreak': longestStreak};
  }

  Map<String, dynamic> _computeDnf() {
    int dnfCount = 0;
    for (var book in books) {
      if (book.statusValue != null &&
          (book.statusValue!.toLowerCase().contains('abandoned') ||
              book.statusValue!.toLowerCase().contains('dnf')))
        dnfCount++;
    }
    final dnfRate = books.isNotEmpty ? (dnfCount / books.length) * 100 : 0.0;
    return {'dnfCount': dnfCount, 'dnfRate': dnfRate};
  }

  Map<String, dynamic> _computeRereads() {
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
    return {'rereadCount': rereadCount, 'mostRereadBook': mostRereadBook};
  }

  Map<String, dynamic> _computeSeriesVsStandalone() {
    int totalBooksInSeries = 0,
        standaloneBooks = 0,
        totalBooksInSeriesRead = 0,
        standaloneBooksRead = 0;
    final Set<String> uniqueSeries = {}, uniqueSeriesRead = {};
    for (var book in books) {
      final isRead = book.readCount != null && book.readCount! > 0;
      if (book.saga != null && book.saga!.isNotEmpty) {
        totalBooksInSeries++;
        if (isRead) totalBooksInSeriesRead++;
        uniqueSeries.add(book.saga!);
        if (isRead) uniqueSeriesRead.add(book.saga!);
      } else {
        standaloneBooks++;
        if (isRead) standaloneBooksRead++;
      }
    }
    final seriesCount = uniqueSeries.length;
    final seriesCountRead = uniqueSeriesRead.length;
    final seriesPercentage =
        books.isNotEmpty ? (totalBooksInSeries / books.length) * 100 : 0.0;
    return {
      'totalBooksInSeries': totalBooksInSeries,
      'standaloneBooks': standaloneBooks,
      'totalBooksInSeriesRead': totalBooksInSeriesRead,
      'standaloneBooksRead': standaloneBooksRead,
      'seriesCount': seriesCount,
      'seriesCountRead': seriesCountRead,
      'seriesPercentage': seriesPercentage,
    };
  }

  Map<String, dynamic> _computePersonalBests(
    Map<int, Map<int, int>> monthlyHeatmap,
  ) {
    int mostBooksInMonth = 0;
    String? bestMonth;
    int? fastestDays;
    String? fastestBookName;
    for (var yearData in monthlyHeatmap.entries) {
      for (var monthData in yearData.value.entries) {
        if (monthData.value > mostBooksInMonth) {
          mostBooksInMonth = monthData.value;
          bestMonth = '${_getMonthName(monthData.key)} ${yearData.key}';
        }
      }
    }
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
    return {
      'mostBooksInMonth': mostBooksInMonth,
      'bestMonth': bestMonth,
      'fastestDays': fastestDays,
      'fastestBookName': fastestBookName,
    };
  }

  Map<String, int> _computeMilestones() {
    final totalCount = books.length;
    final readBooks =
        books.where((b) => b.readCount != null && b.readCount! > 0).length;
    final nextMilestoneOwned =
        totalCount < 100
            ? 100
            : totalCount < 500
            ? 500
            : totalCount < 1000
            ? 1000
            : ((totalCount ~/ 250) + 1) * 250;
    final booksToMilestoneOwned = nextMilestoneOwned - totalCount;
    final nextMilestoneRead =
        readBooks < 100
            ? 100
            : readBooks < 500
            ? 500
            : readBooks < 1000
            ? 1000
            : ((readBooks ~/ 250) + 1) * 250;
    final booksToMilestoneRead = nextMilestoneRead - readBooks;
    return {
      'nextMilestoneOwned': nextMilestoneOwned,
      'booksToMilestoneOwned': booksToMilestoneOwned,
      'nextMilestoneRead': nextMilestoneRead,
      'booksToMilestoneRead': booksToMilestoneRead,
    };
  }

  double _computeBingeReading() {
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
        if (daysDiff <= 14) bingeCount++;
      }
    }
    return sortedReadBooks.length > 1
        ? (bingeCount / (sortedReadBooks.length - 1)) * 100
        : 0.0;
  }

  Map<String, String> _computeMoodReading() {
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
    final Map<String, String> topGenreBySeason = {};
    for (var season in genreBySeason.keys) {
      if (genreBySeason[season]!.isNotEmpty) {
        final topGenre = genreBySeason[season]!.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        topGenreBySeason[season] = topGenre.key;
      }
    }
    return topGenreBySeason;
  }

  Map<String, dynamic> _computeDailyReadingHeatmap() {
    final currentYear = DateTime.now().year;
    final Map<int, Map<String, int>> dailyHeatmap = {};
    for (var sessionList in bookSessions.values) {
      for (var session in sessionList) {
        if (session.startTime != null) {
          final year = session.startTime!.year;
          final dayKey = _getDayKey(session.startTime!);
          dailyHeatmap.putIfAbsent(year, () => {});
          dailyHeatmap[year]![dayKey] = (dailyHeatmap[year]![dayKey] ?? 0) + 1;
        }
      }
    }
    // Count unique days read this year
    final currentYearDays = dailyHeatmap[currentYear] ?? {};
    final daysReadThisYear = currentYearDays.keys.length;
    return {'dailyHeatmap': dailyHeatmap, 'daysReadThisYear': daysReadThisYear};
  }

  String _getPriceRange(double price) {
    if (price < 5) return '0-5';
    if (price < 10) return '5-10';
    if (price < 15) return '10-15';
    if (price < 20) return '15-20';
    if (price < 30) return '20-30';
    return '30+';
  }

  static const List<String> priceRangeLabels = [
    '0-5',
    '5-10',
    '10-15',
    '15-20',
    '20-30',
    '30+',
  ];

  PriceStatsData? _computePriceStats() {
    final pricedBooks =
        books.where((b) => b.price != null && b.price! > 0).toList();
    if (pricedBooks.isEmpty) return null;

    // Totals
    double totalSpent = 0;
    String? mostExpensiveName, leastExpensiveName;
    double? mostExpensivePrice, leastExpensivePrice;

    // By format
    final Map<String, double> formatTotals = {};
    final Map<String, int> formatCounts = {};

    // By year (using finish date from bookReadDates)
    final Map<int, double> yearTotals = {};
    final Map<int, int> yearCounts = {};
    final Map<int, double> minPriceByYear = {};
    final Map<int, double> maxPriceByYear = {};

    // By month
    final Map<int, Map<int, double>> monthTotals = {};

    // Price range evolution by year
    final Map<int, Map<String, int>> priceRangesByYear = {};

    for (var book in pricedBooks) {
      final price = book.price!;
      totalSpent += price;

      // Most / Least expensive
      if (mostExpensivePrice == null || price > mostExpensivePrice) {
        mostExpensivePrice = price;
        mostExpensiveName = book.name;
      }
      if (leastExpensivePrice == null || price < leastExpensivePrice) {
        leastExpensivePrice = price;
        leastExpensiveName = book.name;
      }

      // By format
      final format = book.formatValue;
      if (format != null && format.isNotEmpty) {
        formatTotals[format] = (formatTotals[format] ?? 0) + price;
        formatCounts[format] = (formatCounts[format] ?? 0) + 1;
      }

      // By year & month (using read dates)
      if (book.bookId != null) {
        final readDates = bookReadDates[book.bookId!] ?? [];
        bool assignedToYear = false;
        for (var readDate in readDates) {
          if (readDate.dateFinished != null &&
              readDate.dateFinished!.isNotEmpty) {
            final endDate = _tryParseDate(
              readDate.dateFinished!,
              bookName: book.name,
            );
            if (endDate != null) {
              final year = endDate.year;
              final month = endDate.month;
              if (!assignedToYear) {
                yearTotals[year] = (yearTotals[year] ?? 0) + price;
                yearCounts[year] = (yearCounts[year] ?? 0) + 1;
                monthTotals.putIfAbsent(year, () => {});
                monthTotals[year]![month] =
                    (monthTotals[year]![month] ?? 0) + price;
                // Min/max per year
                minPriceByYear[year] =
                    (minPriceByYear[year] == null ||
                            price < minPriceByYear[year]!)
                        ? price
                        : minPriceByYear[year]!;
                maxPriceByYear[year] =
                    (maxPriceByYear[year] == null ||
                            price > maxPriceByYear[year]!)
                        ? price
                        : maxPriceByYear[year]!;
                // Price range evolution
                final range = _getPriceRange(price);
                priceRangesByYear.putIfAbsent(year, () => {});
                priceRangesByYear[year]![range] =
                    (priceRangesByYear[year]![range] ?? 0) + 1;
                assignedToYear = true;
              }
            }
          }
        }
        // If no read date, use createdAt year as fallback
        if (!assignedToYear && book.createdAt != null) {
          final createdDate = _tryParseDate(
            book.createdAt!,
            bookName: book.name,
          );
          if (createdDate != null) {
            final year = createdDate.year;
            final month = createdDate.month;
            yearTotals[year] = (yearTotals[year] ?? 0) + price;
            yearCounts[year] = (yearCounts[year] ?? 0) + 1;
            monthTotals.putIfAbsent(year, () => {});
            monthTotals[year]![month] =
                (monthTotals[year]![month] ?? 0) + price;
            minPriceByYear[year] =
                (minPriceByYear[year] == null || price < minPriceByYear[year]!)
                    ? price
                    : minPriceByYear[year]!;
            maxPriceByYear[year] =
                (maxPriceByYear[year] == null || price > maxPriceByYear[year]!)
                    ? price
                    : maxPriceByYear[year]!;
            final range = _getPriceRange(price);
            priceRangesByYear.putIfAbsent(year, () => {});
            priceRangesByYear[year]![range] =
                (priceRangesByYear[year]![range] ?? 0) + 1;
          }
        }
      }
    }

    // Compute averages
    final Map<String, double> avgPriceByFormat = {};
    for (var entry in formatTotals.entries) {
      avgPriceByFormat[entry.key] = entry.value / formatCounts[entry.key]!;
    }
    final Map<int, double> avgPriceByYear = {};
    for (var entry in yearTotals.entries) {
      avgPriceByYear[entry.key] = entry.value / yearCounts[entry.key]!;
    }

    return PriceStatsData(
      avgPriceByFormat: avgPriceByFormat,
      countByFormat: formatCounts,
      totalSpentByYear: yearTotals,
      avgPriceByYear: avgPriceByYear,
      totalSpentByMonth: monthTotals,
      mostExpensiveName: mostExpensiveName,
      mostExpensivePrice: mostExpensivePrice,
      leastExpensiveName: leastExpensiveName,
      leastExpensivePrice: leastExpensivePrice,
      totalSpent: totalSpent,
      priceRangesByYear: priceRangesByYear,
      minPriceByYear: minPriceByYear,
      maxPriceByYear: maxPriceByYear,
    );
  }

  /// Computes reading time of day distribution from session start times.
  /// Returns: slot label -> {count: int, totalMinutes: int}
  /// Slots: Madrugada (0-6), Morning (6-12), Afternoon (12-18), Night (18-0)
  Map<String, Map<String, dynamic>> _computeReadingTimeOfDay() {
    final Map<String, int> slotCounts = {
      'late_night': 0,
      'morning': 0,
      'afternoon': 0,
      'night': 0,
    };
    final Map<String, int> slotMinutes = {
      'late_night': 0,
      'morning': 0,
      'afternoon': 0,
      'night': 0,
    };

    for (var sessionList in bookSessions.values) {
      for (var session in sessionList) {
        final time = session.clickedAt ?? session.startTime;
        if (time == null) continue;
        final hour = time.hour;
        final slot = _getTimeSlot(hour);
        slotCounts[slot] = (slotCounts[slot] ?? 0) + 1;
        if (session.durationSeconds != null && session.durationSeconds! > 0) {
          slotMinutes[slot] =
              (slotMinutes[slot] ?? 0) + (session.durationSeconds! ~/ 60);
        }
      }
    }

    final Map<String, Map<String, dynamic>> result = {};
    for (var slot in slotCounts.keys) {
      result[slot] = {
        'count': slotCounts[slot]!,
        'totalMinutes': slotMinutes[slot]!,
      };
    }
    return result;
  }

  String _getTimeSlot(int hour) {
    if (hour >= 0 && hour < 6) return 'late_night';
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    return 'night'; // 18-0
  }
}
