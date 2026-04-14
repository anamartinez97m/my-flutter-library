import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';

/// Card showing reading session distribution across 4 time-of-day slots.
class ReadingTimeOfDayCard extends StatelessWidget {
  final Map<String, Map<String, dynamic>> readingTimeOfDay;

  const ReadingTimeOfDayCard({super.key, required this.readingTimeOfDay});

  static const List<String> _slotOrder = [
    'late_night',
    'morning',
    'afternoon',
    'night',
  ];

  static const Map<String, IconData> _slotIcons = {
    'late_night': Icons.dark_mode,
    'morning': Icons.wb_sunny,
    'afternoon': Icons.light_mode,
    'night': Icons.nights_stay,
  };

  static const Map<String, Color> _slotColors = {
    'late_night': Color(0xFF5C6BC0),
    'morning': Color(0xFFFF9800),
    'afternoon': Color(0xFFE65100),
    'night': Color(0xFF283593),
  };

  static const Map<String, String> _slotTimeRanges = {
    'late_night': '00:00 - 06:00',
    'morning': '06:00 - 12:00',
    'afternoon': '12:00 - 18:00',
    'night': '18:00 - 00:00',
  };

  String _getSlotLabel(String slot, AppLocalizations l10n) {
    switch (slot) {
      case 'late_night':
        return l10n.time_slot_late_night;
      case 'morning':
        return l10n.time_slot_morning;
      case 'afternoon':
        return l10n.time_slot_afternoon;
      case 'night':
        return l10n.time_slot_night;
      default:
        return slot;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if there's any data
    final totalSessions = _slotOrder.fold<int>(
      0,
      (sum, slot) => sum + ((readingTimeOfDay[slot]?['count'] as int?) ?? 0),
    );
    if (totalSessions == 0) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.reading_time_of_day,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Icon(Icons.access_time, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.no_session_data,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    final maxCount = _slotOrder.fold<int>(0, (max, slot) {
      final count = (readingTimeOfDay[slot]?['count'] as int?) ?? 0;
      return count > max ? count : max;
    });

    // Find the favorite time slot
    String favoriteSlot = _slotOrder.first;
    int favoriteCount = 0;
    for (var slot in _slotOrder) {
      final count = (readingTimeOfDay[slot]?['count'] as int?) ?? 0;
      if (count > favoriteCount) {
        favoriteCount = count;
        favoriteSlot = slot;
      }
    }

    final favColor = _slotColors[favoriteSlot] ?? Colors.grey;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              l10n.reading_time_of_day,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Favorite time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: favColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: favColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_slotIcons[favoriteSlot], size: 16, color: favColor),
                  const SizedBox(width: 6),
                  Text(
                    l10n.favorite_reading_time(
                      _getSlotLabel(favoriteSlot, l10n),
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Horizontal bars for each slot
            ..._slotOrder.map((slot) {
              final count = (readingTimeOfDay[slot]?['count'] as int?) ?? 0;
              final totalMinutes =
                  (readingTimeOfDay[slot]?['totalMinutes'] as int?) ?? 0;
              final percentage = maxCount > 0 ? count / maxCount : 0.0;
              final isFavorite = slot == favoriteSlot;
              final color = _slotColors[slot] ?? Colors.grey;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(_slotIcons[slot], size: 20, color: color),
                            const SizedBox(width: 8),
                            Text(
                              _getSlotLabel(slot, l10n),
                              style: TextStyle(
                                fontWeight:
                                    isFavorite
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _slotTimeRanges[slot] ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          count > 0
                              ? '$count${totalMinutes > 0 ? ' (${_formatMinutes(totalMinutes)})' : ''}'
                              : '0',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
}
