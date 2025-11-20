import 'package:flutter/material.dart';

class MonthlyHeatmapCard extends StatefulWidget {
  final Map<int, Map<int, int>> monthlyHeatmap;

  const MonthlyHeatmapCard({
    super.key,
    required this.monthlyHeatmap,
  });

  @override
  State<MonthlyHeatmapCard> createState() => _MonthlyHeatmapCardState();
}

class _MonthlyHeatmapCardState extends State<MonthlyHeatmapCard> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    // Default to most recent year or current year
    if (widget.monthlyHeatmap.isNotEmpty) {
      final sortedYears = widget.monthlyHeatmap.keys.toList()..sort((a, b) => b.compareTo(a));
      _selectedYear = sortedYears.first;
    } else {
      _selectedYear = DateTime.now().year;
    }
  }

  String _getMonthAbbr(int month) {
    const monthAbbrs = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return monthAbbrs[month];
  }

  Color _getHeatColor(int count, int maxCount) {
    if (count == 0) return Colors.grey[200]!;
    final intensity = (count / maxCount).clamp(0.0, 1.0);
    return Color.lerp(
      Colors.green[100],
      Colors.green[900],
      intensity,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.monthlyHeatmap.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get available years
    final sortedYears = widget.monthlyHeatmap.keys.toList()..sort((a, b) => b.compareTo(a));
    
    // Get data for selected year
    final yearData = widget.monthlyHeatmap[_selectedYear] ?? {};
    
    // Get max count for color scaling (for selected year only)
    int maxCount = 0;
    for (var count in yearData.values) {
      if (count > maxCount) maxCount = count;
    }
    if (maxCount == 0) maxCount = 1; // Avoid division by zero

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Monthly Reading Heatmap',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Year selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: sortedYears.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(
                              '$year',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        }).toList(),
                        onChanged: (year) {
                          if (year != null) {
                            setState(() {
                              _selectedYear = year;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Books finished per month',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Less',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 4),
                ...List.generate(5, (index) {
                  // Calculate intensity from 0.2 to 1.0 in 5 steps
                  final intensity = (index + 1) * 0.2;
                  final color = Color.lerp(
                    Colors.green[100],
                    Colors.green[900],
                    intensity,
                  )!;
                  return Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text(
                  'More',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Heatmap grid for selected year
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(12, (index) {
                final month = index + 1;
                final count = yearData[month] ?? 0;
                return Tooltip(
                  message: '${_getMonthAbbr(month)} $_selectedYear: $count books',
                  child: Container(
                    width: 60,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getHeatColor(count, maxCount),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getMonthAbbr(month),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: count > maxCount / 2 ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (count > 0)
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: count > maxCount / 2 ? Colors.white : Colors.black87,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
