import 'package:myrandomlibrary/l10n/app_localizations.dart';
import 'package:myrandomlibrary/model/book.dart';

/// What the Android home widget shows for one book.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.title,
    required this.subtitle,
    required this.progressText,
    required this.percent,
    required this.remaining,
  });

  final String title;
  final String subtitle;
  final String progressText;

  /// 0-100, or -1 when the progress can't be expressed as a share.
  final int percent;
  final String remaining;

  factory HomeWidgetSnapshot.fromBook(
    Book book, {
    required int timedSeconds,
    required AppLocalizations l10n,
  }) {
    final saga = book.saga?.trim() ?? '';
    final sagaLine =
        saga.isEmpty
            ? ''
            : (book.nSaga?.trim().isNotEmpty == true
                ? '$saga #${book.nSaga!.trim()}'
                : saga);
    final subtitle = [
      book.author?.trim() ?? '',
      sagaLine,
    ].where((s) => s.isNotEmpty).join(' · ');

    final progress = book.readingProgress ?? 0;
    final pages = book.pages ?? 0;
    String progressText;
    double? fraction;
    if (book.progressType == 'percentage') {
      fraction = progress.clamp(0, 100) / 100;
      progressText = '';
    } else if (pages > 0) {
      fraction = progress.clamp(0, pages) / pages;
      progressText = l10n.widget_pages_progress(progress, pages);
    } else {
      progressText = l10n.widget_pages_only(progress);
    }

    return HomeWidgetSnapshot(
      title: book.name ?? '',
      subtitle: subtitle,
      progressText: progressText,
      percent: fraction == null ? -1 : (fraction * 100).round(),
      remaining: timeLeftLabel(fraction, timedSeconds, l10n),
    );
  }

  /// Time to finish at the pace of the timed sessions so far:
  /// timed seconds × remaining ÷ read. Empty without enough data.
  static String timeLeftLabel(
    double? fraction,
    int timedSeconds,
    AppLocalizations l10n,
  ) {
    if (fraction == null || fraction <= 0 || fraction >= 1) return '';
    if (timedSeconds < 60) return '';
    final minutes = (timedSeconds * (1 - fraction) / fraction / 60).round();
    if (minutes < 1) return '';
    if (minutes < 60) return l10n.widget_time_left_minutes(minutes);
    if (minutes >= 600) {
      return l10n.widget_time_left_hours((minutes / 60).round());
    }
    final rounded = (minutes / 10).round() * 10;
    final h = rounded ~/ 60;
    final m = rounded % 60;
    return m == 0
        ? l10n.widget_time_left_hours(h)
        : l10n.widget_time_left_hours_minutes(h, m);
  }
}
