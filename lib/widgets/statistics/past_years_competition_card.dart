import 'package:flutter/material.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/screens/past_years_competition_screen.dart';

class PastYearsCompetitionCard extends StatelessWidget {
  final List<BookCompetition> pastWinners;

  const PastYearsCompetitionCard({super.key, required this.pastWinners});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to past years selection screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PastYearsCompetitionScreen(),
          ),
        );
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
                  Icon(
                    Icons.emoji_events,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Best Past Books',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }
}
