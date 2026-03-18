import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// 365-day reading heatmap card — 12 month columns x 31 day rows, binary color.
class DailyReadingHeatmapCard extends StatefulWidget {
  final Map<int, Map<String, int>> dailyHeatmap;

  const DailyReadingHeatmapCard({super.key, required this.dailyHeatmap});

  @override
  State<DailyReadingHeatmapCard> createState() =>
      _DailyReadingHeatmapCardState();
}

class _DailyReadingHeatmapCardState extends State<DailyReadingHeatmapCard> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _initializeYear();
  }

  void _initializeYear() {
    if (widget.dailyHeatmap.isNotEmpty) {
      final sortedYears =
          widget.dailyHeatmap.keys.toList()..sort((a, b) => b.compareTo(a));
      _selectedYear = sortedYears.first;
    } else {
      _selectedYear = DateTime.now().year;
    }
  }

  @override
  void didUpdateWidget(DailyReadingHeatmapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyHeatmap != widget.dailyHeatmap) {
      _initializeYear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dailyHeatmap.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedYears =
        widget.dailyHeatmap.keys.toList()..sort((a, b) => b.compareTo(a));
    final yearData = widget.dailyHeatmap[_selectedYear] ?? {};

    // Compute days read
    final daysRead = yearData.keys.length;
    final totalDaysInYear =
        DateTime(
          _selectedYear + 1,
          1,
          1,
        ).difference(DateTime(_selectedYear, 1, 1)).inDays;
    final percentage =
        totalDaysInYear > 0
            ? (daysRead / totalDaysInYear * 100).toStringAsFixed(1)
            : '0';

    final l10n = AppLocalizations.of(context)!;
    final monthAbbrs = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + year selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.daily_reading_heatmap,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    underline: const SizedBox.shrink(),
                    isDense: true,
                    items:
                        sortedYears.map((year) {
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
            const SizedBox(height: 4),
            // Summary text
            Text(
              l10n.days_read_summary(
                daysRead.toString(),
                totalDaysInYear.toString(),
                percentage,
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            // Grid: 12 month columns x 31 day rows
            // Month headers row + 31 rows of day cells
            LayoutBuilder(
              builder: (context, constraints) {
                const dayLabelWidth = 20.0;
                final availableWidth = constraints.maxWidth - dayLabelWidth;
                final cellSize = (availableWidth / 12 - 2).clamp(4.0, 14.0);
                const gap = 3.0;

                return Column(
                  children: [
                    // Month header row
                    Row(
                      children: [
                        const SizedBox(width: dayLabelWidth),
                        ...List.generate(12, (monthIndex) {
                          return SizedBox(
                            width: cellSize + gap,
                            child: Center(
                              child: Text(
                                monthAbbrs[monthIndex],
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 31 day rows
                    ...List.generate(31, (dayIndex) {
                      final day = dayIndex + 1;
                      return Row(
                        children: [
                          SizedBox(
                            width: dayLabelWidth,
                            child: Text(
                              '$day',
                              style: const TextStyle(fontSize: 7),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ...List.generate(12, (monthIndex) {
                            final month = monthIndex + 1;
                            final daysInMonth = DateUtils.getDaysInMonth(
                              _selectedYear,
                              month,
                            );
                            // If this day doesn't exist in this month, show empty
                            if (day > daysInMonth) {
                              return SizedBox(
                                width: cellSize + gap,
                                height: cellSize + gap,
                              );
                            }
                            final dayKey =
                                '$_selectedYear-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                            final didRead = yearData.containsKey(dayKey);
                            return Container(
                              width: cellSize,
                              height: cellSize,
                              margin: const EdgeInsets.all(gap / 2),
                              decoration: BoxDecoration(
                                color:
                                    didRead ? Colors.green : Colors.grey[200],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
