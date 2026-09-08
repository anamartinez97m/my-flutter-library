import 'package:flutter/material.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_competition_screen.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSecondary = Color(0xFF894B67);
const _kSub = Color(0xFF514348);
const _kText = Color(0xFF1C1B1A);
const _kBorder = Color(0xFFD5C2C7);
const _kGold = Color(0xFFC98A2C);
const _kGoldLight = Color(0xFFFEF7EA);
const _kHeroGradientStart = Color(0xFF43102B);
const _kHeroGradientMid = Color(0xFF5D2641);
const _kHeroGradientEnd = Color(0xFF300A1E);

enum _FilterChip { all, awarded, unresolved }

class NewPastYearsCompetitionScreen2 extends StatefulWidget {
  const NewPastYearsCompetitionScreen2({super.key});

  @override
  State<NewPastYearsCompetitionScreen2> createState() =>
      _NewPastYearsCompetitionScreen2State();
}

class _NewPastYearsCompetitionScreen2State
    extends State<NewPastYearsCompetitionScreen2>
    with WidgetsBindingObserver {
  BookCompetition? _reigningChampion;
  List<BookCompetition> _pastWinners = [];
  List<int> _availableYears = [];
  bool _isLoading = true;

  _FilterChip _selectedFilter = _FilterChip.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final competitionRepository = BookCompetitionRepository(db);
      final bookRepository = BookRepository(db);
      final currentYear = DateTime.now().year;

      final competitionResult = await competitionRepository
          .getCompetitionResults(currentYear);
      final pastWinners = await competitionRepository.getPastYearsWinners(
        currentYear,
      );
      final yearsWithCompetitions =
          await competitionRepository.getYearsWithCompetitions();
      final yearData = await bookRepository.getBooksAndPagesPerYear();
      final yearsWithBooks = yearData['books']?.keys.toList() ?? [];

      final allYears =
          <int>{
            ...yearsWithCompetitions,
            ...yearsWithBooks,
          }.where((year) => year < currentYear).toList();
      allYears.sort((a, b) => b.compareTo(a));

      // Reigning champion = current-year winner if already set, otherwise the
      // most recent past winner, so the card is visible even before the year
      // has finished.
      BookCompetition? reigningChampion = competitionResult?.yearlyWinner;
      if (reigningChampion == null && pastWinners.isNotEmpty) {
        reigningChampion = pastWinners.first;
      }

      if (mounted) {
        setState(() {
          _reigningChampion = reigningChampion;
          _pastWinners = pastWinners;
          _availableYears = allYears;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading competition data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<int> get _awardedYears =>
      _pastWinners.map((winner) => winner.year).toSet().toList()
        ..sort((a, b) => b.compareTo(a));

  List<int> get _unresolvedYears =>
      _availableYears.where((year) => !_awardedYears.contains(year)).toList();

  List<BookCompetition> get _filteredPastWinners =>
      _pastWinners
          .where((winner) => _filteredYears.contains(winner.year))
          .toList();

  List<int> get _filteredUnresolvedYears =>
      _unresolvedYears.where((year) => _filteredYears.contains(year)).toList();

  List<int> get _filteredYears {
    switch (_selectedFilter) {
      case _FilterChip.awarded:
        return _awardedYears;
      case _FilterChip.unresolved:
        return _unresolvedYears;
      case _FilterChip.all:
        return _availableYears;
    }
  }

  void _onFilterSelected(_FilterChip filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  Future<void> _navigateToCompetition(int year) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewBookCompetitionScreen(year: year),
      ),
    );
    _loadData();
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
          l10n.past_years_competitions,
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
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : _availableYears.isEmpty && _reigningChampion == null
              ? _buildEmptyState(l10n)
              : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _buildFilterChips(),
                    ),
                  ),
                  if (_reigningChampion != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: _buildReigningChampionSection(l10n),
                      ),
                    ),
                  if (_filteredPastWinners.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                        child: _buildSectionHeader(
                          'Previous Laureates',
                          _buildYearRangeBadge(_filteredPastWinners),
                        ),
                      ),
                    ),
                  if (_filteredPastWinners.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 139,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final winner = _filteredPastWinners[index];
                          return _buildLaureateCard(winner.year, winner);
                        }, childCount: _filteredPastWinners.length),
                      ),
                    ),
                  if (_filteredUnresolvedYears.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                        child: _buildPendingHeader(),
                      ),
                    ),
                  if (_filteredUnresolvedYears.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 50),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final year = _filteredUnresolvedYears[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildUnresolvedCard(year),
                          );
                        }, childCount: _filteredUnresolvedYears.length),
                      ),
                    ),
                ],
              ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 64, color: _kBorder),
          const SizedBox(height: 16),
          Text(
            l10n.no_past_competitions_found,
            style: const TextStyle(fontSize: 16, color: _kSub),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final chips = [
      _FilterChipData(label: 'All Years', filter: _FilterChip.all),
      _FilterChipData(
        label: 'Awarded (${_awardedYears.length})',
        filter: _FilterChip.awarded,
      ),
      _FilterChipData(
        label: 'Unresolved (${_unresolvedYears.length})',
        filter: _FilterChip.unresolved,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            chips.map((chip) {
              final isSelected = _selectedFilter == chip.filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(chip.label),
                  selected: isSelected,
                  onSelected: (_) => _onFilterSelected(chip.filter),
                  labelStyle: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : _kSub,
                  ),
                  selectedColor: _kPrimary,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? _kPrimary : const Color(0xFFF0E7E4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildReigningChampionSection(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'REIGNING CHAMPION',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _kSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const Text(
              '★ Hall of Fame',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildHeroCard(),
      ],
    );
  }

  Widget _buildHeroCard() {
    final winner = _reigningChampion!;

    return GestureDetector(
      onTap: () => _navigateToCompetition(winner.year),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kGold.withValues(alpha: 0.3)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kHeroGradientStart, _kHeroGradientMid, _kHeroGradientEnd],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F5D2641),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              top: -12,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: _kGold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 14,
                            color: _kGoldLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'BEST BOOK OF ${winner.year}',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _kGoldLight,
                              letterSpacing: 0.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Completed in ${winner.year + 1}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 80,
                      padding: const EdgeInsets.fromLTRB(7, 6.75, 7, 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF7E3559), Color(0xFF380E23)],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'WINNER',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFDE68A),
                              letterSpacing: 0.45,
                            ),
                          ),
                          const Icon(
                            Icons.menu_book,
                            size: 24,
                            color: Colors.white,
                          ),
                          Container(
                            height: 2,
                            width: 24,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFCD34D,
                              ).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GRAND PRIZE WINNER',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _kGoldLight,
                              letterSpacing: 0.275,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            winner.bookName,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'by Rebecca Yarros',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 12,
                                      color: _kGoldLight,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '4.92 Rating',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _kGoldLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '18.4k votes',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 15),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'View full ${winner.year} ceremony recap',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EDF2),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                  letterSpacing: -0.35,
                ),
              ),
            ),
          ],
        ),
        const Text(
          'Yearly Archives',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _kSub,
          ),
        ),
      ],
    );
  }

  Widget _buildLaureateCard(int year, BookCompetition winner) {
    return GestureDetector(
      onTap: () => _navigateToCompetition(year),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E7E4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D5D2641),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7EDF2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$year',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '1st Place',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      winner.bookName,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Awarded Winner',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: _kSub,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 9),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0x99F0E7E4))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            size: 12,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LAUREATE',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: _kGold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: -15,
              top: -15,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBE9),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: const Center(
                  child: Text(
                    '✦',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: _kGold,
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

  String _buildYearRangeBadge(List<BookCompetition> winners) {
    if (winners.isEmpty) return '';
    final years = winners.map((winner) => winner.year).toList()..sort();
    if (years.length == 1) return '${years.first}';
    return '${years.last} - ${years.first}';
  }

  Widget _buildPendingHeader() {
    return const Text(
      'PENDING RETROSPECTIVES (NO WINNER SET)',
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF9E919A),
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildUnresolvedCard(int year) {
    return GestureDetector(
      onTap: () => _navigateToCompetition(year),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF7F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFF0E7E4),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x99F0E7E4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$year',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9E919A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best Book of $year',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD6D3D1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'No winner set • Retrospective open',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            color: Color(0xFF9E919A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EDF2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Nominate',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipData {
  final String label;
  final _FilterChip filter;

  const _FilterChipData({required this.label, required this.filter});
}
