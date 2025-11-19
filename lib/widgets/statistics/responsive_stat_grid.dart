import 'package:flutter/material.dart';

/// A responsive grid that displays statistics cards
/// - 1 column on phones (< 600dp)
/// - 2 columns on tablets (>= 600dp)
class ResponsiveStatGrid extends StatelessWidget {
  final List<Widget> children;

  const ResponsiveStatGrid({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    if (!isTablet || children.isEmpty) {
      // Phone layout - single column
      return Column(
        children: children.map((child) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: child,
          );
        }).toList(),
      );
    }

    // Tablet layout - two columns
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      final leftChild = children[i];
      final rightChild = i + 1 < children.length ? children[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftChild),
              if (rightChild != null) ...[
                const SizedBox(width: 16),
                Expanded(child: rightChild),
              ] else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}
