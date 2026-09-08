import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/new_monthly_winner_selection_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/new_quarterly_winner_selection_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/new_semifinal_winner_selection_screen.dart';
import 'package:myrandomlibrary/screens/new_ui/new_yearly_winner_selection_screen.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kBorder = Color(0xFFD5C2C7);
const _kDivider = Color(0xFFE6E2DF);
const _kBadgeBg = Color(0xFFF2EDEB);
const _kGold = Color(0xFFD4A017);
const _kSecondary = Color(0xFF894B67);

class NewBookCompetitionScreen extends StatefulWidget {
  final int year;

  const NewBookCompetitionScreen({super.key, required this.year});

  @override
  State<NewBookCompetitionScreen> createState() =>
      _NewBookCompetitionScreenState();
}

class _NewBookCompetitionScreenState extends State<NewBookCompetitionScreen> {
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

      final result = await repository.getCompetitionResults(widget.year);
      final booksPerMonth = await repository.getBooksReadPerMonth(widget.year);

      if (mounted) {
        setState(() {
          competitionResult = result;
          monthBooksCache = booksPerMonth;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading competition data: $e');
      if (mounted) {
        setState(() => isLoading = false);
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
            (context) => NewMonthlyWinnerSelectionScreen(
              year: widget.year,
              month: month,
            ),
      ),
    );

    if (result == true) _loadCompetitionData();
  }

  Future<void> _runQuarterlyCompetition(int quarter) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => NewQuarterlyWinnerSelectionScreen(
              year: widget.year,
              quarter: quarter,
            ),
      ),
    );

    if (result == true) await _loadCompetitionData();
  }

  Future<void> _runSemifinalCompetition(int roundNumber) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => NewSemifinalWinnerSelectionScreen(
              year: widget.year,
              roundNumber: roundNumber,
            ),
      ),
    );

    if (result == true) await _loadCompetitionData();
  }

  Future<void> _runFinalCompetition() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NewYearlyWinnerSelectionScreen(year: widget.year),
      ),
    );

    if (result == true) await _loadCompetitionData();
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
          l10n.best_book_of_year(widget.year.toString()),
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
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : competitionResult == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: _kBorder,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.no_competition_data,
                      style: const TextStyle(fontSize: 16, color: _kSub),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (competitionResult!.yearlyWinner != null)
                      _buildYearlyWinnerSection(),
                    if (competitionResult!.yearlyWinner != null)
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A27231E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, color: _kGold, size: 28),
              const SizedBox(width: 10),
              Text(
                l10n.year_winner,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                const Icon(Icons.star_rounded, color: _kGold, size: 40),
                const SizedBox(height: 8),
                Text(
                  winner.bookName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentTree() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A27231E)),
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
          _buildSectionHeader(
            l10n.tournament_tree,
            Icons.account_tree_outlined,
          ),
          const SizedBox(height: 20),
          _buildQuarterlySection(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: _kDivider),
          ),
          _buildSemifinalsSection(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: _kDivider),
          ),
          _buildFinalSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.only(bottom: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x3327231E))),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kPrimary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuarterlySection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quarterly_winners,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kSub,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildQuarterCard(1)),
            const SizedBox(width: 10),
            Expanded(child: _buildQuarterCard(2)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildQuarterCard(3)),
            const SizedBox(width: 10),
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

    final canRunCompetition = _canRunQuarterlyCompetition(quarter);
    final hasWinner = quarterlyWinner != null;

    return GestureDetector(
      onTap:
          canRunCompetition || hasWinner
              ? () => _runQuarterlyCompetition(quarter)
              : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 90),
        decoration: BoxDecoration(
          color:
              hasWinner
                  ? _kPrimary.withValues(alpha: 0.06)
                  : canRunCompetition
                  ? _kSecondary.withValues(alpha: 0.04)
                  : _kBadgeBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                hasWinner
                    ? _kPrimary.withValues(alpha: 0.2)
                    : canRunCompetition
                    ? _kSecondary.withValues(alpha: 0.3)
                    : _kBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Q$quarter',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: hasWinner ? _kPrimary : _kSub,
              ),
            ),
            const SizedBox(height: 6),
            if (hasWinner)
              Text(
                quarterlyWinner.winner.bookName,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else if (canRunCompetition)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _kSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, size: 16, color: _kSecondary),
              )
            else
              Icon(Icons.hourglass_empty, size: 16, color: _kBorder),
          ],
        ),
      ),
    );
  }

  Widget _buildSemifinalsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.semifinals,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kSub,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSemifinalCard(1, 'Q1 vs Q3')),
            const SizedBox(width: 10),
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
    final hasWinner = semifinalWinner != null;

    return GestureDetector(
      onTap:
          canRunCompetition || hasWinner
              ? () => _runSemifinalCompetition(roundNumber)
              : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(minHeight: 90),
        decoration: BoxDecoration(
          color:
              hasWinner
                  ? _kSecondary.withValues(alpha: 0.06)
                  : canRunCompetition
                  ? _kSecondary.withValues(alpha: 0.04)
                  : _kBadgeBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                hasWinner
                    ? _kSecondary.withValues(alpha: 0.25)
                    : canRunCompetition
                    ? _kSecondary.withValues(alpha: 0.3)
                    : _kBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              matchup,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: hasWinner ? _kSecondary : _kSub,
              ),
            ),
            const SizedBox(height: 8),
            if (hasWinner)
              Text(
                semifinalWinner.winner.bookName,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _kPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else if (canRunCompetition)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _kSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, size: 18, color: _kSecondary),
              )
            else
              Icon(Icons.hourglass_empty, size: 18, color: _kBorder),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalSection() {
    final l10n = AppLocalizations.of(context)!;
    final yearlyWinner = competitionResult!.yearlyWinner;
    final canRunCompetition = _canRunFinalCompetition();
    final hasWinner = yearlyWinner != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.final_round,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kSub,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap:
              canRunCompetition || hasWinner
                  ? () => _runFinalCompetition()
                  : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  hasWinner
                      ? _kPrimary.withValues(alpha: 0.06)
                      : canRunCompetition
                      ? _kGold.withValues(alpha: 0.04)
                      : _kBadgeBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    hasWinner
                        ? _kGold.withValues(alpha: 0.3)
                        : canRunCompetition
                        ? _kGold.withValues(alpha: 0.3)
                        : _kBorder.withValues(alpha: 0.5),
              ),
            ),
            child:
                hasWinner
                    ? Column(
                      children: [
                        const Icon(Icons.emoji_events, color: _kGold, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          yearlyWinner.bookName,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                    : canRunCompetition
                    ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, size: 24, color: _kGold),
                      ),
                    )
                    : Center(
                      child: Icon(
                        Icons.hourglass_empty,
                        size: 28,
                        color: _kBorder,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyWinnersSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A27231E)),
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
          _buildSectionHeader(
            l10n.monthly_winners,
            Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthlyWinner =
                  competitionResult!.monthlyWinners
                      .where((m) => m.month == month)
                      .firstOrNull;

              final hasWinner = monthlyWinner != null;
              final disabled = _isMonthDisabled(month);
              final future = _isFutureMonth(month);

              return GestureDetector(
                onTap: () => _selectMonthlyWinner(month),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        hasWinner
                            ? _kPrimary.withValues(alpha: 0.06)
                            : disabled
                            ? _kDivider.withValues(alpha: 0.5)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          hasWinner
                              ? _kPrimary.withValues(alpha: 0.2)
                              : disabled
                              ? _kDivider
                              : _kBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getMonthName(month),
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: disabled ? _kBorder : _kSub,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (hasWinner)
                        Expanded(
                          child: Center(
                            child: Text(
                              monthlyWinner.winner.bookName,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _kPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      else if (disabled)
                        Icon(Icons.block, size: 14, color: _kBorder)
                      else if (future)
                        Icon(Icons.hourglass_empty, size: 14, color: _kBorder)
                      else
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 12,
                            color: Colors.white,
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
    );
  }
}
