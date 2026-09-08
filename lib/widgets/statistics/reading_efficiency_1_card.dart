import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// Reading Efficiency 1 — Hero score ring.
///
/// A large circular progress ring shows the percentage of books read faster
/// than the user's average pace. Three compact chips below surface the
/// supporting velocity metrics.
class ReadingEfficiency1Card extends StatelessWidget {
  static const _kPrimary = Color(0xFF43102B);
  static const _kSecondary = Color(0xFF894B67);
  static const _kTertiary = Color(0xFFBC92A6);
  static const _kSub = Color(0xFF514348);
  static const _kDivider = Color(0xFFE6E2DF);

  final double efficiencyPercentage;
  final int booksFasterThanAverage;
  final int booksSlowerThanAverage;
  final int totalBooksWithData;
  final double readingVelocity;
  final double averageDaysToFinish;
  final double averageBooksPerYear;

  const ReadingEfficiency1Card({
    super.key,
    required this.efficiencyPercentage,
    required this.booksFasterThanAverage,
    required this.booksSlowerThanAverage,
    required this.totalBooksWithData,
    required this.readingVelocity,
    required this.averageDaysToFinish,
    required this.averageBooksPerYear,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.reading_efficiency_1,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildScoreRing(),
          const SizedBox(height: 16),
          Text(
            l10n.pace_profile_summary(
              '$booksFasterThanAverage',
              '$booksSlowerThanAverage',
              '$totalBooksWithData',
            ),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: _kSub,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1, color: _kDivider),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildChip(
                  icon: Icons.speed,
                  value: readingVelocity.toStringAsFixed(1),
                  label: l10n.pages_per_day,
                  color: _kTertiary,
                ),
              ),
              Expanded(
                child: _buildChip(
                  icon: Icons.timer,
                  value: averageDaysToFinish.toStringAsFixed(1),
                  label: l10n.days,
                  color: _kSecondary,
                ),
              ),
              Expanded(
                child: _buildChip(
                  icon: Icons.trending_up,
                  value: averageBooksPerYear.toStringAsFixed(1),
                  label: l10n.books_per_year,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRing() {
    final pct = efficiencyPercentage.clamp(0.0, 100.0) / 100.0;
    final color = _efficiencyColor(efficiencyPercentage);
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(160, 160),
            painter: _RingPainter(
              progress: pct,
              progressColor: color,
              backgroundColor: _kDivider,
              strokeWidth: 14,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${efficiencyPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'efficiency',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: _kSub.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _efficiencyColor(double value) {
    if (value >= 75) return _kPrimary;
    if (value >= 50) return _kSecondary;
    return _kTertiary;
  }

  Widget _buildChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            color: _kSub,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final backgroundPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
    final progressPaint =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, 2 * pi, false, backgroundPaint);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
