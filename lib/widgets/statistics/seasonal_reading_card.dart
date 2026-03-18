import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

class SeasonalReadingCard extends StatelessWidget {
  final Map<String, int> seasonalReading;
  final Map<int, Map<String, int>> seasonalReadingPerYear;
  final int yearsCount;
  final Map<String, String> topGenreBySeason;

  const SeasonalReadingCard({
    super.key,
    required this.seasonalReading,
    required this.seasonalReadingPerYear,
    this.yearsCount = 1,
    this.topGenreBySeason = const {},
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

  Color _getSeasonColor(String season) {
    switch (season) {
      case 'Winter':
        return Colors.blue.shade300;
      case 'Spring':
        return Colors.green.shade300;
      case 'Summer':
        return Colors.orange.shade300;
      case 'Fall':
        return Colors.brown.shade300;
      default:
        return Colors.grey.shade300;
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

    final preferredSeason = mostProductive?.key ?? 'None';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon (style from 3rd card)
            Row(
              children: [
                Icon(
                  Icons.wb_sunny_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.seasonal_reading_patterns,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (totalBooks > 0) ...[
              // Preferred season highlight (style from 3rd card)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getSeasonColor(preferredSeason).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getSeasonColor(preferredSeason),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getSeasonEmoji(preferredSeason),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.you_read_most_in,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          preferredSeason,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getSeasonColor(preferredSeason),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Season breakdown bars (style from 3rd card)
              ...seasonalReading.entries.map((entry) {
                final percentage = (entry.value / totalBooks * 100)
                    .toStringAsFixed(1);
                final barWidth = (entry.value / totalBooks).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getSeasonEmoji(entry.key),
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${entry.value} ($percentage%)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: barWidth,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getSeasonColor(entry.key),
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 16),

              // Most / Least comparison
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

              // Seasonal genre preferences (moved from ReadingInsightsCard)
              if (topGenreBySeason.isNotEmpty) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.auto_stories,
                      color: Colors.deepOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.seasonal_reading_preferences,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        topGenreBySeason.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${_getSeasonEmoji(entry.key)} ${entry.key}: ${entry.value}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.no_reading_data_available,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
