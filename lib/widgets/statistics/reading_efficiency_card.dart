import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

const _kPrimary = Color(0xFF43102B);
const _kSecondary = Color(0xFF894B67);
const _kTertiary = Color(0xFFBC92A6);
const _kSub = Color(0xFF514348);
const _kDivider = Color(0xFFE6E2DF);

/// Reading Efficiency — Insight-first card.
///
/// Turns the raw efficiency metrics into plain-language takeaways and
/// projections, keeping the supporting numbers as secondary context.
class ReadingEfficiencyCard extends StatelessWidget {
  final double readingVelocity;
  final double averageDaysToFinish;
  final double averageBooksPerYear;
  final int booksUsedInAverageDays;
  final int yearsWithBooks;

  const ReadingEfficiencyCard({
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
    final projectedThisYear = _projectedBooksThisYear();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary insight
        _InsightRow(
          icon: Icons.timer,
          color: _kSecondary,
          headline:
              averageDaysToFinish > 0
                  ? l10n.finish_book_every_n_days(
                    averageDaysToFinish.toStringAsFixed(1),
                  )
                  : l10n.no_data_available,
          caption: l10n.based_on_books_with_data(booksUsedInAverageDays),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: _kDivider),
        const SizedBox(height: 16),
        // Secondary insight
        _InsightRow(
          icon: Icons.calendar_today,
          color: _kTertiary,
          headline:
              projectedThisYear > 0
                  ? l10n.projected_books_this_year(
                    projectedThisYear.toStringAsFixed(0),
                  )
                  : l10n.no_data_available,
          caption: l10n.based_on_years_of_data(yearsWithBooks),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: _kDivider),
        const SizedBox(height: 16),
        // Supporting metrics row
        Row(
          children: [
            _SupportStat(
              icon: Icons.speed,
              value: readingVelocity.toStringAsFixed(1),
              label: l10n.pages_per_day,
              color: _kPrimary,
            ),
            const SizedBox(width: 16),
            _SupportStat(
              icon: Icons.trending_up,
              value: averageBooksPerYear.toStringAsFixed(1),
              label: l10n.books_per_year,
              color: _kPrimary,
            ),
          ],
        ),
      ],
    );
  }

  double _projectedBooksThisYear() {
    if (averageDaysToFinish <= 0) return 0;
    return 365 / averageDaysToFinish;
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String headline;
  final String caption;

  const _InsightRow({
    required this.icon,
    required this.color,
    required this.headline,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: _kSub,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SupportStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  color: _kSub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
