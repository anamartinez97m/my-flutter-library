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
import 'package:myrandomlibrary/widgets/statistics/seasonal_preferences_card.dart';
import 'package:myrandomlibrary/widgets/statistics/monthly_heatmap_card.dart';
import 'package:myrandomlibrary/widgets/statistics/average_rating_card.dart';
import 'package:myrandomlibrary/widgets/statistics/book_extremes_card.dart';
import 'package:myrandomlibrary/widgets/statistics/reading_insights_card.dart';
import 'package:myrandomlibrary/widgets/statistics/reading_time_placeholder_card.dart';
import 'package:myrandomlibrary/widgets/statistics/reading_goals_card.dart';
import 'package:myrandomlibrary/widgets/statistics/quick_stats_row.dart';
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

  @override
  void initState() {
    super.initState();
    _loadYearData();
    _loadCompetitionData();
    _loadFormatSagaMapping();
  }

  void _triggerProviderDependentLoads() {
    if (!_hasTriggeredProviderLoads) {
      _hasTriggeredProviderLoads = true;
      _loadReadingSessionsData();
      _loadReadDatesData();
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
        topGenreBySeason: stats.topGenreBySeason,
      ),
      SeasonalReadingCard(
        seasonalReading: stats.seasonalReading,
        seasonalReadingPerYear: stats.seasonalReadingPerYear,
        yearsCount: stats.yearsCount,
      ),
      SeasonalPreferencesCard(seasonalReading: stats.seasonalReading),
    ];
  }

  List<Widget> _buildComingSoonCards(BuildContext context) {
    return [ReadingTimePlaceholderCard()];
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
      _SectionDef(
        title: l10n.section_coming_soon,
        icon: Icons.upcoming,
        onTap:
            () => _navigateToSection(
              context,
              l10n.section_coming_soon,
              Icons.upcoming,
              _buildComingSoonCards(context),
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

  List<MapEntry<String, int>> _computeEntries() {
    final Map<String, int> counts = {};
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
      }
    }
    return (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .take(widget.topN)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _computeEntries();

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
                final maxValue = entries.first.value;
                final percentage = entry.value / maxValue;
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
