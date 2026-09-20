import 'package:flutter/material.dart';
import 'package:myrandomlibrary/widgets/shimmer_loading.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/providers/book_provider.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/library_breakdown_screen.dart';
import 'package:myrandomlibrary/screens/price_statistics_screen.dart';
import 'package:myrandomlibrary/screens/ratings_pages_screen.dart';
import 'package:myrandomlibrary/screens/reading_activity_screen.dart';
import 'package:myrandomlibrary/screens/reading_patterns_screen.dart';
import 'package:myrandomlibrary/screens/sagas_series_screen.dart';
import 'package:myrandomlibrary/screens/top_rankings_screen.dart';
import 'package:myrandomlibrary/helpers/statistics_calculator.dart';

import 'package:myrandomlibrary/widgets/statistics/quick_stats_row.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myrandomlibrary/widgets/statistics/statistics_shimmer.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_competition_screen.dart';
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
    final provider = Provider.of<BookProvider?>(context, listen: false);
    try {
      final db = await DatabaseHelper.instance.database;
      final sessionRepository = ReadingSessionRepository(db);

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
    final provider = Provider.of<BookProvider?>(context, listen: false);
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);

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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookProvider?>(context);

    if (provider == null || provider.isLoading) {
      return const Scaffold(body: ShimmerLoading(child: StatisticsShimmer()));
    }

    // Trigger provider-dependent loads once provider is ready
    _triggerProviderDependentLoads();

    if (_isLoadingReadDates || _isLoadingSessions) {
      return const Scaffold(body: ShimmerLoading(child: StatisticsShimmer()));
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
        onTap: () {
          final currentStats = _computeCurrentStats(books);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ReadingActivityScreen(
                    booksReadPerYear: _booksReadPerYear,
                    pagesReadPerYear: _pagesReadPerYear,
                    monthlyHeatmap: currentStats.monthlyHeatmap,
                    dailyHeatmap: currentStats.dailyHeatmap,
                    readingVelocity: currentStats.readingVelocity,
                    averageDaysToFinish: currentStats.averageDaysToFinish,
                    averageBooksPerYear: currentStats.averageBooksPerYear,
                    booksUsedInAverageDays: currentStats.booksUsedInAverageDays,
                    yearsWithBooks: currentStats.yearsWithBooks,
                    readingEfficiencyPercentage:
                        currentStats.readingEfficiencyPercentage,
                    booksUsedInEfficiency: currentStats.booksUsedInEfficiency,
                    booksFasterThanAverage: currentStats.booksFasterThanAverage,
                    booksSlowerThanAverage: currentStats.booksSlowerThanAverage,
                    books: books,
                  ),
            ),
          );
        },
      ),
      _SectionDef(
        title: l10n.section_library_breakdown,
        icon: Icons.library_books,
        onTap: () {
          final currentStats = _computeCurrentStats(books);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => LibraryBreakdownScreen(
                    statusCounts: currentStats.statusCounts,
                    formatCounts: currentStats.formatCounts,
                    placeCounts: currentStats.placeCounts,
                    languageCounts: currentStats.languageCounts,
                    totalCount: currentStats.totalCount,
                    books: books,
                    formatByLanguageCounts: currentStats.formatByLanguageCounts,
                    avgDaysByFormatLanguage:
                        currentStats.avgDaysByFormatLanguage,
                  ),
            ),
          );
        },
      ),
      _SectionDef(
        title: l10n.section_top_rankings,
        icon: Icons.leaderboard,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TopRankingsScreen(books: books)),
          );
        },
      ),
      _SectionDef(
        title: l10n.section_ratings_pages,
        icon: Icons.star_half,
        onTap: () {
          final currentStats = _computeCurrentStats(books);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => RatingsPagesScreen(
                    averageRating: currentStats.averageRating,
                    ratedBooksCount: currentStats.ratedBooksCount,
                    ratingDistribution: currentStats.ratingDistribution,
                    pageDistribution: currentStats.pageDistribution,
                    oldestYear: currentStats.oldestYear,
                    oldestBookName: currentStats.oldestBookName,
                    newestYear: currentStats.newestYear,
                    newestBookName: currentStats.newestBookName,
                    shortestPages: currentStats.shortestPages,
                    shortestBookName: currentStats.shortestBookName,
                    longestPages: currentStats.longestPages,
                    longestBookName: currentStats.longestBookName,
                  ),
            ),
          );
        },
      ),
      _SectionDef(
        title: l10n.section_sagas_series,
        icon: Icons.collections_bookmark,
        onTap: () {
          final currentStats = _computeCurrentStats(books);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => SagasSeriesScreen(
                    sagaStats: currentStats.sagaStats,
                    completedSagas: currentStats.completedSagas,
                    partialSagas: currentStats.partialSagas,
                    unstartedSagas: currentStats.unstartedSagas,
                    books: books,
                  ),
            ),
          );
        },
      ),
      _SectionDef(
        title: l10n.section_reading_patterns,
        icon: Icons.insights,
        onTap: () {
          final currentStats = _computeCurrentStats(books);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ReadingPatternsScreen(
                    currentStreak: currentStats.currentStreak,
                    longestStreak: currentStats.longestStreak,
                    dnfCount: currentStats.dnfCount,
                    dnfRate: currentStats.dnfRate,
                    rereadCount: currentStats.rereadCount,
                    mostRereadBook: currentStats.mostRereadBook,
                    seriesBooks: currentStats.totalBooksInSeries,
                    standaloneBooks: currentStats.standaloneBooks,
                    seriesBooksRead: currentStats.totalBooksInSeriesRead,
                    standaloneBooksRead: currentStats.standaloneBooksRead,
                    seriesPercentage: currentStats.seriesPercentage,
                    seriesCount: currentStats.seriesCount,
                    mostBooksInMonth: currentStats.mostBooksInMonth,
                    bestMonth: currentStats.bestMonth,
                    fastestDays: currentStats.fastestDays,
                    fastestBookName: currentStats.fastestBookName,
                    nextMilestoneOwned: currentStats.nextMilestoneOwned,
                    booksToMilestoneOwned: currentStats.booksToMilestoneOwned,
                    nextMilestoneRead: currentStats.nextMilestoneRead,
                    booksToMilestoneRead: currentStats.booksToMilestoneRead,
                    bingePercentage: currentStats.bingePercentage,
                    seasonalReading: currentStats.seasonalReading,
                    seasonalReadingPerYear: currentStats.seasonalReadingPerYear,
                    yearsCount: currentStats.yearsCount,
                    topGenreBySeason: currentStats.topGenreBySeason,
                    readingTimeOfDay: currentStats.readingTimeOfDay,
                  ),
            ),
          );
        },
      ),
      if (_showPriceStatistics)
        _SectionDef(
          title: l10n.section_price_statistics,
          icon: Icons.attach_money,
          onTap: () {
            final currentStats = _computeCurrentStats(books);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => PriceStatisticsScreen(
                      priceStats: currentStats.priceStats,
                      currencySymbol: _currencySymbol,
                    ),
              ),
            );
          },
        ),
    ];

    return _buildV2Scaffold(
      context,
      stats,
      latestBookName,
      sections,
      currentYear,
      l10n,
    );
  }

  Widget _buildV2Scaffold(
    BuildContext context,
    StatisticsData stats,
    String? latestBookName,
    List<_SectionDef> sections,
    int currentYear,
    AppLocalizations l10n,
  ) {
    const kBg = Color(0xFFFDF8F6);
    const kPrimary = Color(0xFF43102B);
    const kSub = Color(0xFF514348);
    const kText = Color(0xFF1C1B1A);
    const kBadgeBg = Color(0xFFF2EDEB);
    const kBadgeBorder = Color(0xFFD5C2C7);

    BoxDecoration cardDeco({double radius = 12}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0x1A27231E)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 6,
          offset: Offset(0, 4),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: 25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bento cards
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 46,
                      ),
                      decoration: cardDeco(radius: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.library_books,
                            size: 30,
                            color: kPrimary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.total_books,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kSub,
                              letterSpacing: 0.26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${stats.totalCount}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: cardDeco(radius: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.new_releases,
                            size: 32,
                            color: kPrimary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.latest_book_added,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kSub,
                              letterSpacing: 0.26,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            latestBookName != null && latestBookName.isNotEmpty
                                ? latestBookName
                                : l10n.no_books_in_database,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Competition card
            if (!_isLoadingCompetition)
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => NewBookCompetitionScreen(year: currentYear),
                    ),
                  );
                  _loadCompetitionData();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: cardDeco(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: kPrimary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.best_book_of_year(currentYear.toString()),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: kSub,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_yearlyWinner != null) ...[
                        Text(
                          '${l10n.winner}:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kSub,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: kBadgeBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBadgeBorder),
                          ),
                          child: Text(
                            _yearlyWinner!.bookName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else if (_nominees.isNotEmpty) ...[
                        Text(
                          '${l10n.nominees}:',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kSub,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children:
                              _nominees
                                  .take(6)
                                  .map(
                                    (n) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kBadgeBg,
                                        borderRadius: BorderRadius.circular(
                                          9999,
                                        ),
                                        border: Border.all(color: kBadgeBorder),
                                      ),
                                      child: Text(
                                        n.bookName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: kPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        if (_nominees.length > 6)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '... ${l10n.and_n_more((_nominees.length - 6).toString())}',
                              style: const TextStyle(fontSize: 12, color: kSub),
                            ),
                          ),
                      ] else
                        Text(
                          l10n.no_books_read_in_year(currentYear.toString()),
                          style: const TextStyle(fontSize: 13, color: kSub),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Quick Stats
            QuickStatsRow(data: stats, useNewUi: true),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.quick_stat_long_press_hint,
                style: const TextStyle(fontSize: 12, color: kSub),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Section nav cards
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: section.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(17),
                    decoration: cardDeco(),
                    child: Row(
                      children: [
                        Icon(section.icon, color: kPrimary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section.title,
                            style: const TextStyle(fontSize: 16, color: kText),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: kSub,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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

/// Unified Breakdown — dropdown to pick field, donut with %, legend with counts
class _UnifiedBreakdownCard extends StatefulWidget {
  final Map<String, int> statusCounts;
  final Map<String, int> formatCounts;
  final Map<String, int> placeCounts;
  final Map<String, int> languageCounts;
  final int totalCount;
  final List<Book> books;

  const _UnifiedBreakdownCard({
    required this.statusCounts,
    required this.formatCounts,
    required this.placeCounts,
    required this.languageCounts,
    required this.totalCount,
    required this.books,
  });

  @override
  State<_UnifiedBreakdownCard> createState() => _UnifiedBreakdownCardState();
}

class _UnifiedBreakdownCardState extends State<_UnifiedBreakdownCard> {
  String _selectedField = 'status';

  List<Color> _getPaletteColors(BuildContext context, String field) {
    final cs = Theme.of(context).colorScheme;
    switch (field) {
      case 'format':
        return [cs.tertiary, cs.secondary, cs.primary, cs.tertiaryContainer];
      case 'place':
        return [cs.primary, cs.secondary, cs.tertiary, cs.secondaryContainer];
      case 'language':
        return [cs.secondary, cs.primary, cs.tertiary, cs.primaryContainer];
      case 'genre':
        return [cs.error, cs.secondary, cs.tertiary, cs.primary];
      default:
        return [cs.primary, cs.secondary, cs.tertiary, cs.error];
    }
  }

  Map<String, int> _getDataForField() {
    switch (_selectedField) {
      case 'status':
        return widget.statusCounts;
      case 'format':
        return widget.formatCounts;
      case 'place':
        return widget.placeCounts;
      case 'language':
        return widget.languageCounts;
      case 'genre':
        return _computeGenreCounts();
      default:
        return widget.statusCounts;
    }
  }

  Map<String, int> _computeGenreCounts() {
    final Map<String, int> counts = {};
    for (var book in widget.books) {
      final raw = book.genre ?? '';
      if (raw.isEmpty) continue;
      final multiplier =
          (book.isBundle == true &&
                  book.bundleCount != null &&
                  book.bundleCount! > 0)
              ? book.bundleCount!
              : 1;
      final genres = raw
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty);
      for (final genre in genres) {
        counts[genre] = (counts[genre] ?? 0) + multiplier;
      }
    }
    final sorted =
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  String _fieldLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'status':
        return l10n.books_by_status;
      case 'format':
        return l10n.books_by_format;
      case 'place':
        return l10n.books_by_place;
      case 'language':
        return l10n.books_by_language;
      case 'genre':
        return l10n.books_by_genre;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _getDataForField();
    final total = data.values.fold<int>(0, (sum, v) => sum + v);
    final colors = _getPaletteColors(context, _selectedField);

    final fieldOptions = ['status', 'format', 'place', 'language', 'genre'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              l10n.library_overview,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Dropdown
            DropdownButton<String>(
              value: _selectedField,
              isExpanded: true,
              underline: Container(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              items:
                  fieldOptions.map((key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(_fieldLabel(key, l10n)),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedField = value);
              },
            ),
            const SizedBox(height: 20),
            // Donut chart with percentage badges
            SizedBox(
              height: 230,
              child:
                  data.isEmpty
                      ? Center(child: Text(l10n.no_data))
                      : PieChart(
                        PieChartData(
                          sections:
                              data.entries.map((entry) {
                                final index = data.keys.toList().indexOf(
                                  entry.key,
                                );
                                final pct =
                                    total > 0
                                        ? (entry.value / total) * 100
                                        : 0.0;
                                final showBadge = pct >= 2.5;
                                return PieChartSectionData(
                                  value: entry.value.toDouble(),
                                  title: '',
                                  radius: 50,
                                  color: colors[index % colors.length],
                                  badgeWidget:
                                      showBadge
                                          ? Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.surface,
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
                                              '${pct.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    colors[index %
                                                        colors.length],
                                              ),
                                            ),
                                          )
                                          : const SizedBox.shrink(),
                                  badgePositionPercentageOffset: 1.4,
                                );
                              }).toList(),
                          sectionsSpace: 2,
                          centerSpaceRadius: 45,
                        ),
                      ),
            ),
            const SizedBox(height: 16),
            // Vertical legend with counts
            if (data.isNotEmpty)
              Column(
                children:
                    data.entries.map((entry) {
                      final index = data.keys.toList().indexOf(entry.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: Theme.of(context).textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
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
