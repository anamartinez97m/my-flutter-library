import 'package:flutter/material.dart';

class StatisticsShimmer extends StatelessWidget {
  const StatisticsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bento cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _placeholderBox(height: 150, borderRadius: 16)),
              const SizedBox(width: 16),
              Expanded(child: _placeholderBox(height: 150, borderRadius: 16)),
            ],
          ),
          const SizedBox(height: 24),
          // Competition card
          _placeholderBox(height: 140, borderRadius: 12, fullWidth: true),
          const SizedBox(height: 24),
          // Quick stats
          _placeholderBox(height: 90, borderRadius: 12, fullWidth: true),
          const SizedBox(height: 8),
          // Hint line
          Center(
            child: _placeholderBox(width: 220, height: 12, borderRadius: 6),
          ),
          const SizedBox(height: 24),
          // Section nav cards
          ...List.generate(
            7,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _placeholderBox(
                height: 60,
                borderRadius: 12,
                fullWidth: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBox({
    double? width,
    required double height,
    required double borderRadius,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
