import 'dart:math';

import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/screens/saga_completion_detail.dart';

/// New Sagas & Series statistics screen matching the redesigned UI.
/// Shows a circular completion rate chart and a status breakdown with bars.
/// Tapping a status breakdown row navigates to the detail screen.
class SagasSeriesScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>> sagaStats;
  final int completedSagas;
  final int partialSagas;
  final int unstartedSagas;
  final List<Book> books;

  const SagasSeriesScreen({
    super.key,
    required this.sagaStats,
    required this.completedSagas,
    required this.partialSagas,
    required this.unstartedSagas,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = completedSagas + partialSagas + unstartedSagas;
    final completionPercentage =
        total > 0 ? (completedSagas / total * 100).round() : 0;

    const kBg = Color(0xFFFDF8F6);
    const kPrimary = Color(0xFF43102B);
    const kSecondary = Color(0xFF894B67);
    const kMuted = Color(0xFFD5C2C7);
    const kText = Color(0xFF1C1B1A);
    const kSub = Color(0xFF514348);
    const kBorder = Color(0x4DD5C2C7);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.section_sagas_series,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: kPrimary,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFD5C2C7)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Completion Rate Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
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
                    l10n.completion_rate,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 192,
                      height: 192,
                      child: CustomPaint(
                        painter: _CompletionRingPainter(
                          percentage: completionPercentage / 100.0,
                          primaryColor: kPrimary,
                          trackColor: kMuted,
                        ),
                        child: Center(
                          child: Text(
                            '$completionPercentage%',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: kText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      l10n.n_series_completed(completedSagas.toString()),
                      style: const TextStyle(fontSize: 14, color: kSub),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status Breakdown Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorder),
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      l10n.status_breakdown,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: kText,
                      ),
                    ),
                  ),
                  _buildStatusBar(
                    label: l10n.completed,
                    count: completedSagas,
                    total: total,
                    color: kPrimary,
                    labelColor: kPrimary,
                    onTap: () => _openDetail(context, 0),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusBar(
                    label: l10n.in_progress,
                    count: partialSagas,
                    total: total,
                    color: kSecondary,
                    labelColor: kSecondary,
                    onTap: () => _openDetail(context, 1),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusBar(
                    label: l10n.not_started,
                    count: unstartedSagas,
                    total: total,
                    color: kMuted,
                    labelColor: kSub,
                    onTap: () => _openDetail(context, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openDetail(context, 0),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View more',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: kPrimary, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, int initialTabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => SagaCompletionDetailScreen(
              sagaStats: sagaStats,
              books: books,
              initialTabIndex: initialTabIndex,
            ),
      ),
    );
  }

  Widget _buildStatusBar({
    required String label,
    required int count,
    required int total,
    required Color color,
    required Color labelColor,
    VoidCallback? onTap,
  }) {
    final fraction = total > 0 ? count / total : 0.0;
    const kText = Color(0xFF1C1B1A);
    const kBarBg = Color(0xFFE6E2DF);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                      letterSpacing: 0.26,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '$count',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: Container(
              height: 8,
              width: double.infinity,
              color: kBarBg,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the circular completion ring
class _CompletionRingPainter extends CustomPainter {
  final double percentage;
  final Color primaryColor;
  final Color trackColor;

  _CompletionRingPainter({
    required this.percentage,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    const strokeWidth = 14.0;

    // Track
    final trackPaint =
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CompletionRingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}
