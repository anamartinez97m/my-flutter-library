import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myrandomlibrary/config/v2_design_system.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/utils/club_daily_target.dart';

/// The daily goal line of a reading club card: pages/% a day and days left,
/// "Book finished", "Target date passed" or a hint to add a target date.
class ClubDailyTargetView extends StatelessWidget {
  final String? targetDate;
  final num? readingProgress;
  final String? progressType;
  final int? pages;
  final bool isRead;
  final bool compact;

  const ClubDailyTargetView({
    super.key,
    required this.targetDate,
    this.readingProgress,
    this.progressType,
    this.pages,
    this.isRead = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = V2Colors.primary;
    final sub = V2Colors.textSecondary;
    final mainSize = compact ? 12.0 : 14.0;
    final iconSize = compact ? 14.0 : 16.0;
    final target = ClubDailyTarget.compute(
      targetDate: targetDate,
      readingProgress: readingProgress,
      progressType: progressType,
      pages: pages,
      isRead: isRead,
    );

    if (target == null) {
      return Text(
        l10n.club_add_target_hint,
        style: TextStyle(
          fontSize: compact ? 11 : 13,
          color: sub,
          fontStyle: FontStyle.italic,
        ),
        maxLines: compact ? 2 : null,
        overflow: compact ? TextOverflow.ellipsis : null,
      );
    }

    if (target.finished || target.overdue) {
      final color =
          target.overdue ? Theme.of(context).colorScheme.error : primary;
      return Row(
        children: [
          Icon(
            target.overdue ? Icons.event_busy : Icons.check_circle,
            size: iconSize,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              target.overdue
                  ? l10n.club_target_passed
                  : l10n.club_book_finished,
              style: TextStyle(
                fontSize: mainSize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final percent = NumberFormat(
      '0.#',
      Localizations.localeOf(context).toString(),
    ).format(target.percentPerDay);
    final goal =
        target.pagesPerDay != null
            ? l10n.club_daily_pages_percent(target.pagesPerDay!, percent)
            : l10n.club_daily_percent(percent);

    return Row(
      children: [
        Icon(Icons.auto_stories, size: iconSize, color: primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            goal,
            style: TextStyle(
              fontSize: mainSize,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
            maxLines: compact ? 1 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.club_days_left(target.daysLeft),
          style: TextStyle(fontSize: compact ? 11 : 12, color: sub),
        ),
      ],
    );
  }
}
