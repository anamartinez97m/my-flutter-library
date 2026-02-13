import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
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
              AppLocalizations.of(context)!.reading_insights,
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
              title: AppLocalizations.of(context)!.reading_streaks,
              value:
                  '${AppLocalizations.of(context)!.current_label}: $currentStreak ${AppLocalizations.of(context)!.days} | ${AppLocalizations.of(context)!.best}: $longestStreak ${AppLocalizations.of(context)!.days}',
            ),
            const Divider(height: 20),

            // DNF Rate
            _buildInsightRow(
              context,
              icon: Icons.close,
              color: Colors.red,
              title: AppLocalizations.of(context)!.dnf_rate,
              value:
                  '$dnfCount ${AppLocalizations.of(context)!.books} (${dnfRate.toStringAsFixed(1)}%)',
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
                    title: AppLocalizations.of(context)!.re_reads,
                    value:
                        '$rereadCount ${AppLocalizations.of(context)!.books}',
                    subtitle:
                        mostRereadBook != null
                            ? '${AppLocalizations.of(context)!.most}: ${mostRereadBook!['name']} (${mostRereadBook!['count']}x)'
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
              title: AppLocalizations.of(context)!.series_vs_standalone,
              value:
                  '$seriesBooks ${AppLocalizations.of(context)!.series} (${seriesPercentage.toStringAsFixed(1)}%) | $standaloneBooks ${AppLocalizations.of(context)!.standalone}',
              subtitle:
                  '${AppLocalizations.of(context)!.read_label}: $seriesBooksRead ${AppLocalizations.of(context)!.series} + $standaloneBooksRead ${AppLocalizations.of(context)!.standalone}',
            ),
            const Divider(height: 20),

            // Personal Bests
            _buildInsightRow(
              context,
              icon: Icons.emoji_events,
              color: Colors.amber,
              title: AppLocalizations.of(context)!.personal_bests,
              value:
                  '${AppLocalizations.of(context)!.most_in_month}: $mostBooksInMonth${bestMonth != null ? ' ($bestMonth)' : ''}',
              subtitle:
                  fastestDays != null && fastestBookName != null
                      ? '${AppLocalizations.of(context)!.fastest}: $fastestDays ${AppLocalizations.of(context)!.days} ($fastestBookName)'
                      : null,
            ),
            const Divider(height: 20),

            // Milestones - Books Owned
            _buildInsightRow(
              context,
              icon: Icons.flag,
              color: Colors.green,
              title: AppLocalizations.of(context)!.next_milestone_owned,
              value:
                  '$nextMilestoneOwned ${AppLocalizations.of(context)!.books} ($booksToMilestoneOwned ${AppLocalizations.of(context)!.to_go})',
            ),
            const Divider(height: 20),

            // Milestones - Books Read
            _buildInsightRow(
              context,
              icon: Icons.menu_book,
              color: Colors.blue,
              title: AppLocalizations.of(context)!.next_milestone_read,
              value:
                  '$nextMilestoneRead ${AppLocalizations.of(context)!.books} ($booksToMilestoneRead ${AppLocalizations.of(context)!.to_go})',
            ),
            const Divider(height: 20),

            // Binge Reading
            _buildInsightRow(
              context,
              icon: Icons.fast_forward,
              color: Colors.purple,
              title: AppLocalizations.of(context)!.binge_reading_series,
              value:
                  '${bingePercentage.toStringAsFixed(1)}% ${AppLocalizations.of(context)!.binge_reading_description}',
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
              AppLocalizations.of(context)!.seasonal_reading_preferences,
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
