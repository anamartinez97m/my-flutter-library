import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/repositories/year_challenge_repository.dart';
import 'package:myrandomlibrary/screens/books_by_decade.dart';
import 'package:myrandomlibrary/screens/books_by_year.dart';
import 'package:myrandomlibrary/screens/year_challenges.dart';

/// New "Reading Activity" statistics screen matching the redesigned UI.
///
/// Preserves the original content (books read per year, pages read per year,
/// monthly heatmap, daily heatmap, reading goals, reading efficiency,
/// books by decade) while adopting the v2 visual language. Each section is
/// collapsible.
class ReadingActivityScreen extends StatefulWidget {
  final Map<int, int>? booksReadPerYear;
  final Map<int, int>? pagesReadPerYear;
  final Map<int, Map<int, int>> monthlyHeatmap;
  final Map<int, Map<String, int>> dailyHeatmap;
  final double readingVelocity;
  final double averageDaysToFinish;
  final double averageBooksPerYear;
  final int booksUsedInAverageDays;
  final int yearsWithBooks;
  final List<Book> books;

  static const kBg = Color(0xFFFDF8F6);
  static const kPrimary = Color(0xFF43102B);
  static const kSecondary = Color(0xFF894B67);
  static const kTertiary = Color(0xFFBC92A6);
  static const kMuted = Color(0xFFD5C2C7);
  static const kText = Color(0xFF1C1B1A);
  static const kSub = Color(0xFF514348);
  static const kBorder = Color(0x4DD5C2C7);
  static const kDivider = Color(0xFFE6E2DF);
  static const kBarBg = Color(0xFFE6E2DF);

  const ReadingActivityScreen({
    super.key,
    required this.booksReadPerYear,
    required this.pagesReadPerYear,
    required this.monthlyHeatmap,
    required this.dailyHeatmap,
    required this.readingVelocity,
    required this.averageDaysToFinish,
    required this.averageBooksPerYear,
    required this.booksUsedInAverageDays,
    required this.yearsWithBooks,
    required this.books,
  });

  @override
  State<ReadingActivityScreen> createState() => _ReadingActivityScreenState();
}

