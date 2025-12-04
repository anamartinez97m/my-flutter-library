import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/repositories/book_competition_repository.dart';
import 'package:myrandomlibrary/screens/book_competition_screen.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';

class PastYearsCompetitionScreen extends StatefulWidget {
  const PastYearsCompetitionScreen({super.key});

  @override
  State<PastYearsCompetitionScreen> createState() =>
      _PastYearsCompetitionScreenState();
}

class _PastYearsCompetitionScreenState
    extends State<PastYearsCompetitionScreen> {
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

      // Get past years winners
      final winners = await competitionRepository.getPastYearsWinners(
        currentYear,
      );

      // Get all years with competitions
      final yearsWithCompetitions =
          await competitionRepository.getYearsWithCompetitions();

      // Get all years with books read
      final yearData = await bookRepository.getBooksAndPagesPerYear();
      final yearsWithBooks = yearData['books']?.keys.toList() ?? [];

      // Combine both sets of years and filter out current year
      final allYears =
          {
            ...yearsWithCompetitions,
            ...yearsWithBooks,
          }.where((year) => year < currentYear).toList();

      // Sort descending
      allYears.sort((a, b) => b.compareTo(a));

      if (mounted) {
        setState(() {
          pastWinners = winners;
          availableYears = allYears;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading past years data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Past Years Competitions')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : availableYears.isEmpty
              ? const Center(
                child: Text(
                  'No past competitions found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: 56.0, // Add bottom padding instead of SizedBox
                  ),
                  itemCount: availableYears.length,
                  itemBuilder: (context, index) {
                    final year = availableYears[index];
                    final winner = getWinnerForYear(year);
                    
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BookCompetitionScreen(year: year),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Best Book of $year',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    if (winner != null)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.emoji_events,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              winner.bookName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        'No winner set',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
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
