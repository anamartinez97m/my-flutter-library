import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

const _kPrimary = Color(0xFF43102B);
const _kTertiary = Color(0xFFBC92A6);
const _kSub = Color(0xFF514348);
const _kMuted = Color(0xFFD5C2C7);

/// Reading Efficiency 3 — Pace profile mini-chart.
///
/// A segmented bar compares books read faster than the user's average pace
/// against books read slower, making the efficiency distribution explicit.
class ReadingEfficiency3Card extends StatelessWidget {
  final double efficiencyPercentage;
  final int booksFasterThanAverage;
  final int booksSlowerThanAverage;
  final int totalBooksWithData;

  const ReadingEfficiency3Card({
    super.key,
    required this.efficiencyPercentage,
    required this.booksFasterThanAverage,
    required this.booksSlowerThanAverage,
    required this.totalBooksWithData,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = totalBooksWithData;
    final fasterPct = total > 0 ? booksFasterThanAverage / total : 0.0;
    final slowerPct = total > 0 ? booksSlowerThanAverage / total : 0.0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reading_efficiency_3,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.based_on_n_books('$totalBooksWithData'),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: _kSub,
            ),
          ),
          const SizedBox(height: 24),
          // Segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 28,
              child: Row(
                children: [
                  if (booksFasterThanAverage > 0)
                    Expanded(
                      flex: (fasterPct * 1000).round().clamp(1, 1000),
                      child: Container(
                        color: _kPrimary,
                        alignment: Alignment.center,
                        child: Text(
                          '${(fasterPct * 100).round()}%',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (booksSlowerThanAverage > 0)
                    Expanded(
                      flex: (slowerPct * 1000).round().clamp(1, 1000),
                      child: Container(
                        color: _kMuted,
                        alignment: Alignment.center,
                        child: Text(
                          '${(slowerPct * 100).round()}%',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ),
                  if (total == 0)
                    const Expanded(
                      child: ColoredBox(
                        color: _kMuted,
                        child: Center(
                          child: Text(
                            '0%',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _kPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            children: [
              _LegendDot(color: _kPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.n_books_faster_than_average('$booksFasterThanAverage'),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: _kSub,
                  ),
                ),
              ),
              _LegendDot(color: _kMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.n_books_slower_than_average('$booksSlowerThanAverage'),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: _kSub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Score pill
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF8F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x1A27231E)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.speed, color: _kTertiary, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${efficiencyPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.books_faster_than_average,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: _kSub,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
