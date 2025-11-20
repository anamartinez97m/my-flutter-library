import 'package:flutter/material.dart';

class SeasonalPreferencesCard extends StatelessWidget {
  final Map<String, int> seasonalReading;

  const SeasonalPreferencesCard({
    super.key,
    required this.seasonalReading,
  });

  String _getPreferredSeason() {
    if (seasonalReading.isEmpty) return 'None';
    
    final sortedSeasons = seasonalReading.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedSeasons.first.key;
  }

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
    final preferredSeason = _getPreferredSeason();
    final totalBooks = seasonalReading.values.fold(0, (sum, count) => sum + count);

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
                  Icons.wb_sunny_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Seasonal Reading Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (totalBooks > 0) ...[
              // Preferred season highlight
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
                          'You read most in',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          preferredSeason,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
              
              // Season breakdown
              ...seasonalReading.entries.map((entry) {
                final percentage = (entry.value / totalBooks * 100).toStringAsFixed(1);
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
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Text(
                            '${entry.value} books ($percentage%)',
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
              }).toList(),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No reading data available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
