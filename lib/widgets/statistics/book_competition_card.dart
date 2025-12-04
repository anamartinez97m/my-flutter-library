import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book_competition.dart';
import 'package:myrandomlibrary/screens/book_competition_screen.dart';

class BookCompetitionCard extends StatelessWidget {
  final int currentYear;
  final BookCompetition? yearlyWinner;
  final List<BookCompetition> nominees;

  const BookCompetitionCard({
    super.key,
    required this.currentYear,
    this.yearlyWinner,
    required this.nominees,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Text(
                  'Best Book of $currentYear',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (yearlyWinner != null)
              _buildWinnerSection(context)
            else if (nominees.isNotEmpty)
              _buildNomineesSection(context)
            else
              Center(
                child: Text(
                  'No books read in $currentYear',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              'Winner:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            yearlyWinner!.bookName,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNomineesSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.how_to_vote,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Nominees:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children:
              nominees.take(6).map((nominee) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    nominee.bookName,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
        ),
        if (nominees.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '... and ${nominees.length - 6} more',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