class _ReadingActivityScreenState extends State<ReadingActivityScreen>
    with WidgetsBindingObserver {
  static const _kBg = ReadingActivityScreen.kBg;
  static const _kPrimary = ReadingActivityScreen.kPrimary;
  static const _kSecondary = ReadingActivityScreen.kSecondary;
  static const _kTertiary = ReadingActivityScreen.kTertiary;
  static const _kText = ReadingActivityScreen.kText;
  static const _kSub = ReadingActivityScreen.kSub;
  static const _kBorder = ReadingActivityScreen.kBorder;
  static const _kDivider = ReadingActivityScreen.kDivider;
  static const _kBarBg = ReadingActivityScreen.kBarBg;

  final Set<String> _collapsedSections = {};

  // Monthly heatmap year selection
  late int _monthlySelectedYear;

  // Daily heatmap year selection
  late int _dailySelectedYear;

  // Books by decade toggle
  bool _showReadBooks = false;

  // Reading goals data
  Map<String, dynamic>? _currentYearProgress;
  bool _isLoadingGoals = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMonthlyYear();
    _initializeDailyYear();
    _loadCurrentYearProgress();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCurrentYearProgress();
    }
  }

  void _initializeMonthlyYear() {
    if (widget.monthlyHeatmap.isNotEmpty) {
      final sortedYears =
          widget.monthlyHeatmap.keys.toList()..sort((a, b) => b.compareTo(a));
      _monthlySelectedYear = sortedYears.first;
    } else {
      _monthlySelectedYear = DateTime.now().year;
    }
  }

  void _initializeDailyYear() {
    if (widget.dailyHeatmap.isNotEmpty) {
      final sortedYears =
          widget.dailyHeatmap.keys.toList()..sort((a, b) => b.compareTo(a));
      _dailySelectedYear = sortedYears.first;
    } else {
      _dailySelectedYear = DateTime.now().year;
    }
  }

  Future<void> _loadCurrentYearProgress() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final repository = YearChallengeRepository(db);
      final currentYear = DateTime.now().year;

      final challenges = await repository.getAllChallenges();
      final currentChallenge =
          challenges.where((c) => c.year == currentYear).firstOrNull;

      if (currentChallenge != null) {
        final progress = await repository.getChallengeProgress(currentYear);
        if (mounted) {
          setState(() {
            _currentYearProgress = progress;
            _isLoadingGoals = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentYearProgress = null;
            _isLoadingGoals = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading current year progress: $e');
      if (mounted) {
        setState(() {
          _currentYearProgress = null;
          _isLoadingGoals = false;
        });
      }
    }
  }

  void _toggleSection(String key) {
    setState(() {
      if (_collapsedSections.contains(key)) {
        _collapsedSections.remove(key);
      } else {
        _collapsedSections.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.section_reading_activity,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFD5C2C7)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Books Read Per Year
            _buildCollapsibleCard(
              sectionKey: 'books_per_year',
              title: l10n.books_read_per_year,
              child: _buildBooksReadPerYearContent(context, l10n),
            ),
            const SizedBox(height: 16),
            // Pages Read Per Year
            _buildCollapsibleCard(
              sectionKey: 'pages_per_year',
              title: l10n.pages_read_per_year,
              child: _buildPagesReadPerYearContent(context, l10n),
            ),
            const SizedBox(height: 16),
            // Monthly Reading Heatmap
            _buildCollapsibleCard(
              sectionKey: 'monthly_heatmap',
              title: l10n.monthly_reading_heatmap,
              child: _buildMonthlyHeatmapContent(context, l10n),
            ),
            const SizedBox(height: 16),
            // Daily Reading Heatmap
            if (widget.dailyHeatmap.isNotEmpty)
              _buildCollapsibleCard(
                sectionKey: 'daily_heatmap',
                title: l10n.daily_reading_heatmap,
                child: _buildDailyHeatmapContent(context, l10n),
              ),
            if (widget.dailyHeatmap.isNotEmpty) const SizedBox(height: 16),
            // Reading Goals
            _buildCollapsibleCard(
              sectionKey: 'reading_goals',
              title: l10n.reading_goals,
              child: _buildReadingGoalsContent(context, l10n),
            ),
            const SizedBox(height: 16),
            // Reading Efficiency
            _buildCollapsibleCard(
              sectionKey: 'reading_efficiency',
              title: l10n.reading_efficiency,
              child: _buildReadingEfficiencyContent(context, l10n),
            ),
            const SizedBox(height: 16),
            // Books by Decade
            _buildCollapsibleCard(
              sectionKey: 'books_by_decade',
              title: l10n.books_by_decade,
              child: _buildBooksByDecadeContent(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Collapsible card shell ───────────────────────────────────────

  Widget _buildCollapsibleCard({
    required String sectionKey,
    required String title,
    required Widget child,
  }) {
    final isCollapsed = _collapsedSections.contains(sectionKey);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection(sectionKey),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isCollapsed ? -0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more, color: _kPrimary),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child:
                isCollapsed
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: child,
                    ),
          ),
        ],
      ),
    );
  }

  // ─── Books Read Per Year ──────────────────────────────────────────

  Widget _buildBooksReadPerYearContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final sortedYears =
        widget.booksReadPerYear?.entries.toList()
          ?..sort((a, b) => b.key.compareTo(a.key));

    if (sortedYears == null || sortedYears.isEmpty) {
      return _buildNoData(l10n);
    }

    final maxValue = sortedYears
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        ...sortedYears.map((entry) {
          final percentage =
              maxValue > 0 ? (entry.value / maxValue).clamp(0.0, 1.0) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BooksByYearScreen(initialYear: entry.key),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${entry.key}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSub,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBar(
                      percentage: percentage,
                      value: '${entry.value}',
                      barColor: _kSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        BooksByYearScreen(initialYear: sortedYears.first.key),
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'View more',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: _kPrimary, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Pages Read Per Year ──────────────────────────────────────────

  Widget _buildPagesReadPerYearContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final sortedYears =
        widget.pagesReadPerYear?.entries.toList()
          ?..sort((a, b) => b.key.compareTo(a.key));

    if (sortedYears == null || sortedYears.isEmpty) {
      return _buildNoData(l10n);
    }

    final maxValue = sortedYears
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children:
          sortedYears.map((entry) {
            final percentage =
                maxValue > 0 ? (entry.value / maxValue).clamp(0.0, 1.0) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${entry.key}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kSub,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildBar(
                      percentage: percentage,
                      value: '${entry.value}',
                      barColor: _kTertiary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  // ─── Monthly Heatmap ──────────────────────────────────────────────

  Widget _buildMonthlyHeatmapContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    if (widget.monthlyHeatmap.isEmpty) {
      return _buildNoData(l10n);
    }

    final sortedYears =
        widget.monthlyHeatmap.keys.toList()..sort((a, b) => b.compareTo(a));
    final yearData = widget.monthlyHeatmap[_monthlySelectedYear] ?? {};

    int maxCount = 0;
    for (var count in yearData.values) {
      if (count > maxCount) maxCount = count;
    }
    if (maxCount == 0) maxCount = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year selector & subtitle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.books_finished_per_month,
              style: const TextStyle(fontSize: 13, color: _kSub),
            ),
            _buildYearDropdown(
              sortedYears,
              _monthlySelectedYear,
              (year) => setState(() => _monthlySelectedYear = year),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.less, style: const TextStyle(fontSize: 11, color: _kSub)),
            const SizedBox(width: 4),
            ...List.generate(5, (index) {
              final intensity = (index + 1) * 0.2;
              final color =
                  Color.lerp(
                    _kSecondary.withValues(alpha: 0.3),
                    _kPrimary,
                    intensity,
                  )!;
              return Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
            const SizedBox(width: 4),
            Text(l10n.more, style: const TextStyle(fontSize: 11, color: _kSub)),
          ],
        ),
        const SizedBox(height: 16),
        // 3x4 grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 2.2,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final count = yearData[month] ?? 0;
            final intensity =
                maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;
            final cellColor =
                count == 0
                    ? _kBarBg
                    : Color.lerp(
                      _kSecondary.withValues(alpha: 0.3),
                      _kPrimary,
                      intensity,
                    )!;

            return Tooltip(
              message:
                  '${_getMonthAbbr(month)} $_monthlySelectedYear: $count books',
              child: Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _kBorder, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getMonthAbbr(month),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: intensity > 0.5 ? Colors.white : _kText,
                      ),
                    ),
                    if (count > 0)
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: intensity > 0.5 ? Colors.white : _kText,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── Daily Heatmap ────────────────────────────────────────────────

  Widget _buildDailyHeatmapContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final sortedYears =
        widget.dailyHeatmap.keys.toList()..sort((a, b) => b.compareTo(a));
    final yearData = widget.dailyHeatmap[_dailySelectedYear] ?? {};

    final daysRead = yearData.keys.length;
    final totalDaysInYear =
        DateTime(
          _dailySelectedYear + 1,
          1,
          1,
        ).difference(DateTime(_dailySelectedYear, 1, 1)).inDays;
    final percentage =
        totalDaysInYear > 0
            ? (daysRead / totalDaysInYear * 100).toStringAsFixed(1)
            : '0';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year selector & summary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.days_read_summary(
                  daysRead.toString(),
                  totalDaysInYear.toString(),
                  percentage,
                ),
                style: const TextStyle(fontSize: 13, color: _kSub),
              ),
            ),
            _buildYearDropdown(
              sortedYears,
              _dailySelectedYear,
              (year) => setState(() => _dailySelectedYear = year),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Grid: 12 month columns x 31 day rows
        LayoutBuilder(
          builder: (context, constraints) {
            const dayLabelWidth = 20.0;
            final availableWidth = constraints.maxWidth - dayLabelWidth;
            final cellSize = (availableWidth / 12 - 2).clamp(4.0, 14.0);
            const gap = 3.0;

            return Column(
              children: [
                // Month header row
                Row(
                  children: [
                    const SizedBox(width: dayLabelWidth),
                    ...List.generate(12, (monthIndex) {
                      return SizedBox(
                        width: cellSize + gap,
                        child: Center(
                          child: Text(
                            monthAbbrs[monthIndex],
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: _kSub,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                // 31 day rows
                ...List.generate(31, (dayIndex) {
                  final day = dayIndex + 1;
                  return Row(
                    children: [
                      SizedBox(
                        width: dayLabelWidth,
                        child: Text(
                          '$day',
                          style: const TextStyle(fontSize: 7, color: _kSub),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ...List.generate(12, (monthIndex) {
                        final month = monthIndex + 1;
                        final daysInMonth = DateUtils.getDaysInMonth(
                          _dailySelectedYear,
                          month,
                        );
                        if (day > daysInMonth) {
                          return SizedBox(
                            width: cellSize + gap,
                            height: cellSize + gap,
                          );
                        }
                        final dayKey =
                            '$_dailySelectedYear-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                        final didRead = yearData.containsKey(dayKey);
                        return Container(
                          width: cellSize,
                          height: cellSize,
                          margin: const EdgeInsets.all(gap / 2),
                          decoration: BoxDecoration(
                            color: didRead ? _kPrimary : _kBarBg,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  // ─── Reading Goals ────────────────────────────────────────────────

  Widget _buildReadingGoalsContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    if (_isLoadingGoals) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: _kPrimary),
        ),
      );
    }

    if (_currentYearProgress == null) {
      // No challenge set — show placeholder
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const YearChallengesScreen(),
            ),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Icon(
              Icons.flag,
              size: 40,
              color: _kSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.no_challenge_set_for_year(DateTime.now().year.toString()),
              style: const TextStyle(fontSize: 14, color: _kSub),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _kPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.create_challenge,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show current year progress
    final booksRead = _currentYearProgress!['booksRead'] ?? 0;
    final targetBooks = _currentYearProgress!['targetBooks'] ?? 0;
    final pagesRead = _currentYearProgress!['pagesRead'] ?? 0;
    final targetPages = _currentYearProgress!['targetPages'];
    final booksProgress =
        (_currentYearProgress!['booksProgress'] ?? 0.0) as double;
    final pagesProgress =
        (_currentYearProgress!['pagesProgress'] ?? 0.0) as double;

    final booksComplete = booksRead >= targetBooks;
    final pagesComplete = targetPages != null && pagesRead >= targetPages;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const YearChallengesScreen()),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag, color: _kSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${DateTime.now().year} ${l10n.reading_goals}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: _kPrimary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          // Books progress
          if (targetBooks > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.books_label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kSub,
                  ),
                ),
                Text(
                  '$booksRead / $targetBooks',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: booksComplete ? _kPrimary : _kText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: booksProgress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: _kBarBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  booksComplete ? _kPrimary : _kSecondary,
                ),
              ),
            ),
          ],
          // Pages progress
          if (targetPages != null && targetPages > 0) ...[
            if (targetBooks > 0) const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.pages_label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kSub,
                  ),
                ),
                Text(
                  '$pagesRead / $targetPages',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: pagesComplete ? _kPrimary : _kText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pagesProgress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: _kBarBg,
                valueColor: AlwaysStoppedAnimation<Color>(
                  pagesComplete ? _kPrimary : _kTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Reading Efficiency ───────────────────────────────────────────

  Widget _buildReadingEfficiencyContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final hasVelocity = widget.readingVelocity > 0;
    final hasAvgDays = widget.averageDaysToFinish > 0;
    final hasAvgBooks = widget.averageBooksPerYear > 0;

    if (!hasVelocity && !hasAvgDays && !hasAvgBooks) {
      return _buildNoData(l10n);
    }

    return Column(
      children: [
        if (hasVelocity)
          _buildEfficiencyStat(
            icon: Icons.speed,
            color: _kTertiary,
            value: widget.readingVelocity.toStringAsFixed(1),
            unit: l10n.pages_per_day,
            subtitle: l10n.based_on_books_with_data(
              widget.booksUsedInAverageDays,
            ),
          ),
        if (hasVelocity && hasAvgDays) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          const SizedBox(height: 16),
        ],
        if (hasAvgDays)
          _buildEfficiencyStat(
            icon: Icons.timer,
            color: _kTertiary,
            value: widget.averageDaysToFinish.toStringAsFixed(1),
            unit: l10n.days,
            subtitle: l10n.avg_time_to_finish,
          ),
        if (hasAvgDays && hasAvgBooks) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          const SizedBox(height: 16),
        ],
        if (hasAvgBooks)
          _buildEfficiencyStat(
            icon: Icons.trending_up,
            color: _kTertiary,
            value: widget.averageBooksPerYear.toStringAsFixed(1),
            unit: l10n.books_per_year,
            subtitle: l10n.based_on_years_of_data(widget.yearsWithBooks),
          ),
      ],
    );
  }

  Widget _buildEfficiencyStat({
    required IconData icon,
    required Color color,
    required String value,
    required String unit,
    required String subtitle,
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
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 36,
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
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: _kSub,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: _kSub),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Books by Decade ──────────────────────────────────────────────

  Widget _buildBooksByDecadeContent(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final sortedBooksByDecade = _computeSortedBooksByDecade();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All / Read toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.all_label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: !_showReadBooks ? _kPrimary : _kSub,
              ),
            ),
            Switch(
              value: _showReadBooks,
              activeThumbColor: _kPrimary,
              onChanged: (val) {
                setState(() {
                  _showReadBooks = val;
                });
              },
            ),
            Text(
              l10n.read_label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _showReadBooks ? _kPrimary : _kSub,
              ),
            ),
          ],
        ),
        Text(
          '(${l10n.based_on_publication_year})',
          style: const TextStyle(
            fontSize: 12,
            color: _kSub,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        if (sortedBooksByDecade.isEmpty)
          _buildNoData(l10n)
        else
          ...sortedBooksByDecade.map((entry) {
            final maxValue = sortedBooksByDecade
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b);
            final percentage =
                maxValue > 0 ? (entry.value / maxValue).clamp(0.0, 1.0) : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => BooksByDecadeScreen(
                            initialDecade: entry.key,
                            showReadOnly: _showReadBooks,
                          ),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kSub,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildBar(
                        percentage: percentage,
                        value: '${entry.value}',
                        barColor: _kSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        if (sortedBooksByDecade.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => BooksByDecadeScreen(
                        initialDecade: sortedBooksByDecade.first.key,
                        showReadOnly: _showReadBooks,
                      ),
                ),
              );
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View more',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: _kPrimary, size: 18),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<MapEntry<String, int>> _computeSortedBooksByDecade() {
    final Map<String, int> booksByDecade = {};
    for (var book in widget.books) {
      final isRead = book.readCount != null && book.readCount! > 0;
      final shouldInclude = _showReadBooks ? isRead : true;
      if (shouldInclude && book.originalPublicationYear != null) {
        int pubYear = book.originalPublicationYear!;
        if (pubYear > 9999) pubYear = pubYear ~/ 10000;
        final decade = (pubYear ~/ 10) * 10;
        final decadeLabel = '${decade}s';
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
    return booksByDecade.entries.toList()..sort((a, b) {
      final aD = int.parse(a.key.replaceAll('s', ''));
      final bD = int.parse(b.key.replaceAll('s', ''));
      return bD.compareTo(aD);
    });
  }

  // ─── Shared helpers ───────────────────────────────────────────────

  Widget _buildBar({
    required double percentage,
    required String value,
    required Color barColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barPixelWidth = constraints.maxWidth * percentage;
        final textColor = barPixelWidth >= 8 ? Colors.white : _kText;
        return Stack(
          children: [
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: _kBarBg,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYearDropdown(
    List<int> sortedYears,
    int selectedYear,
    ValueChanged<int> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: selectedYear,
        underline: const SizedBox.shrink(),
        isDense: true,
        dropdownColor: Colors.white,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 13,
          color: _kText,
        ),
        items:
            sortedYears.map((year) {
              return DropdownMenuItem<int>(value: year, child: Text('$year'));
            }).toList(),
        onChanged: (year) {
          if (year != null) onChanged(year);
        },
      ),
    );
  }

  Widget _buildNoData(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          l10n.no_data,
          style: const TextStyle(fontSize: 14, color: _kSub),
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const monthAbbrs = [
      '',
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
    return monthAbbrs[month];
  }
}
