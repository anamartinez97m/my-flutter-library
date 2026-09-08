import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/screens/new_ui/new_book_competition_screen.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

// ── v2 design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFFDF8F6);
const _kPrimary = Color(0xFF43102B);
const _kSub = Color(0xFF514348);
const _kText = Color(0xFF1C1B1A);
const _kBorder = Color(0xFFD5C2C7);
const _kGold = Color(0xFFD4A017);

class NewPastYearsCompetitionScreen extends StatefulWidget {
  const NewPastYearsCompetitionScreen({super.key});

  @override
  State<NewPastYearsCompetitionScreen> createState() =>
      _NewPastYearsCompetitionScreenState();
}

class _NewPastYearsCompetitionScreenState
    extends State<NewPastYearsCompetitionScreen> {
  List<BookCompetition> pastWinners = [];
  List<int> availableYears = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPastYearsData();
  }

  Future<void> _loadPastYearsData() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final competitionRepository = BookCompetitionRepository(db);
      final bookRepository = BookRepository(db);
      final currentYear = DateTime.now().year;

      final winners = await competitionRepository.getPastYearsWinners(
        currentYear,
      );

      final yearsWithCompetitions =
          await competitionRepository.getYearsWithCompetitions();

      final yearData = await bookRepository.getBooksAndPagesPerYear();
      final yearsWithBooks = yearData['books']?.keys.toList() ?? [];

      final allYears =
          {
            ...yearsWithCompetitions,
            ...yearsWithBooks,
          }.where((year) => year < currentYear).toList();

      allYears.sort((a, b) => b.compareTo(a));

      if (mounted) {
        setState(() {
          pastWinners = winners;
          availableYears = allYears;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading past years data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  BookCompetition? getWinnerForYear(int year) {
    try {
      return pastWinners.firstWhere((winner) => winner.year == year);
    } catch (e) {
      return null;
    }
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
          isLoading
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : availableYears.isEmpty
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
                      l10n.no_past_competitions_found,
                      style: const TextStyle(fontSize: 16, color: _kSub),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
                itemCount: availableYears.length,
                itemBuilder: (context, index) {
                  final year = availableYears[index];
                  final winner = getWinnerForYear(year);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    NewBookCompetitionScreen(year: year),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x1A27231E)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _kPrimary.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _kPrimary.withValues(alpha: 0.1),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.calendar_today,
                                  color: _kPrimary,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.best_book_of_year(year.toString()),
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _kText,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (winner != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.emoji_events,
                                          color: _kGold,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            winner.bookName,
                                            style: const TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: _kPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      l10n.no_winner_set,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 13,
                                        color: _kSub,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: _kSub,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
