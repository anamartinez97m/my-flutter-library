import 'package:flutter/material.dart';

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
    // Calculate average per season correctly:
    // 1. Sum each season across all years
    // 2. Calculate mean for each season (total / number of years)
    // 3. Average those 4 seasonal means together
    double avgPerYearPerSeason = 0.0;
    if (seasonalReadingPerYear.isNotEmpty) {
      final numYears = seasonalReadingPerYear.length;

      // Sum each season across all years
      final Map<String, int> seasonTotals = {
        'Winter': 0,
        'Spring': 0,
        'Summer': 0,
        'Fall': 0,
      };

      for (var yearData in seasonalReadingPerYear.values) {
        seasonTotals['Winter'] =
            (seasonTotals['Winter'] ?? 0) + (yearData['Winter'] ?? 0);
        seasonTotals['Spring'] =
            (seasonTotals['Spring'] ?? 0) + (yearData['Spring'] ?? 0);
        seasonTotals['Summer'] =
            (seasonTotals['Summer'] ?? 0) + (yearData['Summer'] ?? 0);
        seasonTotals['Fall'] =
            (seasonTotals['Fall'] ?? 0) + (yearData['Fall'] ?? 0);
      }

      // Calculate mean for each season
      final winterMean = seasonTotals['Winter']! / numYears;
      final springMean = seasonTotals['Spring']! / numYears;
      final summerMean = seasonTotals['Summer']! / numYears;
      final fallMean = seasonTotals['Fall']! / numYears;

      // Average the 4 seasonal means
      avgPerYearPerSeason =
          (winterMean + springMean + summerMean + fallMean) / 4;
    }

    final avgPerYearPerSeasonStr = avgPerYearPerSeason.toStringAsFixed(1);

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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Seasonal Reading Patterns',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Average books per season display
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.trending_up, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Average: $avgPerYearPerSeasonStr books per season',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Most and least productive seasons
            if (mostProductive != null &&
                leastProductive != null &&
                mostProductive.key != leastProductive.key) ...[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getSeasonEmoji(mostProductive.key),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Most',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            mostProductive.key,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            mostAvgPerYear,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            'per year',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getSeasonEmoji(leastProductive.key),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Least',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            leastProductive.key,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            leastAvgPerYear,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.orange,
                            ),
                          ),
                          Text(
                            'per year',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
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
