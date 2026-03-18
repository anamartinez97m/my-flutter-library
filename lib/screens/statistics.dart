import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/books_by_year.dart';
import 'package:myrandomlibrary/screens/statistics_section_screen.dart';
import 'package:myrandomlibrary/helpers/statistics_calculator.dart';
import 'package:myrandomlibrary/widgets/statistics/total_books_card.dart';
import 'package:myrandomlibrary/widgets/statistics/latest_book_card.dart';
import 'package:myrandomlibrary/widgets/statistics/books_by_decade_card.dart';
import 'package:myrandomlibrary/widgets/statistics/rating_distribution_card.dart';
import 'package:myrandomlibrary/widgets/statistics/page_distribution_card.dart';
import 'package:myrandomlibrary/widgets/statistics/saga_completion_card.dart';
import 'package:myrandomlibrary/widgets/statistics/seasonal_reading_card.dart';
import 'package:myrandomlibrary/widgets/statistics/monthly_heatmap_card.dart';
import 'package:myrandomlibrary/widgets/statistics/average_rating_card.dart';
import 'package:myrandomlibrary/widgets/statistics/book_extremes_card.dart';
import 'package:myrandomlibrary/widgets/statistics/reading_insights_card.dart';
import 'package:myrandomlibrary/widgets/statistics/reading_time_of_day_card.dart';
import 'package:myrandomlibrary/widgets/statistics/reading_goals_card.dart';
import 'package:myrandomlibrary/widgets/statistics/quick_stats_row.dart';
import 'package:myrandomlibrary/widgets/statistics/daily_reading_heatmap_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myrandomlibrary/widgets/statistics/book_competition_card.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/screens/book_competition_screen.dart';
import 'package:myrandomlibrary/model/reading_session.dart';
import 'package:myrandomlibrary/repositories/reading_session_repository.dart';
import 'package:myrandomlibrary/model/read_date.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  Map<int, int>? _booksReadPerYear;
  Map<int, int>? _pagesReadPerYear;

  // Competition data
  BookCompetition? _yearlyWinner;
  List<BookCompetition> _nominees = [];
  bool _isLoadingCompetition = true;

  // Reading sessions data for statistics
  Map<int, List<ReadingSession>> _bookSessions = {};
  bool _isLoadingSessions = true;

  // Read dates data for statistics (from book_read_dates table)
  Map<int, List<ReadDate>> _bookReadDates = {};
  bool _isLoadingReadDates = true;

  // Format saga expected books mapping
  Map<String, int?> _formatSagaMapping = {};

  bool _hasTriggeredProviderLoads = false;

  // Price statistics toggle & currency
  bool _showPriceStatistics = false;
  String _currencySymbol = '€';

  @override
  void initState() {
    super.initState();
    _loadYearData();
    _loadCompetitionData();
    _loadFormatSagaMapping();
    _loadPricePrefs();
  }

  void _triggerProviderDependentLoads() {
    if (!_hasTriggeredProviderLoads) {
      _hasTriggeredProviderLoads = true;
      _loadReadingSessionsData();
      _loadReadDatesData();
    }
  }

  Future<void> _loadPricePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showPriceStatistics = prefs.getBool('show_price_statistics') ?? false;
        _currencySymbol = prefs.getString('currency_symbol') ?? '€';
      });
    }
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

      final competitionResult = await repository.getCompetitionResults(
        currentYear,
      );

      if (competitionResult != null) {
        _yearlyWinner = competitionResult.yearlyWinner;
        _nominees = _calculateCurrentNominees(competitionResult);
      } else {
        _nominees = [];
      }

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
            final sessions = await sessionRepository.getDisplaySessionsForBook(
              book.bookId!,
            );
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

  Future<void> _loadFormatSagaMapping() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final mapping = await repository.getFormatSagaExpectedBooks();
      if (mounted) {
        setState(() {
          _formatSagaMapping = mapping;
        });
      }
    } catch (e) {
      debugPrint('Error loading format saga mapping: $e');
    }
  }

  Future<void> _loadReadDatesData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final provider = Provider.of<BookProvider?>(context, listen: false);

      if (provider != null && !provider.isLoading) {
        final books = provider.allBooks;
        final Map<int, List<ReadDate>> bookReadDates = {};

        for (var book in books) {
          if (book.bookId != null) {
            final readDates = await repository.getReadDatesForBook(
              book.bookId!,
            );
            if (readDates.isNotEmpty) {
              bookReadDates[book.bookId!] = readDates;
            }
          }
        }

        if (mounted) {
          setState(() {
            _bookReadDates = bookReadDates;
            _isLoadingReadDates = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading read dates for stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingReadDates = false;
        });
      }
    }
  }

  List<BookCompetition> _calculateCurrentNominees(
    CompetitionResult competitionResult,
  ) {
    List<BookCompetition> nominees = [];

    if (competitionResult.yearlyWinner != null) {
      return [competitionResult.yearlyWinner!];
    }

    if (competitionResult.semifinalWinners.length == 2) {
      return competitionResult.semifinalWinners.map((s) => s.winner).toList();
    }

    if (competitionResult.quarterlyWinners.isNotEmpty) {
      nominees.addAll(competitionResult.quarterlyWinners.map((q) => q.winner));

      Set<int> quarterMonths = {};
      for (final quarterWinner in competitionResult.quarterlyWinners) {
        final quarter = quarterWinner.quarter;
        final startMonth = (quarter - 1) * 3 + 1;
        final endMonth = quarter * 3;
        for (int month = startMonth; month <= endMonth; month++) {
          quarterMonths.add(month);
        }
      }

      for (final monthlyWinner in competitionResult.monthlyWinners) {
        if (!quarterMonths.contains(monthlyWinner.month)) {
          nominees.add(monthlyWinner.winner);
        }
      }

      return nominees;
    }

    return competitionResult.monthlyWinners.map((m) => m.winner).toList();
  }

  StatisticsData _computeCurrentStats(List<Book> books) {
    final calculator = StatisticsCalculator(
      books: books,
      bookSessions: _bookSessions,
      bookReadDates: _bookReadDates,
      formatSagaMapping: _formatSagaMapping,
      booksReadPerYear: _booksReadPerYear,
      pagesReadPerYear: _pagesReadPerYear,
    );
    return calculator.compute();
  }

  // --- Section builder methods for carousel screens ---

  List<Widget> _buildReadingActivityCards(
    BuildContext context,
    StatisticsData stats,
    List<Book> books,
  ) {
    return [
      _BooksReadPerYearCard(booksReadPerYear: _booksReadPerYear),
      _PagesReadPerYearCard(pagesReadPerYear: _pagesReadPerYear),
      MonthlyHeatmapCard(monthlyHeatmap: stats.monthlyHeatmap),
      if (stats.dailyHeatmap.isNotEmpty)
        DailyReadingHeatmapCard(dailyHeatmap: stats.dailyHeatmap),
      ReadingGoalsCard(),
      _ReadingEfficiencyCard(
        readingVelocity: stats.readingVelocity,
        averageDaysToFinish: stats.averageDaysToFinish,
        averageBooksPerYear: stats.averageBooksPerYear,
        booksUsedInAverageDays: stats.booksUsedInAverageDays,
        yearsWithBooks: stats.yearsWithBooks,
      ),
      BooksByDecadeCard(books: books),
    ];
  }

  List<Widget> _buildLibraryBreakdownCards(
    BuildContext context,
    StatisticsData stats,
  ) {
    return [
      _StatusDonutCard(
        statusCounts: stats.statusCounts,
        totalCount: stats.totalCount,
      ),
      _FormatDonutCard(
        formatCounts: stats.formatCounts,
        formatCountsCurrentYear: stats.formatCountsCurrentYear,
      ),
      if (stats.placeCounts.isNotEmpty)
        _PlaceDonutCard(placeCounts: stats.placeCounts),
      _LanguageBarCard(languageCounts: stats.languageCounts),
      _FormatByLanguageCard(
        formatByLanguageCounts: stats.formatByLanguageCounts,
      ),
    ];
  }

  List<Widget> _buildTopRankingsCards(
    BuildContext context,
    StatisticsData stats,
    List<Book> books,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _TopRankingCard(
        title: l10n.top_5_genres,
        books: books,
        color: Colors.green,
        fieldExtractor: (book) => book.genre ?? '',
        topN: 5,
      ),
      _TopRankingCard(
        title: l10n.top_10_editorials,
        books: books,
        color: Colors.orange,
        fieldExtractor: (book) => book.editorialValue ?? '',
      ),
      _TopRankingCard(
        title: l10n.top_10_authors,
        books: books,
        color: Colors.red,
        fieldExtractor: (book) => book.author ?? '',
      ),
    ];
  }

  List<Widget> _buildRatingsAndPagesCards(
    BuildContext context,
    StatisticsData stats,
  ) {
    return [
      AverageRatingCard(
        averageRating: stats.averageRating,
        ratedBooksCount: stats.ratedBooksCount,
      ),
      RatingDistributionCard(ratingDistribution: stats.ratingDistribution),
      PageDistributionCard(pageDistribution: stats.pageDistribution),
      BookExtremesCard(
        oldestYear: stats.oldestYear,
        oldestBookName: stats.oldestBookName,
        newestYear: stats.newestYear,
        newestBookName: stats.newestBookName,
        shortestPages: stats.shortestPages,
        shortestBookName: stats.shortestBookName,
        longestPages: stats.longestPages,
        longestBookName: stats.longestBookName,
      ),
    ];
  }

  List<Widget> _buildSagasAndSeriesCards(
    BuildContext context,
    StatisticsData stats,
    List<Book> books,
  ) {
    return [
      SagaCompletionCard(
        sagaStats: stats.sagaStats,
        completedSagas: stats.completedSagas,
        partialSagas: stats.partialSagas,
        unstartedSagas: stats.unstartedSagas,
        books: books,
      ),
    ];
  }

  List<Widget> _buildReadingPatternsCards(
    BuildContext context,
    StatisticsData stats,
  ) {
    return [
      ReadingInsightsCard(
        currentStreak: stats.currentStreak,
        longestStreak: stats.longestStreak,
        dnfCount: stats.dnfCount,
        dnfRate: stats.dnfRate,
        rereadCount: stats.rereadCount,
        mostRereadBook: stats.mostRereadBook,
        seriesBooks: stats.totalBooksInSeries,
        standaloneBooks: stats.standaloneBooks,
        seriesBooksRead: stats.totalBooksInSeriesRead,
        standaloneBooksRead: stats.standaloneBooksRead,
        seriesPercentage: stats.seriesPercentage,
        seriesCount: stats.seriesCount,
        mostBooksInMonth: stats.mostBooksInMonth,
        bestMonth: stats.bestMonth,
        fastestDays: stats.fastestDays,
        fastestBookName: stats.fastestBookName,
        nextMilestoneOwned: stats.nextMilestoneOwned,
        booksToMilestoneOwned: stats.booksToMilestoneOwned,
        nextMilestoneRead: stats.nextMilestoneRead,
        booksToMilestoneRead: stats.booksToMilestoneRead,
        bingePercentage: stats.bingePercentage,
      ),
      SeasonalReadingCard(
        seasonalReading: stats.seasonalReading,
        seasonalReadingPerYear: stats.seasonalReadingPerYear,
        yearsCount: stats.yearsCount,
        topGenreBySeason: stats.topGenreBySeason,
      ),
      ReadingTimeOfDayCard(readingTimeOfDay: stats.readingTimeOfDay),
    ];
  }

  List<Widget> _buildPriceStatisticsCards(
    BuildContext context,
    StatisticsData stats,
  ) {
    final priceStats = stats.priceStats;
    if (priceStats == null) {
      return [
        Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
              child: Text(
                AppLocalizations.of(context)!.no_price_data,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ];
    }
    return [
      _PriceByFormatCard(
        avgPriceByFormat: priceStats.avgPriceByFormat,
        countByFormat: priceStats.countByFormat,
        currencySymbol: _currencySymbol,
      ),
      _PriceByYearCard(
        totalSpentByYear: priceStats.totalSpentByYear,
        avgPriceByYear: priceStats.avgPriceByYear,
        currencySymbol: _currencySymbol,
      ),
      _PriceByMonthCard(
        totalSpentByMonth: priceStats.totalSpentByMonth,
        currencySymbol: _currencySymbol,
      ),
      _MostLeastExpensiveCard(
        mostExpensiveName: priceStats.mostExpensiveName,
        mostExpensivePrice: priceStats.mostExpensivePrice,
        leastExpensiveName: priceStats.leastExpensiveName,
        leastExpensivePrice: priceStats.leastExpensivePrice,
        totalSpent: priceStats.totalSpent,
        currencySymbol: _currencySymbol,
      ),
      _PriceRangeEvolutionCard(
        avgPriceByYear: priceStats.avgPriceByYear,
        minPriceByYear: priceStats.minPriceByYear,
        maxPriceByYear: priceStats.maxPriceByYear,
        currencySymbol: _currencySymbol,
      ),
    ];
  }

  void _navigateToSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> cards,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StatisticsSectionScreen(
              title: title,
              icon: icon,
              children: cards,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Trigger provider-dependent loads once provider is ready
    _triggerProviderDependentLoads();

    if (_isLoadingReadDates || _isLoadingSessions) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final books = provider.allBooks;
    final latestBookName = provider.latestBookAdded;

    final stats = _computeCurrentStats(books);

    final l10n = AppLocalizations.of(context)!;
    final currentYear = DateTime.now().year;

    // Section definitions for the dashboard grid
    final sections = <_SectionDef>[
      _SectionDef(
        title: l10n.section_reading_activity,
        icon: Icons.auto_graph,
        onTap:
            () => _navigateToSection(
              context,
              l10n.section_reading_activity,
              Icons.auto_graph,
              _buildReadingActivityCards(
                context,
                _computeCurrentStats(books),
                books,
              ),
            ),
      ),
      _SectionDef(
        title: l10n.section_library_breakdown,
        icon: Icons.library_books,
        onTap:
            () => _navigateToSection(
              context,
              l10n.section_library_breakdown,
              Icons.library_books,
              _buildLibraryBreakdownCards(context, _computeCurrentStats(books)),
            ),
      ),
      _SectionDef(
        title: l10n.section_top_rankings,
        icon: Icons.leaderboard,
        onTap:
            () => _navigateToSection(
              context,
              l10n.section_top_rankings,
              Icons.leaderboard,
              _buildTopRankingsCards(
                context,
                _computeCurrentStats(books),
                books,
              ),
            ),
      ),
      _SectionDef(
        title: l10n.section_ratings_pages,
        icon: Icons.star_half,
        onTap:
            () => _navigateToSection(
              context,
              l10n.section_ratings_pages,
              Icons.star_half,
              _buildRatingsAndPagesCards(context, _computeCurrentStats(books)),
            ),
      ),
      _SectionDef(
        title: l10n.section_sagas_series,
        icon: Icons.collections_bookmark,
        onTap:
            () => _navigateToSection(
              context,
              l10n.section_sagas_series,
              Icons.collections_bookmark,
              _buildSagasAndSeriesCards(
                context,
                _computeCurrentStats(books),
                books,
              ),
            ),
      ),
      _SectionDef(
        title: l10n.section_reading_patterns,
        icon: Icons.insights,
        onTap:
            () => _navigateToSection(
              context,
              l10n.section_reading_patterns,
              Icons.insights,
              _buildReadingPatternsCards(context, _computeCurrentStats(books)),
            ),
      ),
      if (_showPriceStatistics)
        _SectionDef(
          title: l10n.section_price_statistics,
          icon: Icons.attach_money,
          onTap:
              () => _navigateToSection(
                context,
                l10n.section_price_statistics,
                Icons.attach_money,
                _buildPriceStatisticsCards(
                  context,
                  _computeCurrentStats(books),
                ),
              ),
        ),
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // Header row: Total Books + Latest Book
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(child: TotalBooksCard(totalCount: stats.totalCount)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LatestBookCard(latestBookName: latestBookName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Book Competition Card
            if (!_isLoadingCompetition)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => BookCompetitionScreen(year: currentYear),
                      ),
                    );
                  },
                  child: BookCompetitionCard(
                    currentYear: currentYear,
                    yearlyWinner: _yearlyWinner,
                    nominees: _nominees,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Quick Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: QuickStatsRow(data: stats),
            ),
            const SizedBox(height: 4),
            // Hint text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.quick_stat_long_press_hint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Section cards grid
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: section.onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            section.icon,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              section.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// --- Helper types ---

class _SectionDef {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _SectionDef({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

// === Extracted inline card widgets (self-contained with own toggle state) ===

/// Books Read Per Year — horizontal fill-bar chart, tappable rows → BooksByYearScreen
class _BooksReadPerYearCard extends StatelessWidget {
  final Map<int, int>? booksReadPerYear;
  const _BooksReadPerYearCard({this.booksReadPerYear});

  @override
  Widget build(BuildContext context) {
    final sortedYears =
        booksReadPerYear?.entries.toList()
          ?..sort((a, b) => b.key.compareTo(a.key));
    return InkWell(
      onTap: () {
        if (sortedYears != null && sortedYears.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => BooksByYearScreen(initialYear: sortedYears.first.key),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Books Read Per Year',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
              if (sortedYears == null || sortedYears.isEmpty)
                Center(child: Text(AppLocalizations.of(context)!.no_data))
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      sortedYears.map((entry) {
                        final maxValue = sortedYears
                            .map((e) => e.value)
                            .reduce((a, b) => a > b ? a : b);
                        final percentage = (entry.value / maxValue).clamp(
                          0.0,
                          1.0,
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => BooksByYearScreen(
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${entry.key}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
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
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            Container(
                                              width:
                                                  constraints.maxWidth *
                                                  percentage,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            Container(
                                              height: 24,
                                              padding:
                                                  const EdgeInsets.symmetric(
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Pages Read Per Year — horizontal fill-bar chart
class _PagesReadPerYearCard extends StatelessWidget {
  final Map<int, int>? pagesReadPerYear;
  const _PagesReadPerYearCard({this.pagesReadPerYear});

  @override
  Widget build(BuildContext context) {
    final sortedYears =
        pagesReadPerYear?.entries.toList()
          ?..sort((a, b) => b.key.compareTo(a.key));
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Pages Read Per Year',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (sortedYears == null || sortedYears.isEmpty)
              Center(child: Text(AppLocalizations.of(context)!.no_data))
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    sortedYears.map((entry) {
                      final maxValue = sortedYears
                          .map((e) => e.value)
                          .reduce((a, b) => a > b ? a : b);
                      final percentage = (entry.value / maxValue).clamp(
                        0.0,
                        1.0,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 60,
                              child: Text(
                                '${entry.key}',
                                style: Theme.of(context).textTheme.bodySmall,
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width:
                                            constraints.maxWidth * percentage,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(
                                            4,
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
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Combined Reading Efficiency — velocity, avg days, avg books/year on one page
class _ReadingEfficiencyCard extends StatelessWidget {
  final double readingVelocity;
  final double averageDaysToFinish;
  final double averageBooksPerYear;
  final int booksUsedInAverageDays;
  final int yearsWithBooks;

  const _ReadingEfficiencyCard({
    required this.readingVelocity,
    required this.averageDaysToFinish,
    required this.averageBooksPerYear,
    required this.booksUsedInAverageDays,
    required this.yearsWithBooks,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Reading Efficiency',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            // Reading Velocity
            if (readingVelocity > 0) ...[
              _buildBigStat(
                context,
                icon: Icons.speed,
                value: readingVelocity.toStringAsFixed(1),
                unit: 'pages/day',
                subtitle:
                    'Based on $booksUsedInAverageDays books with reading data',
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 24),
            ],
            // Average Days to Finish
            if (averageDaysToFinish > 0) ...[
              _buildBigStat(
                context,
                icon: Icons.timer,
                value: averageDaysToFinish.toStringAsFixed(1),
                unit: 'days',
                subtitle: 'Average time to finish a book',
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 24),
            ],
            // Average Books Per Year
            if (averageBooksPerYear > 0)
              _buildBigStat(
                context,
                icon: Icons.trending_up,
                value: averageBooksPerYear.toStringAsFixed(1),
                unit: 'books/year',
                subtitle: 'Based on $yearsWithBooks years of reading data',
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigStat(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String unit,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                unit,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Status Donut — badge-style pie chart with %/# toggle
class _StatusDonutCard extends StatefulWidget {
  final Map<String, int> statusCounts;
  final int totalCount;
  const _StatusDonutCard({
    required this.statusCounts,
    required this.totalCount,
  });

  @override
  State<_StatusDonutCard> createState() => _StatusDonutCardState();
}

class _StatusDonutCardState extends State<_StatusDonutCard> {
  bool _showAsPercentage = false;
  static const _colors = [
    Colors.deepPurple,
    Colors.purple,
    Colors.purpleAccent,
    Colors.deepPurpleAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.books_by_status,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Text(
                      _showAsPercentage ? '%' : '#',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Switch(
                      value: _showAsPercentage,
                      onChanged: (v) => setState(() => _showAsPercentage = v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 230,
              child:
                  widget.statusCounts.isEmpty
                      ? Center(child: Text(l10n.no_data))
                      : PieChart(
                        PieChartData(
                          sections:
                              widget.statusCounts.entries.map((entry) {
                                final index = widget.statusCounts.keys
                                    .toList()
                                    .indexOf(entry.key);
                                return PieChartSectionData(
                                  value: entry.value.toDouble(),
                                  title: '',
                                  radius: 50,
                                  color: _colors[index % _colors.length],
                                  badgeWidget: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _colors[index % _colors.length],
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      _showAsPercentage
                                          ? '${((entry.value / widget.totalCount) * 100).toStringAsFixed(1)}%'
                                          : '${entry.value}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _colors[index % _colors.length],
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
                  widget.statusCounts.entries.map((entry) {
                    final index = widget.statusCounts.keys.toList().indexOf(
                      entry.key,
                    );
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _colors[index % _colors.length],
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
    );
  }
}

/// Format Donut — badge-style pie chart with current year / total toggle
class _FormatDonutCard extends StatefulWidget {
  final Map<String, int> formatCounts;
  final Map<String, int> formatCountsCurrentYear;
  const _FormatDonutCard({
    required this.formatCounts,
    required this.formatCountsCurrentYear,
  });

  @override
  State<_FormatDonutCard> createState() => _FormatDonutCardState();
}

class _FormatDonutCardState extends State<_FormatDonutCard> {
  bool _showCurrentYear = true;
  static const _colors = [
    Colors.green,
    Colors.lime,
    Colors.lightGreen,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataToShow =
        _showCurrentYear ? widget.formatCountsCurrentYear : widget.formatCounts;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.books_by_format,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showCurrentYear ? 'Current' : 'Total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 48,
                      child: Switch(
                        value: _showCurrentYear,
                        onChanged: (v) => setState(() => _showCurrentYear = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 230,
              child: Builder(
                builder: (context) {
                  return dataToShow.isEmpty
                      ? Center(child: Text(l10n.no_data))
                      : PieChart(
                        PieChartData(
                          sections:
                              dataToShow.entries.map((entry) {
                                final index = dataToShow.keys.toList().indexOf(
                                  entry.key,
                                );
                                return PieChartSectionData(
                                  value: entry.value.toDouble(),
                                  title: '',
                                  radius: 50,
                                  color: _colors[index % _colors.length],
                                  badgeWidget: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _colors[index % _colors.length],
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      '${entry.value}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _colors[index % _colors.length],
                                      ),
                                    ),
                                  ),
                                  badgePositionPercentageOffset: 1.4,
                                );
                              }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 45,
                        ),
                      );
                },
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children:
                  dataToShow.entries.map((entry) {
                    final index = dataToShow.keys.toList().indexOf(entry.key);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _colors[index % _colors.length],
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
    );
  }
}

/// Place Donut — badge-style pie chart with %/# toggle
class _PlaceDonutCard extends StatefulWidget {
  final Map<String, int> placeCounts;
  const _PlaceDonutCard({required this.placeCounts});

  @override
  State<_PlaceDonutCard> createState() => _PlaceDonutCardState();
}

class _PlaceDonutCardState extends State<_PlaceDonutCard> {
  bool _showAsPercentage = false;
  static const _colors = [
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Books by Place',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Text(
                      _showAsPercentage ? '%' : '#',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Switch(
                      value: _showAsPercentage,
                      onChanged: (v) => setState(() => _showAsPercentage = v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 230,
              child:
                  widget.placeCounts.isEmpty
                      ? Center(child: Text(l10n.no_data))
                      : PieChart(
                        PieChartData(
                          sections:
                              widget.placeCounts.entries.map((entry) {
                                final index = widget.placeCounts.keys
                                    .toList()
                                    .indexOf(entry.key);
                                final percentage =
                                    (entry.value /
                                        widget.placeCounts.values.reduce(
                                          (a, b) => a + b,
                                        )) *
                                    100;
                                return PieChartSectionData(
                                  value: entry.value.toDouble(),
                                  title: '',
                                  radius: 50,
                                  color: _colors[index % _colors.length],
                                  badgeWidget: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _colors[index % _colors.length],
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      _showAsPercentage
                                          ? '${percentage.toStringAsFixed(1)}%'
                                          : '${entry.value}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _colors[index % _colors.length],
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
                  widget.placeCounts.entries.map((entry) {
                    final index = widget.placeCounts.keys.toList().indexOf(
                      entry.key,
                    );
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _colors[index % _colors.length],
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
    );
  }
}

/// Language — horizontal fill-bar chart
class _LanguageBarCard extends StatelessWidget {
  final Map<String, int> languageCounts;
  const _LanguageBarCard({required this.languageCounts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted =
        languageCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              l10n.books_by_language,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (sorted.isEmpty)
              Center(child: Text(l10n.no_data))
            else
              ...sorted.map((entry) {
                final maxValue = sorted.first.value;
                final percentage = entry.value / maxValue;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
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
                                  color: Colors.deepPurple,
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
    );
  }
}

/// Format by Language — colored heatmap grid
class _FormatByLanguageCard extends StatelessWidget {
  final Map<String, Map<String, int>> formatByLanguageCounts;
  const _FormatByLanguageCard({required this.formatByLanguageCounts});

  @override
  Widget build(BuildContext context) {
    if (formatByLanguageCounts.isEmpty) return const SizedBox.shrink();

    final Set<String> allLanguages = {};
    for (var formatEntry in formatByLanguageCounts.entries) {
      allLanguages.addAll(formatEntry.value.keys);
    }
    final sortedLanguages = allLanguages.toList()..sort();
    final sortedFormats = formatByLanguageCounts.keys.toList()..sort();

    int maxCount = 0;
    for (var formatMap in formatByLanguageCounts.values) {
      for (var count in formatMap.values) {
        if (count > maxCount) maxCount = count;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 80;
    final labelWidth = 80.0;
    final cellWidth =
        (availableWidth - labelWidth) / (sortedLanguages.length + 1);
    final cellHeight = 50.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              'Format by Language',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      SizedBox(width: labelWidth),
                      ...sortedLanguages.map(
                        (language) => Container(
                          width: cellWidth,
                          height: cellHeight,
                          alignment: Alignment.center,
                          child: Text(
                            language,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...sortedFormats.map(
                    (format) => Row(
                      children: [
                        Container(
                          width: labelWidth,
                          height: cellHeight,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            format,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...sortedLanguages.map((language) {
                          final count =
                              formatByLanguageCounts[format]?[language] ?? 0;
                          final intensity =
                              maxCount > 0 ? count / maxCount : 0.0;
                          final baseColor =
                              Theme.of(context).colorScheme.primary;
                          final cellColor =
                              count == 0
                                  ? Colors.grey.shade200
                                  : Color.lerp(
                                    baseColor.withOpacity(0.2),
                                    baseColor,
                                    intensity,
                                  )!;
                          return Container(
                            width: cellWidth,
                            height: cellHeight,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 0.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              count > 0 ? '$count' : '',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    intensity > 0.5
                                        ? Colors.white
                                        : Colors.black87,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Low', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                ...List.generate(5, (index) {
                  final intensity = (index + 1) / 5;
                  final baseColor = Theme.of(context).colorScheme.primary;
                  return Container(
                    width: 30,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        baseColor.withOpacity(0.2),
                        baseColor,
                        intensity,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                Text('High', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Top Ranking — horizontal fill-bar chart with All/Read toggle
class _TopRankingCard extends StatefulWidget {
  final String title;
  final List<Book> books;
  final Color color;
  final String Function(Book) fieldExtractor;
  final int topN;
  const _TopRankingCard({
    required this.title,
    required this.books,
    required this.color,
    required this.fieldExtractor,
    this.topN = 10,
  });

  @override
  State<_TopRankingCard> createState() => _TopRankingCardState();
}

class _TopRankingCardState extends State<_TopRankingCard> {
  bool _showReadBooks = false;

  // Returns list of {name, count, avgRating}
  List<Map<String, dynamic>> _computeEntries() {
    final Map<String, int> counts = {};
    final Map<String, double> ratingTotals = {};
    final Map<String, int> ratingCounts = {};
    for (var book in widget.books) {
      final isRead = book.readCount != null && book.readCount! > 0;
      if (_showReadBooks && !isRead) continue;
      final value = widget.fieldExtractor(book);
      if (value.isNotEmpty) {
        final multiplier =
            (book.isBundle == true &&
                    book.bundleCount != null &&
                    book.bundleCount! > 0)
                ? book.bundleCount!
                : 1;
        counts[value] = (counts[value] ?? 0) + multiplier;
        if (book.myRating != null && book.myRating! > 0) {
          ratingTotals[value] = (ratingTotals[value] ?? 0) + book.myRating!;
          ratingCounts[value] = (ratingCounts[value] ?? 0) + 1;
        }
      }
    }
    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(widget.topN).map((entry) {
      final avgRating =
          ratingCounts.containsKey(entry.key)
              ? ratingTotals[entry.key]! / ratingCounts[entry.key]!
              : 0.0;
      return {'name': entry.key, 'count': entry.value, 'avgRating': avgRating};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _computeEntries();
    final maxValue = entries.isNotEmpty ? entries.first['count'] as int : 1;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Column(
              children: [
                Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('All', style: Theme.of(context).textTheme.bodySmall),
                    Switch(
                      value: _showReadBooks,
                      onChanged: (val) {
                        setState(() {
                          _showReadBooks = val;
                        });
                      },
                    ),
                    Text('Read', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Center(child: Text(AppLocalizations.of(context)!.no_data))
            else
              ...entries.map((entry) {
                final count = entry['count'] as int;
                final name = entry['name'] as String;
                final avgRating = entry['avgRating'] as double;
                final percentage = count / maxValue;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (avgRating > 0)
                              Text(
                                '★ ${avgRating.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
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
                                  color: widget.color,
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
                                '$count',
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
    );
  }
}

// === Price Statistics Cards ===

/// Price by Format — horizontal bar chart showing avg price per format
class _PriceByFormatCard extends StatelessWidget {
  final Map<String, double> avgPriceByFormat;
  final Map<String, int> countByFormat;
  final String currencySymbol;
  const _PriceByFormatCard({
    required this.avgPriceByFormat,
    required this.countByFormat,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (avgPriceByFormat.isEmpty) return const SizedBox.shrink();
    final sorted =
        avgPriceByFormat.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final maxPrice = sorted.first.value;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.price_by_format,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...sorted.map((entry) {
              final percentage = maxPrice > 0 ? entry.value / maxPrice : 0.0;
              final count = countByFormat[entry.key] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$count books',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
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
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$currencySymbol${entry.value.toStringAsFixed(2)}',
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
    );
  }
}

/// Price by Year — horizontal bar chart
class _PriceByYearCard extends StatelessWidget {
  final Map<int, double> totalSpentByYear;
  final Map<int, double> avgPriceByYear;
  final String currencySymbol;
  const _PriceByYearCard({
    required this.totalSpentByYear,
    required this.avgPriceByYear,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSpentByYear.isEmpty) return const SizedBox.shrink();
    final sortedYears = totalSpentByYear.keys.toList()..sort();
    final maxVal = totalSpentByYear.values.reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.price_by_year,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...sortedYears.map((year) {
              final total = totalSpentByYear[year] ?? 0;
              final avg = avgPriceByYear[year] ?? 0;
              final percentage = maxVal > 0 ? total / maxVal : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$year',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
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
                                color: Colors.teal,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$currencySymbol${total.toStringAsFixed(0)}',
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
    );
  }
}

/// Price by Month — horizontal bar chart for a selected year
class _PriceByMonthCard extends StatefulWidget {
  final Map<int, Map<int, double>> totalSpentByMonth;
  final String currencySymbol;
  const _PriceByMonthCard({
    required this.totalSpentByMonth,
    required this.currencySymbol,
  });

  @override
  State<_PriceByMonthCard> createState() => _PriceByMonthCardState();
}

class _PriceByMonthCardState extends State<_PriceByMonthCard> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    if (widget.totalSpentByMonth.isNotEmpty) {
      final years =
          widget.totalSpentByMonth.keys.toList()
            ..sort((a, b) => b.compareTo(a));
      _selectedYear = years.first;
    } else {
      _selectedYear = DateTime.now().year;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalSpentByMonth.isEmpty) return const SizedBox.shrink();
    final sortedYears =
        widget.totalSpentByMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    final monthData = widget.totalSpentByMonth[_selectedYear] ?? {};
    final maxVal =
        monthData.values.isEmpty
            ? 1.0
            : monthData.values.reduce((a, b) => a > b ? a : b);
    final monthAbbrs = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.price_by_month,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items:
                        sortedYears.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(
                              '$year',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }).toList(),
                    onChanged: (year) {
                      if (year != null) setState(() => _selectedYear = year);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(12, (index) {
              final month = index + 1;
              final total = monthData[month] ?? 0.0;
              final percentage = maxVal > 0 ? total / maxVal : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        monthAbbrs[index],
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          if (total > 0)
                            FractionallySizedBox(
                              widthFactor: percentage,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          Container(
                            height: 20,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              total > 0
                                  ? '${widget.currencySymbol}${total.toStringAsFixed(0)}'
                                  : '',
                              style: TextStyle(
                                color:
                                    percentage > 0.15
                                        ? Colors.white
                                        : Colors.black87,
                                fontSize: 10,
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
    );
  }
}

/// Most / Least Expensive book card
class _MostLeastExpensiveCard extends StatelessWidget {
  final String? mostExpensiveName;
  final double? mostExpensivePrice;
  final String? leastExpensiveName;
  final double? leastExpensivePrice;
  final double totalSpent;
  final String currencySymbol;
  const _MostLeastExpensiveCard({
    this.mostExpensiveName,
    this.mostExpensivePrice,
    this.leastExpensiveName,
    this.leastExpensivePrice,
    required this.totalSpent,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.price_extremes,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            // Total spent
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.teal,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.total_spent,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '$currencySymbol${totalSpent.toStringAsFixed(2)}',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Most expensive
            if (mostExpensiveName != null) ...[
              ListTile(
                leading: const Icon(Icons.arrow_upward, color: Colors.red),
                title: Text(
                  mostExpensiveName!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(AppLocalizations.of(context)!.most_expensive),
                trailing: Text(
                  '$currencySymbol${mostExpensivePrice?.toStringAsFixed(2) ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
            // Least expensive
            if (leastExpensiveName != null) ...[
              ListTile(
                leading: const Icon(Icons.arrow_downward, color: Colors.green),
                title: Text(
                  leastExpensiveName!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(AppLocalizations.of(context)!.least_expensive),
                trailing: Text(
                  '$currencySymbol${leastExpensivePrice?.toStringAsFixed(2) ?? ''}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Price Range Evolution — line chart showing avg, min, max price over years
class _PriceRangeEvolutionCard extends StatelessWidget {
  final Map<int, double> avgPriceByYear;
  final Map<int, double> minPriceByYear;
  final Map<int, double> maxPriceByYear;
  final String currencySymbol;
  const _PriceRangeEvolutionCard({
    required this.avgPriceByYear,
    required this.minPriceByYear,
    required this.maxPriceByYear,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (avgPriceByYear.isEmpty) return const SizedBox.shrink();
    final sortedYears = avgPriceByYear.keys.toList()..sort();

    // Compute global max for Y axis
    double globalMax = 0;
    for (var year in sortedYears) {
      final maxP = maxPriceByYear[year] ?? 0;
      if (maxP > globalMax) globalMax = maxP;
    }
    globalMax = globalMax * 1.15;
    if (globalMax == 0) globalMax = 10;

    // Build spots
    final avgSpots = <FlSpot>[];
    final minSpots = <FlSpot>[];
    final maxSpots = <FlSpot>[];
    for (int i = 0; i < sortedYears.length; i++) {
      final year = sortedYears[i];
      avgSpots.add(FlSpot(i.toDouble(), avgPriceByYear[year] ?? 0));
      minSpots.add(FlSpot(i.toDouble(), minPriceByYear[year] ?? 0));
      maxSpots.add(FlSpot(i.toDouble(), maxPriceByYear[year] ?? 0));
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.price_range_evolution,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.red, 'Max'),
                const SizedBox(width: 12),
                _legendDot(Colors.teal, 'Avg'),
                const SizedBox(width: 12),
                _legendDot(Colors.blue, 'Min'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: globalMax,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedYears.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${sortedYears[index]}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '$currencySymbol${value.toInt()}',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: globalMax / 4,
                    getDrawingHorizontalLine:
                        (value) =>
                            FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          String label;
                          if (spot.barIndex == 0) {
                            label = 'Max';
                          } else if (spot.barIndex == 1) {
                            label = 'Avg';
                          } else {
                            label = 'Min';
                          }
                          return LineTooltipItem(
                            '$label: $currencySymbol${spot.y.toStringAsFixed(1)}',
                            TextStyle(
                              color: spot.bar.color ?? Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    // Max line
                    LineChartBarData(
                      spots: maxSpots,
                      isCurved: true,
                      color: Colors.red.withOpacity(0.7),
                      barWidth: 2,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Avg line
                    LineChartBarData(
                      spots: avgSpots,
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withOpacity(0.1),
                      ),
                    ),
                    // Min line
                    LineChartBarData(
                      spots: minSpots,
                      isCurved: true,
                      color: Colors.blue.withOpacity(0.7),
                      barWidth: 2,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// === Custom Painters ===

class LineChartPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  LineChartPainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    final width = size.width * percentage;
    final height = size.height;
    final centerY = height / 2;

    final backgroundPaint =
        Paint()
          ..color = Colors.grey[300]!
          ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      backgroundPaint,
    );

    final linePaint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), linePaint);

    final circlePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width, centerY), 5, circlePaint);

    final circleOutlinePaint =
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(Offset(width, centerY), 8, circleOutlinePaint);
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.color != color;
  }
}

class VerticalLineChartPainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  VerticalLineChartPainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);
    final height = size.height * (1 - percentage);
    final width = size.width;
    final centerX = width / 2;

    final backgroundPaint =
        Paint()
          ..color = Colors.grey[300]!
          ..strokeWidth = 2;
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      backgroundPaint,
    );

    final linePaint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, size.height),
      Offset(centerX, height),
      linePaint,
    );

    final circlePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, height), 5, circlePaint);

    final circleOutlinePaint =
        Paint()
          ..color = color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawCircle(Offset(centerX, height), 8, circleOutlinePaint);
  }

  @override
  bool shouldRepaint(VerticalLineChartPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.color != color;
  }
}
