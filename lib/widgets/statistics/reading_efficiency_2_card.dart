import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

const _kPrimary = Color(0xFF43102B);
const _kSecondary = Color(0xFF894B67);
const _kTertiary = Color(0xFFBC92A6);
const _kSub = Color(0xFF514348);

/// Reading Efficiency 2 — Compact 3-column metric row.
///
/// Converts velocity, days-to-finish, and books-per-year into a horizontal
/// row of small tiles for quick scanning.
class ReadingEfficiency2Card extends StatelessWidget {
  final double readingVelocity;
  final double averageDaysToFinish;
  final double averageBooksPerYear;
  final int booksUsedInAverageDays;
  final int yearsWithBooks;

  const ReadingEfficiency2Card({
    super.key,
    required this.readingVelocity,
    required this.averageDaysToFinish,
    required this.averageBooksPerYear,
    required this.booksUsedInAverageDays,
    required this.yearsWithBooks,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = [
      _Metric(
        icon: Icons.speed,
        value: readingVelocity.toStringAsFixed(1),
        unit: l10n.pages_per_day,
        subtitle: l10n.based_on_books_with_data(booksUsedInAverageDays),
        color: _kTertiary,
      ),
      _Metric(
        icon: Icons.timer,
        value: averageDaysToFinish.toStringAsFixed(1),
        unit: l10n.days,
        subtitle: l10n.avg_time_to_finish,
        color: _kSecondary,
      ),
      _Metric(
        icon: Icons.trending_up,
        value: averageBooksPerYear.toStringAsFixed(1),
        unit: l10n.books_per_year,
        subtitle: l10n.based_on_years_of_data(yearsWithBooks),
        color: _kPrimary,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A27231E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.reading_efficiency_2,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children:
                metrics.asMap().entries.map((entry) {
                  final isLast = entry.key == metrics.length - 1;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: isLast ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF8F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x1A27231E)),
                      ),
                      child: _MetricTile(metric: entry.value),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  final IconData icon;
  final String value;
  final String unit;
  final String subtitle;
  final Color color;

  _Metric({
    required this.icon,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.color,
  });
}

class _MetricTile extends StatelessWidget {
  final _Metric metric;

  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(metric.icon, color: metric.color, size: 22),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              metric.value,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: metric.color,
              ),
            ),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                metric.unit,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  color: _kSub,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            metric.subtitle,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              color: _kSub,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
