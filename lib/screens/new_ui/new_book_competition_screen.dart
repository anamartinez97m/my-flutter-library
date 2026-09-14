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
const _kBg = Color(0xFFFDF8F5);
const _kPrimary = Color(0xFF5D2641);
const _kInk = Color(0xFF1F151B);
const _kSub = Color(0xFF7A6B73);
const _kBorder = Color(0xFFE2D1DC);
const _kSoft = Color(0xFFF9F3F0);
const _kLavender = Color(0xFFF3E8EE);
const _kGold = Color(0xFFC59B27);
const _kGoldSoft = Color(0xFFFBF5E5);
const _kGreen = Color(0xFF047857);

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
  int selectedStage = 0;
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _canRunQuarterlyCompetition(int quarter) {
    final firstMonth = (quarter - 1) * 3 + 1;
    final monthlyWinners =
        competitionResult?.monthlyWinners.where(
          (winner) =>
              winner.month >= firstMonth && winner.month <= firstMonth + 2,
        ) ??
        [];
    final hasWinner =
        competitionResult?.quarterlyWinners.any(
          (winner) => winner.quarter == quarter,
        ) ??
        false;
    return !hasWinner && monthlyWinners.length >= 2;
  }

  bool _canRunSemifinalCompetition(int roundNumber) {
    final requiredQuarters = roundNumber == 1 ? [1, 3] : [2, 4];
    final available =
        competitionResult?.quarterlyWinners.where(
          (winner) => requiredQuarters.contains(winner.quarter),
        ) ??
        [];
    final hasWinner =
        competitionResult?.semifinalWinners.any(
          (winner) => winner.roundNumber == roundNumber,
        ) ??
        false;
    return !hasWinner && available.length == 2;
  }

  bool _canRunFinalCompetition() =>
      competitionResult?.semifinalWinners.length == 2 &&
      competitionResult?.yearlyWinner == null;

  bool _isFutureMonth(int month) {
    final now = DateTime.now();
    return DateTime(widget.year, month).isAfter(DateTime(now.year, now.month));
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

  QuarterlyWinner? _quarterWinner(int quarter) =>
      competitionResult!.quarterlyWinners
          .where((winner) => winner.quarter == quarter)
          .firstOrNull;

  SemifinalWinner? _semifinalWinner(int round) =>
      competitionResult!.semifinalWinners
          .where((winner) => winner.roundNumber == round)
          .firstOrNull;

  MonthlyWinner? _monthWinner(int month) =>
      competitionResult!.monthlyWinners
          .where((winner) => winner.month == month)
          .firstOrNull;

  Book? _bookById(int bookId) =>
      monthBooksCache.values
          .expand((books) => books)
          .where((book) => book.bookId == bookId)
          .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Manrope'),
        primaryTextTheme: theme.primaryTextTheme.apply(fontFamily: 'Manrope'),
      ),
      child: Scaffold(
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
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: _kBorder),
          ),
        ),
        body:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                )
                : competitionResult == null
                ? Center(
                  child: Text(
                    l10n.no_competition_data,
                    style: const TextStyle(color: _kSub),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 72),
                  child: Column(
                    children: [
                      _buildProgressHero(),
                      const SizedBox(height: 24),
                      _buildStageTabs(),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(selectedStage),
                          child: switch (selectedStage) {
                            0 => _buildQuarterlyStage(),
                            1 => _buildSemifinalsStage(),
                            _ => _buildFinalStage(),
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMonthlyQualifiers(),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildProgressHero() {
    if (competitionResult!.yearlyWinner != null) {
      return _buildCompletedChampionshipHero();
    }
    final decided = competitionResult!.quarterlyWinners.length;
    final nextQuarter =
        List.generate(
          4,
          (index) => index + 1,
        ).where((quarter) => _canRunQuarterlyCompetition(quarter)).firstOrNull;
    final progress = decided / 4;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOURNAMENT STATUS',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  height: 4 / 3,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .6,
                  color: _kSub,
                ),
              ),
              _badge(
                '${(progress * 100).round()}% Decided',
                _kGoldSoft,
                _kGold,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  nextQuarter == null
                      ? decided == 4
                          ? 'Quarterly Champions Ready'
                          : 'Tournament In Progress'
                      : 'Q$nextQuarter Voting Currently Active',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                ),
              ),
              Text(
                '$decided / 4 Quarters Ready',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _kSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 10,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _kSoft,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _kBorder.withValues(alpha: .6)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kPrimary, _kGold],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildNextAction(nextQuarter),
        ],
      ),
    );
  }

  Widget _buildCompletedChampionshipHero() {
    final winner = competitionResult!.yearlyWinner!;
    final book = _bookById(winner.winnerBookId);
    final rating = book?.myRating;
    final winningQuarter =
        competitionResult!.quarterlyWinners
            .where(
              (quarter) => quarter.winner.winnerBookId == winner.winnerBookId,
            )
            .firstOrNull;
    final details =
        winningQuarter == null
            ? 'Grand Winner'
            : 'Grand Winner • Q${winningQuarter.quarter} & Semifinalist';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEDDD8)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFCFB), Color(0xFFF9F1EE)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2ED97706),
            blurRadius: 30,
            spreadRadius: -4,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x14522238),
            blurRadius: 12,
            spreadRadius: -2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 144,
            padding: const EdgeInsets.fromLTRB(13, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: const Border(
                left: BorderSide(color: Color(0xFFFBBF24), width: 3),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF522238), Color(0xFF3D1628)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33522238),
                  blurRadius: 25,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  winner.bookName,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  book?.author ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    height: 1.5,
                    color: Color(0xE6FDE68A),
                  ),
                ),
                const Spacer(),
                Container(height: 1, color: Colors.white.withValues(alpha: .1)),
                const SizedBox(height: 5),
                Text(
                  book?.genre ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: .6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (index) => const Icon(
                        Icons.star,
                        size: 13,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        rating.toStringAsFixed(2),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF522238),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  winner.bookName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    height: 1.38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                    color: Color(0xFF522238),
                  ),
                ),
                Text(
                  details,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Color(0xB3522238),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF522238),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Champion Title',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextAction(int? nextQuarter) {
    VoidCallback? action;
    String title;
    String subtitle;
    if (nextQuarter != null) {
      final firstMonth = (nextQuarter - 1) * 3 + 1;
      title = 'Vote: Quarter $nextQuarter Winner';
      subtitle =
          '${_monthName(firstMonth)}, ${_monthName(firstMonth + 1)} & ${_monthName(firstMonth + 2)} finalists await';
      action = () => _runQuarterlyCompetition(nextQuarter);
    } else if (_canRunSemifinalCompetition(1) ||
        _canRunSemifinalCompetition(2)) {
      final round = _canRunSemifinalCompetition(1) ? 1 : 2;
      title = 'Vote: Semifinal $round Winner';
      subtitle =
          round == 1 ? 'Q1 & Q3 champions await' : 'Q2 & Q4 champions await';
      action = () => _runSemifinalCompetition(round);
    } else if (_canRunFinalCompetition()) {
      title = 'Vote: Grand Finale Winner';
      subtitle = 'The semifinal champions await';
      action = _runFinalCompetition;
    } else {
      title = 'Next round coming soon';
      subtitle = 'Complete the current qualifiers to continue';
    }
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xB3E6D3A3)),
        gradient: const LinearGradient(colors: [_kLavender, _kGoldSoft]),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.how_to_vote_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: _kSub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (action != null)
            TextButton.icon(
              onPressed: action,
              style: TextButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text(
                'Vote',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStageTabs() {
    const tabs = [
      (Icons.grid_view_rounded, 'Quarterly'),
      (Icons.account_tree_outlined, 'Semifinals'),
      (Icons.emoji_events_outlined, 'Grand Final'),
    ];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = selectedStage == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => selectedStage = index),
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[index].$1,
                      size: 14,
                      color: selected ? Colors.white : _kSub,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tabs[index].$2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? Colors.white : _kSub,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuarterlyStage() => Column(
    children: [
      _sectionTitle(
        Icons.workspace_premium_outlined,
        'Quarterly Champions',
        'Road to Semis',
      ),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 122,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => _buildQuarterCard(index + 1),
      ),
    ],
  );

  Widget _buildQuarterCard(int quarter) {
    final winner = _quarterWinner(quarter);
    final canVote = _canRunQuarterlyCompetition(quarter);
    if (winner != null) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(radius: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QUARTER $quarter', style: _overline()),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                winner.winner.bookName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _titleStyle(14),
              ),
            ),
            const Divider(height: 1, color: Color(0x66E2D1DC)),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirmed',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _kGreen,
                  ),
                ),
                Icon(Icons.check_circle_outline, size: 14, color: _kGreen),
              ],
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: canVote ? () => _runQuarterlyCompetition(quarter) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color:
              canVote
                  ? _kGoldSoft.withValues(alpha: .5)
                  : _kSoft.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canVote ? _kGold : _kBorder,
            width: canVote ? 2 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'QUARTER $quarter',
                  style: _overline(color: canVote ? _kGold : _kSub),
                ),
                Icon(
                  canVote ? Icons.circle : Icons.lock_outline,
                  size: canVote ? 6 : 12,
                  color: canVote ? _kGold : _kSub,
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canVote ? Icons.add : Icons.hourglass_empty,
                    size: canVote ? 25 : 24,
                    color: canVote ? _kPrimary : _kSub,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    canVote ? 'Pick Champion' : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: canVote ? _kPrimary : _kSub,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              canVote
                  ? 'Voting Open'
                  : '${_quarterMonths(quarter)} ${widget.year}',
              style: TextStyle(
                fontSize: 10,
                color: _kSub.withValues(alpha: .8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemifinalsStage() => Column(
    children: [
      _sectionTitle(
        Icons.account_tree_outlined,
        'Semifinal Matchups',
        'Single Elimination',
      ),
      const SizedBox(height: 12),
      _buildSemifinalCard(1, 1, 3),
      const SizedBox(height: 12),
      _buildSemifinalCard(2, 2, 4),
    ],
  );

  Widget _buildSemifinalCard(int round, int firstQuarter, int secondQuarter) {
    final first = _quarterWinner(firstQuarter);
    final second = _quarterWinner(secondQuarter);
    final winner = _semifinalWinner(round);
    final canVote = _canRunSemifinalCompetition(round);
    final waitingOn =
        first == null
            ? 'Q$firstQuarter'
            : second == null
            ? 'Q$secondQuarter'
            : null;
    return InkWell(
      onTap: canVote ? () => _runSemifinalCompetition(round) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: _cardDecoration(radius: 16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.flag_outlined, size: 14, color: _kPrimary),
                const SizedBox(width: 6),
                Text(
                  'Semifinal $round',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
                const Spacer(),
                _badge(
                  winner != null
                      ? 'Confirmed'
                      : canVote
                      ? 'Ready to Vote'
                      : 'Waiting on ${waitingOn ?? 'results'}',
                  winner != null
                      ? const Color(0xFFE8F5EE)
                      : canVote
                      ? _kGoldSoft
                      : _kSoft,
                  winner != null
                      ? _kGreen
                      : canVote
                      ? _kGold
                      : _kSub,
                ),
              ],
            ),
            const Divider(height: 20, color: Color(0x80E2D1DC)),
            Row(
              children: [
                Expanded(
                  child: _contender(
                    firstQuarter,
                    first,
                    winner?.winner.winnerBookId,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _kPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kGold,
                    ),
                  ),
                ),
                Expanded(
                  child: _contender(
                    secondQuarter,
                    second,
                    winner?.winner.winnerBookId,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _contender(
    int quarter,
    QuarterlyWinner? contender,
    int? winnerBookId, {
    bool alignEnd = false,
  }) {
    final ready = contender != null;
    final won = ready && contender.winner.winnerBookId == winnerBookId;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: ready ? _kBg : _kGoldSoft.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ready ? _kBorder.withValues(alpha: .8) : _kGold,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            'Q$quarter ${ready ? 'CHAMPION' : 'CONTENDER'}',
            style: _overline(color: ready ? _kSub : _kGold, size: 10),
          ),
          const SizedBox(height: 2),
          Text(
            ready ? contender.winner.bookName : 'To be decided',
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontStyle: ready ? FontStyle.normal : FontStyle.italic,
              color: ready ? _kInk : _kSub,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            won
                ? 'Winner'
                : ready
                ? 'Ready'
                : 'Pending',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: won || ready ? _kGreen : _kGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStage() {
    final winner = competitionResult!.yearlyWinner;
    final canVote = _canRunFinalCompetition();
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, _kSoft],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F5D2641),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: _kGoldSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  size: 14,
                  color: _kGold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'GRAND FINALE ${widget.year}',
                style: _overline(color: _kPrimary, size: 12),
              ),
              const Spacer(),
              _badge('Year-End Crowning', Colors.white, _kSub),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: canVote ? _runFinalCompetition : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: winner != null || canVote ? _kGold : _kBorder,
                  width: winner != null || canVote ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _kLavender,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      winner != null
                          ? Icons.emoji_events
                          : canVote
                          ? Icons.how_to_vote_outlined
                          : Icons.lock_outline,
                      size: 24,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    winner?.bookName ?? 'The ${widget.year} Literary Crown',
                    textAlign: TextAlign.center,
                    style: _titleStyle(14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    winner != null
                        ? 'Champion of the year'
                        : canVote
                        ? 'Tap to choose the champion'
                        : 'Awaits semifinal champions',
                    style: const TextStyle(fontSize: 12, color: _kSub),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyQualifiers() => Column(
    children: [
      _sectionTitle(Icons.calendar_month_outlined, 'Monthly Qualifiers'),
      const SizedBox(height: 12),
      ...List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 8),
          child: _buildQuarterPathway(index + 1),
        ),
      ),
    ],
  );

  Widget _buildQuarterPathway(int quarter) {
    final firstMonth = (quarter - 1) * 3 + 1;
    final winner = _quarterWinner(quarter);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: _kPrimary),
              const SizedBox(width: 6),
              Text(
                'Q$quarter Feeder (${_monthName(firstMonth)} - ${_monthName(firstMonth + 2)})',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          if (winner != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Text(
                'Winner: ${winner.winner.bookName}',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _kGreen,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(3, (index) {
                final month = firstMonth + index;
                final monthlyWinner = _monthWinner(month);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                    child: InkWell(
                      onTap:
                          _isFutureMonth(month)
                              ? null
                              : () => _selectMonthlyWinner(month),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 76),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _kBorder.withValues(alpha: .6),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _monthName(month).toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kSub,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              monthlyWinner?.winner.bookName ??
                                  (_isFutureMonth(month)
                                      ? 'Upcoming'
                                      : 'Select'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                                color: monthlyWinner == null ? _kSub : _kInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String title, [String? trailing]) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kLavender,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: _kPrimary),
      ),
      const SizedBox(width: 8),
      Text(title, style: _titleStyle(16, color: _kPrimary)),
      if (trailing != null) ...[
        const Spacer(),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _kSub,
          ),
        ),
      ],
    ],
  );

  Widget _badge(String text, Color background, Color foreground) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: foreground.withValues(alpha: .25)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
    ),
  );

  BoxDecoration _cardDecoration({required double radius}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _kBorder.withValues(alpha: .7)),
    boxShadow: const [
      BoxShadow(color: Color(0x0F5D2641), blurRadius: 12, offset: Offset(0, 2)),
    ],
  );

  TextStyle _overline({Color color = _kSub, double size = 11}) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    height: 1.5,
    fontWeight: FontWeight.w700,
    letterSpacing: size * .05,
    color: color,
  );

  TextStyle _titleStyle(double size, {Color color = _kInk}) => TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    height: 1.25,
    fontWeight: FontWeight.w800,
    color: color,
  );

  String _monthName(int month) =>
      const [
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
      ][month];

  String _quarterMonths(int quarter) =>
      const ['Jan - Mar', 'Apr - Jun', 'Jul - Sep', 'Oct - Dec'][quarter - 1];
}
