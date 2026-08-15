import 'package:flutter/material.dart';

class RandomShimmer extends StatelessWidget {
  const RandomShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Center(
                  child: _placeholderBox(
                    width: 180,
                    height: 24,
                    borderRadius: 6,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Center(
                  child: _placeholderBox(
                    width: 240,
                    height: 14,
                    borderRadius: 4,
                  ),
                ),
                const SizedBox(height: 32),
                // Filter rows
                ...List.generate(
                  6,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FractionallySizedBox(
                      widthFactor: 0.85,
                      child: _placeholderBox(
                        height: 56,
                        borderRadius: 12,
                        fullWidth: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Action bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(color: Colors.white),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _placeholderBox(
                  height: 44,
                  borderRadius: 9999,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _placeholderBox(
                  height: 44,
                  borderRadius: 9999,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ],
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
