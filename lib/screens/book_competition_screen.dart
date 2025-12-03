import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/screens/monthly_winner_selection_screen.dart';

class BookCompetitionScreen extends StatefulWidget {
  final int year;

  const BookCompetitionScreen({super.key, required this.year});

  @override
  State<BookCompetitionScreen> createState() => _BookCompetitionScreenState();
}

class _BookCompetitionScreenState extends State<BookCompetitionScreen> {
  CompetitionResult? competitionResult;
  bool isLoading = true;

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

      // First try to get existing results
      var result = await repository.getCompetitionResults(widget.year);

      // If no results exist, run the competition (but monthly winners will need user selection)
      if (result == null || result.monthlyWinners.isEmpty) {
        result = await repository.runFullCompetition(widget.year);
      }

      if (mounted) {
        setState(() {
          competitionResult = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading competition data: $e')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Best Book of ${widget.year} Competition')),
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
        Row(
          children: [
            Expanded(child: _buildQuarterCard(1)),
            const SizedBox(width: 8),
            Expanded(child: _buildQuarterCard(2)),
            const SizedBox(width: 8),
            Expanded(child: _buildQuarterCard(3)),
            const SizedBox(width: 8),
            Expanded(child: _buildQuarterCard(4)),
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

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color:
            quarterlyWinner != null
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              quarterlyWinner != null
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Q$quarter',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
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
          else
            Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ],
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            semifinalWinner != null
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              semifinalWinner != null
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            matchup,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
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
          else
            Icon(Icons.help_outline, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildFinalSection() {
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.2),
                Colors.amber.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.withOpacity(0.5)),
          ),
          child:
              competitionResult!.yearlyWinner != null
                  ? Column(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        competitionResult!.yearlyWinner!.bookName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                  : Icon(Icons.help_outline, size: 32, color: Colors.grey),
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
                childAspectRatio: 1.8,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        monthlyWinner != null
                            ? Theme.of(context).colorScheme.surfaceVariant
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          monthlyWinner != null
                              ? Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getMonthName(month),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
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
                      else
                        InkWell(
                          onTap: () => _selectMonthlyWinner(month),
                          child: Container(
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
                        ),
                    ],
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
