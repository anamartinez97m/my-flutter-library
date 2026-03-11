import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

class SeasonalReadingCard extends StatelessWidget {
  final Map<String, int> seasonalReading;
  final Map<int, Map<String, int>> seasonalReadingPerYear;
  final int yearsCount;

  const SeasonalReadingCard({
    super.key,
    required this.seasonalReading,
    required this.seasonalReadingPerYear,
    this.yearsCount = 1,
  });

  String _getSeasonEmoji(String season) {
    switch (season) {
      case 'Winter':
        return '❄️';
      case 'Spring':
        return '🌸';
      case 'Summer':
        return '☀️';
      case 'Fall':
        return '🍂';
      default:
        return '📚';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find most and least productive seasons
    final sortedSeasons =
        seasonalReading.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final mostProductive =
        sortedSeasons.isNotEmpty ? sortedSeasons.first : null;
    final leastProductive =
        sortedSeasons.isNotEmpty ? sortedSeasons.last : null;

    // Calculate averages per year for most and least productive seasons
    final mostAvgPerYear =
        mostProductive != null && yearsCount > 0
            ? (mostProductive.value / yearsCount).toStringAsFixed(1)
            : '0.0';
    final leastAvgPerYear =
        leastProductive != null && yearsCount > 0
            ? (leastProductive.value / yearsCount).toStringAsFixed(1)
            : '0.0';

    final l10n = AppLocalizations.of(context)!;

    // Calculate total for percentages
    final totalBooks = seasonalReading.values.fold<int>(0, (a, b) => a + b);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Text(
              l10n.seasonal_reading_patterns,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // "You read most in SEASON" hero
            if (mostProductive != null) ...[
              Text(
                l10n.you_read_most_in,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                '${_getSeasonEmoji(mostProductive.key)} ${mostProductive.key}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Percentage bars for all 4 seasons
            if (totalBooks > 0)
              ...['Winter', 'Spring', 'Summer', 'Fall'].map((season) {
                final count = seasonalReading[season] ?? 0;
                final percentage = count / totalBooks;
                final isMost =
                    mostProductive != null && season == mostProductive.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text(
                        _getSeasonEmoji(season),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52,
                        child: Text(
                          season,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isMost ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 14,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isMost
                                  ? Colors.green
                                  : Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 38,
                        child: Text(
                          '${(percentage * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isMost ? Colors.green : Colors.grey[700],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[300]),
            const SizedBox(height: 16),

            // Most read average
            if (mostProductive != null &&
                leastProductive != null &&
                mostProductive.key != leastProductive.key) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.most,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_getSeasonEmoji(mostProductive.key)} ${mostProductive.key}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          mostAvgPerYear,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          l10n.per_year,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 60, color: Colors.grey[300]),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.least,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_getSeasonEmoji(leastProductive.key)} ${leastProductive.key}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          leastAvgPerYear,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          l10n.per_year,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
