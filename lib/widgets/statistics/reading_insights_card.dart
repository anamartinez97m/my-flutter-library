import 'package:flutter/material.dart';
import 'package:myrandomlibrary/screens/rereads_detail.dart';

/// Comprehensive card displaying multiple reading insights
class ReadingInsightsCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final int dnfCount;
  final double dnfRate;
  final int rereadCount;
  final Map<String, dynamic>? mostRereadBook;
  final int seriesBooks;
  final int standaloneBooks;
  final int seriesBooksRead;
  final int standaloneBooksRead;
  final double seriesPercentage;
  final int seriesCount;
  final int mostBooksInMonth;
  final String? bestMonth;
  final int? fastestDays;
  final String? fastestBookName;
  final int nextMilestoneOwned;
  final int booksToMilestoneOwned;
  final int nextMilestoneRead;
  final int booksToMilestoneRead;
  final double bingePercentage;
  final Map<String, String> topGenreBySeason;

  const ReadingInsightsCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.dnfCount,
    required this.dnfRate,
    required this.rereadCount,
    this.mostRereadBook,
    required this.seriesBooks,
    required this.standaloneBooks,
    required this.seriesBooksRead,
    required this.standaloneBooksRead,
    required this.seriesPercentage,
    required this.seriesCount,
    required this.mostBooksInMonth,
    this.bestMonth,
    this.fastestDays,
    this.fastestBookName,
    required this.nextMilestoneOwned,
    required this.booksToMilestoneOwned,
    required this.nextMilestoneRead,
    required this.booksToMilestoneRead,
    required this.bingePercentage,
    required this.topGenreBySeason,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Insights',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Reading Streaks
            _buildInsightRow(
              context,
              icon: Icons.local_fire_department,
              color: Colors.orange,
              title: 'Reading Streaks',
              value: 'Current: $currentStreak days | Best: $longestStreak days',
            ),
            const Divider(height: 20),

            // DNF Rate
            _buildInsightRow(
              context,
              icon: Icons.close,
              color: Colors.red,
              title: 'DNF Rate',
              value: '$dnfCount books (${dnfRate.toStringAsFixed(1)}%)',
            ),
            const Divider(height: 20),

            // Re-reads
            if (rereadCount > 0) ...[
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RereadsDetailScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildInsightRow(
                    context,
                    icon: Icons.replay,
                    color: Colors.teal,
                    title: 'Re-reads',
                    value: '$rereadCount books',
                    subtitle:
                        mostRereadBook != null
                            ? 'Most: ${mostRereadBook!['name']} (${mostRereadBook!['count']}x)'
                            : null,
                    showNavigationIcon: true,
                  ),
                ),
              ),
              const Divider(height: 20),
            ],

            // Series vs Standalone
            _buildInsightRow(
              context,
              icon: Icons.collections_bookmark,
              color: Colors.indigo,
              title: 'Series vs Standalone',
              value:
                  '$seriesBooks series (${seriesPercentage.toStringAsFixed(1)}%) | $standaloneBooks standalone',
              subtitle:
                  'Read: $seriesBooksRead series + $standaloneBooksRead standalone',
            ),
            const Divider(height: 20),

            // Personal Bests
            _buildInsightRow(
              context,
              icon: Icons.emoji_events,
              color: Colors.amber,
              title: 'Personal Bests',
              value:
                  'Most in month: $mostBooksInMonth${bestMonth != null ? ' ($bestMonth)' : ''}',
              subtitle:
                  fastestDays != null && fastestBookName != null
                      ? 'Fastest: $fastestDays days ($fastestBookName)'
                      : null,
            ),
            const Divider(height: 20),

            // Milestones - Books Owned
            _buildInsightRow(
              context,
              icon: Icons.flag,
              color: Colors.green,
              title: 'Next Milestone (Books Owned)',
              value: '$nextMilestoneOwned books ($booksToMilestoneOwned to go)',
            ),
            const Divider(height: 20),

            // Milestones - Books Read
            _buildInsightRow(
              context,
              icon: Icons.menu_book,
              color: Colors.blue,
              title: 'Next Milestone (Books Read)',
              value: '$nextMilestoneRead books ($booksToMilestoneRead to go)',
            ),
            const Divider(height: 20),

            // Binge Reading
            _buildInsightRow(
              context,
              icon: Icons.fast_forward,
              color: Colors.purple,
              title: 'Binge Reading (Series)',
              value:
                  '${bingePercentage.toStringAsFixed(1)}% of books finished within 14 days of previous',
            ),

            // Mood Reading (Genre by Season)
            if (topGenreBySeason.isNotEmpty) ...[
              const Divider(height: 20),
              _buildSeasonalGenres(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    String? subtitle,
    bool showNavigationIcon = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showNavigationIcon)
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
      ],
    );
  }

  Widget _buildSeasonalGenres(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.wb_sunny, color: Colors.deepOrange, size: 24),
            const SizedBox(width: 12),
            Text(
              'Seasonal Reading Preferences',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                topGenreBySeason.entries.map((entry) {
                  final seasonIcons = {
                    'Winter': '❄️',
                    'Spring': '🌸',
                    'Summer': '☀️',
                    'Fall': '🍂',
                  };
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${seasonIcons[entry.key] ?? ''} ${entry.key}: ${entry.value}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
