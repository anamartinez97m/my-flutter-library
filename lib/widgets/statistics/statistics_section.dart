import 'package:flutter/material.dart';

class StatisticsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool initiallyExpanded;
  final List<Widget> children;

  const StatisticsSection({
    super.key,
    required this.title,
    required this.icon,
    this.initiallyExpanded = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              bottom: 16,
            ),
            child: Column(
              children: children.map((child) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: child,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
