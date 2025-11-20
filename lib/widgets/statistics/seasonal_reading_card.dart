import 'package:flutter/material.dart';

class SeasonalReadingCard extends StatelessWidget {
  final Map<String, int> seasonalReading;

  const SeasonalReadingCard({
    super.key,
    required this.seasonalReading,
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
    final totalBooks = seasonalReading.values.fold(0, (sum, count) => sum + count);
    
    // Calculate average per season (total books / 4 seasons)
    final avgPerSeason = totalBooks > 0 ? (totalBooks / 4).toStringAsFixed(1) : '0.0';
    
    // Find most and least productive seasons
    final sortedSeasons = seasonalReading.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostProductive = sortedSeasons.isNotEmpty ? sortedSeasons.first : null;
    final leastProductive = sortedSeasons.isNotEmpty ? sortedSeasons.last : null;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Average: $avgPerSeason books per season',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            // Most and least productive seasons
            if (mostProductive != null && leastProductive != null && mostProductive.key != leastProductive.key) ...[
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
                            '${mostProductive.value}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green,
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
                            '${leastProductive.value}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.orange,
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
