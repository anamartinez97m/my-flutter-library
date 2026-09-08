import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

const _kPrimary = Color(0xFF43102B);
const _kSecondary = Color(0xFF894B67);
const _kTertiary = Color(0xFFBC92A6);
const _kSub = Color(0xFF514348);
const _kDivider = Color(0xFFE6E2DF);

/// Reading Efficiency 4 — Speedometer gauge.
///
/// A half-circle gauge maps the user's reading velocity (pages/day) onto a
/// simple scale with a needle and zone labels.
class ReadingEfficiency4Card extends StatelessWidget {
  final double readingVelocity;

  const ReadingEfficiency4Card({super.key, required this.readingVelocity});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxVelocity = _maxScale(readingVelocity);
    final clampedVelocity = readingVelocity.clamp(0.0, maxVelocity);
    final fraction = maxVelocity > 0 ? clampedVelocity / maxVelocity : 0.0;
    final midVelocity = maxVelocity / 2;

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
            l10n.reading_efficiency_4,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.reading_velocity,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: _kSub,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _SpeedometerPainter(
                fraction: fraction,
                maxValue: maxVelocity,
                midValue: midVelocity,
                primaryColor: _kPrimary,
                secondaryColor: _kSecondary,
                tertiaryColor: _kTertiary,
                backgroundColor: _kDivider,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                readingVelocity.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.pages_per_day,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: _kSub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Zone labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ZoneLabel(color: _kTertiary, label: 'Steady'),
              _ZoneLabel(color: _kSecondary, label: 'Avid'),
              _ZoneLabel(color: _kPrimary, label: 'Power'),
            ],
          ),
        ],
      ),
    );
  }

  double _maxScale(double velocity) {
    if (velocity <= 0) return 100;
    // Round up to a friendly ceiling (next 50 or 100).
    if (velocity <= 50) return 50;
    if (velocity <= 100) return 100;
    return ((velocity / 100).ceil() * 100).toDouble();
  }
}

class _ZoneLabel extends StatelessWidget {
  final Color color;
  final String label;

  const _ZoneLabel({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            color: _kSub,
          ),
        ),
      ],
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double fraction;
  final double maxValue;
  final double midValue;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;
  final Color backgroundColor;

  _SpeedometerPainter({
    required this.fraction,
    required this.maxValue,
    required this.midValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width * 0.35;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = pi;
    const sweepAngle = pi;

    // Background arc
    final bgPaint =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepAngle, false, bgPaint);

    // Zone arcs: steady, avid, power
    final zoneSweep = sweepAngle / 3;
    final zonePaintBase =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      rect,
      startAngle,
      zoneSweep,
      false,
      zonePaintBase..color = tertiaryColor,
    );
    canvas.drawArc(
      rect,
      startAngle + zoneSweep,
      zoneSweep,
      false,
      zonePaintBase..color = secondaryColor,
    );
    canvas.drawArc(
      rect,
      startAngle + 2 * zoneSweep,
      zoneSweep,
      false,
      zonePaintBase..color = primaryColor,
    );

    // Tick marks
    final tickPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    for (var i = 0; i <= 10; i++) {
      final angle = pi + (pi * i / 10);
      final inner = Offset(
        center.dx + (radius - 12) * cos(angle),
        center.dy + (radius - 12) * sin(angle),
      );
      final outer = Offset(
        center.dx + (radius + 2) * cos(angle),
        center.dy + (radius + 2) * sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Needle
    final needleAngle = pi + (pi * fraction.clamp(0.0, 1.0));
    final needleEnd = Offset(
      center.dx + (radius - 24) * cos(needleAngle),
      center.dy + (radius - 24) * sin(needleAngle),
    );
    final needlePaint =
        Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    // Pivot dot
    final pivotPaint = Paint()..color = primaryColor;
    canvas.drawCircle(center, 8, pivotPaint);
    canvas.drawCircle(center, 4, Paint()..color = Colors.white);

    // Scale labels
    final labelStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: 10,
      color: _kSub,
      fontWeight: FontWeight.w500,
    );
    _drawLabel(
      canvas,
      '0',
      Offset(center.dx - radius - 10, center.dy + 4),
      labelStyle,
    );
    _drawLabel(
      canvas,
      midValue.round().toString(),
      Offset(center.dx, center.dy - radius + 10),
      labelStyle,
    );
    _drawLabel(
      canvas,
      maxValue.round().toString(),
      Offset(center.dx + radius - 10, center.dy + 4),
      labelStyle,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset, TextStyle style) {
    final span = TextSpan(text: text, style: style);
    final painter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, offset.translate(-painter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
