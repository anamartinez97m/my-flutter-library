import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/screens/monthly_winner_selection_screen.dart';
import 'package:myrandomlibrary/screens/quarterly_winner_selection_screen.dart';
import 'package:myrandomlibrary/screens/semifinal_winner_selection_screen.dart';
import 'package:myrandomlibrary/screens/yearly_winner_selection_screen.dart';

class BookCompetitionScreen extends StatefulWidget {
  final int year;

  const BookCompetitionScreen({super.key, required this.year});

  @override
  State<BookCompetitionScreen> createState() => _BookCompetitionScreenState();
}

class _BookCompetitionScreenState extends State<BookCompetitionScreen> {
  CompetitionResult? competitionResult;
  bool isLoading = true;
  Map<int, List<Book>> monthBooksCache = {};

  @override
  void initState() {
    super.initState();
    _loadCompetitionData();
  }

  Future<void> _loadCompetitionData() async {
    setState(() => isLoading = true);

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookCompetitionRepository(db);

      // Load competition results
      final result = await repository.getCompetitionResults(widget.year);

      // Load books read per month for the current year
      final booksPerMonth = await repository.getBooksReadPerMonth(widget.year);

      if (mounted) {
        setState(() {
          competitionResult = result;
          monthBooksCache = booksPerMonth;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading competition data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool _canRunQuarterlyCompetition(int quarter) {
    final startMonth = (quarter - 1) * 3 + 1;
    final endMonth = quarter * 3;

    final monthlyWinnersInQuarter =
        competitionResult?.monthlyWinners
            .where((m) => m.month >= startMonth && m.month <= endMonth)
            .toList() ??
        [];

    final hasQuarterlyWinner =
        competitionResult?.quarterlyWinners.any((q) => q.quarter == quarter) ??
        false;

    return !hasQuarterlyWinner && monthlyWinnersInQuarter.length >= 2;
  }

  bool _canRunSemifinalCompetition(int roundNumber) {
    final requiredQuarters = roundNumber == 1 ? [1, 3] : [2, 4];

    final availableQuarterlyWinners =
        competitionResult?.quarterlyWinners
            .where((q) => requiredQuarters.contains(q.quarter))
            .toList() ??
        [];

    final hasSemifinalWinner =
        competitionResult?.semifinalWinners.any(
          (s) => s.roundNumber == roundNumber,
        ) ??
        false;

    return !hasSemifinalWinner && availableQuarterlyWinners.length >= 2;
  }

  Future<void> _runQuarterlyCompetition(int quarter) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuarterlyWinnerSelectionScreen(
              year: widget.year,
              quarter: quarter,
            ),
      ),
    );

    if (result == true) {
      // Reload competition data after selection
      await _loadCompetitionData();
    }
  }

  Future<void> _runSemifinalCompetition(int roundNumber) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => SemifinalWinnerSelectionScreen(
              year: widget.year,
              roundNumber: roundNumber,
            ),
      ),
    );

    if (result == true) {
      // Reload competition data after selection
      await _loadCompetitionData();
    }
  }

  Future<void> _runFinalCompetition() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => YearlyWinnerSelectionScreen(year: widget.year),
      ),
    );

    if (result == true) {
      // Reload competition data after selection
      await _loadCompetitionData();
    }
  }

  bool _canRunFinalCompetition() {
    final hasSemifinalWinners = competitionResult?.semifinalWinners.length == 2;
    final hasYearlyWinner = competitionResult?.yearlyWinner != null;
    return hasSemifinalWinners && !hasYearlyWinner;
  }

  bool _hasMonthPassed(int month) {
    final now = DateTime.now();
    final monthDate = DateTime(widget.year, month);
    return monthDate.isBefore(DateTime(now.year, now.month, now.day)) ||
        (monthDate.year == now.year && monthDate.month == now.month);
  }

  bool _hasBooksInMonth(int month) {
    final books = monthBooksCache[month];
    return books != null && books.isNotEmpty;
  }

  bool _isMonthDisabled(int month) {
    return _hasMonthPassed(month) && !_hasBooksInMonth(month);
  }

  bool _isCurrentMonth(int month) {
    final now = DateTime.now();
    return month == now.month && widget.year == now.year;
  }

  bool _isFutureMonth(int month) {
    final now = DateTime.now();
    final monthDate = DateTime(widget.year, month);
    return monthDate.isAfter(DateTime(now.year, now.month, now.day));
  }

  Future<void> _selectMonthlyWinner(int month) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                MonthlyWinnerSelectionScreen(year: widget.year, month: month),
      ),
    );

    if (result == true) {
      // Reload competition data after selection
      _loadCompetitionData();
    }
  }

  Future<void> _cleanup2025Data() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clean 2025 Competition Data'),
            content: const Text(
              'This will delete all quarterly, semifinal, and yearly winners for 2025, '
              'but keep the monthly winners. Are you sure?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clean'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        final repository = BookCompetitionRepository(db);

        await repository.cleanupYearData(2025);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2025 competition data cleaned')),
          );
          _loadCompetitionData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error cleaning data: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Best Book of ${widget.year}'),
        actions: [
          if (widget.year == 2025)
            IconButton(
              icon: const Icon(Icons.cleaning_services),
              onPressed: _cleanup2025Data,
              tooltip: 'Clean 2025 Competition Data',
            ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : competitionResult == null
              ? const Center(child: Text('No competition data available'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (competitionResult!.yearlyWinner != null)
                      _buildYearlyWinnerSection(),
                    const SizedBox(height: 24),
                    _buildTournamentTree(),
                    const SizedBox(height: 24),
                    _buildMonthlyWinnersSection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildYearlyWinnerSection() {
    final winner = competitionResult!.yearlyWinner!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Year Winner',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    winner.bookName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentTree() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tournament Tree',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildQuarterlySection(),
            const SizedBox(height: 20),
            _buildSemifinalsSection(),
            const SizedBox(height: 20),
            _buildFinalSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuarterlySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quarterly Winners',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildQuarterCard(1)),
                const SizedBox(width: 8),
                Expanded(child: _buildQuarterCard(2)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildQuarterCard(3)),
                const SizedBox(width: 8),
                Expanded(child: _buildQuarterCard(4)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuarterCard(int quarter) {
    final quarterlyWinner =
        competitionResult!.quarterlyWinners
            .where((q) => q.quarter == quarter)
            .firstOrNull;

    final canRunCompetition = _canRunQuarterlyCompetition(quarter);

    return InkWell(
      onTap:
          canRunCompetition || quarterlyWinner != null
              ? () => _runQuarterlyCompetition(quarter)
              : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 100, // Increased height for quarterly cards
        decoration: BoxDecoration(
          color:
              quarterlyWinner != null
                  ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.7)
                  : canRunCompetition
                  ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                quarterlyWinner != null
                    ? Theme.of(context).colorScheme.primary
                    : canRunCompetition
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Q$quarter',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (quarterlyWinner != null)
              Text(
                quarterlyWinner.winner.bookName,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else if (canRunCompetition)
              Icon(
                Icons.add_circle_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              )
            else
              Icon(Icons.help_outline, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSemifinalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semifinals',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSemifinalCard(1, 'Q1 vs Q3')),
            const SizedBox(width: 16),
            Expanded(child: _buildSemifinalCard(2, 'Q2 vs Q4')),
          ],
        ),
      ],
    );
  }

  Widget _buildSemifinalCard(int roundNumber, String matchup) {
    final semifinalWinner =
        competitionResult!.semifinalWinners
            .where((s) => s.roundNumber == roundNumber)
            .firstOrNull;

    final canRunCompetition = _canRunSemifinalCompetition(roundNumber);

    return InkWell(
      onTap:
          canRunCompetition || semifinalWinner != null
              ? () => _runSemifinalCompetition(roundNumber)
              : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 100, // Same height as quarterly cards
        decoration: BoxDecoration(
          color:
              semifinalWinner != null
                  ? Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.7)
                  : canRunCompetition
                  ? Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                semifinalWinner != null
                    ? Theme.of(context).colorScheme.secondary
                    : canRunCompetition
                    ? Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              matchup,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (semifinalWinner != null)
              Text(
                semifinalWinner.winner.bookName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else if (canRunCompetition)
              Icon(
                Icons.add_circle_outline,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              )
            else
              Icon(Icons.help_outline, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalSection() {
    final yearlyWinner = competitionResult!.yearlyWinner;
    final canRunCompetition = _canRunFinalCompetition();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap:
              canRunCompetition || yearlyWinner != null
                  ? () => _runFinalCompetition()
                  : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient:
                  yearlyWinner != null
                      ? LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.inversePrimary.withValues(alpha: 0.2),
                          Theme.of(
                            context,
                          ).colorScheme.inversePrimary.withValues(alpha: 0.1),
                        ],
                      )
                      : canRunCompetition
                      ? LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.inversePrimary.withValues(alpha: 0.1),
                          Theme.of(
                            context,
                          ).colorScheme.inversePrimary.withValues(alpha: 0.05),
                        ],
                      )
                      : null,
              color:
                  yearlyWinner == null && !canRunCompetition
                      ? Colors.grey.withValues(alpha: 0.1)
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    yearlyWinner != null
                        ? Theme.of(
                          context,
                        ).colorScheme.inversePrimary.withValues(alpha: 0.5)
                        : canRunCompetition
                        ? Theme.of(
                          context,
                        ).colorScheme.inversePrimary.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            child:
                yearlyWinner != null
                    ? Column(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          yearlyWinner.bookName,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                    : canRunCompetition
                    ? Icon(
                      Icons.add_circle_outline,
                      size: 32,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    )
                    : Icon(Icons.help_outline, size: 32, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyWinnersSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Winners',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final monthlyWinner =
                    competitionResult!.monthlyWinners
                        .where((m) => m.month == month)
                        .firstOrNull;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        monthlyWinner != null
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : _isMonthDisabled(month)
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          monthlyWinner != null
                              ? Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.3)
                              : _isMonthDisabled(month)
                              ? Colors.grey.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _selectMonthlyWinner(month),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getMonthName(month),
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color:
                                _isMonthDisabled(month)
                                    ? Colors.grey[600]
                                    : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        if (monthlyWinner != null)
                          Expanded(
                            child: Center(
                              child: Text(
                                monthlyWinner.winner.bookName,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(fontSize: 9),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                        else if (_isMonthDisabled(month))
                          Icon(Icons.block, size: 12, color: Colors.grey[600])
                        else if (_isFutureMonth(month))
                          Icon(
                            Icons.help_outline,
                            size: 12,
                            color: Colors.grey[600],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.add,
                              size: 10,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
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
    return month >= 1 && month <= 12 ? monthNames[month] : '';
  }
}
