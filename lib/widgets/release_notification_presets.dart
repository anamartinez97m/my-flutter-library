import 'package:flutter/material.dart';
import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/utils/release_date_helper.dart';

/// Quick picks for a release notification (release day, 1 day or 1 week
/// before) and a warning when the notification is after the release.
class ReleaseNotificationPresets extends StatelessWidget {
  final DateTime? releaseDate;
  final DateTime? notificationDateTime;
  final ValueChanged<DateTime> onSelected;

  const ReleaseNotificationPresets({
    super.key,
    required this.releaseDate,
    required this.notificationDateTime,
    required this.onSelected,
  });

  String _label(AppLocalizations l10n, int daysBefore) {
    switch (daysBefore) {
      case 0:
        return l10n.notify_on_release_day;
      case 1:
        return l10n.notify_one_day_before;
      default:
        return l10n.notify_one_week_before;
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = releaseDate;
    if (release == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final selected = releaseNotificationOffset(release, notificationDateTime);
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final daysBefore in releaseNotificationOffsets)
                Builder(
                  builder: (context) {
                    final at = releaseNotificationAt(
                      release,
                      daysBefore,
                      timeOf: notificationDateTime,
                    );
                    return ChoiceChip(
                      label: Text(_label(l10n, daysBefore)),
                      selected: selected == daysBefore,
                      onSelected:
                          at.isAfter(now) ? (_) => onSelected(at) : null,
                    );
                  },
                ),
            ],
          ),
          if (isNotificationAfterRelease(release, notificationDateTime))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.notification_after_release_warning,
                      style: TextStyle(color: colorScheme.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
