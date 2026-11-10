/// How much of a book has to be read each day to finish it by a reading
/// club's target date. Today counts as one of the remaining reading days.
class ClubDailyTarget {
  final int daysLeft;
  final double percentPerDay;
  final int? pagesPerDay;
  final bool finished;
  final bool overdue;

  const ClubDailyTarget({
    required this.daysLeft,
    required this.percentPerDay,
    this.pagesPerDay,
    this.finished = false,
    this.overdue = false,
  });

  /// Returns null when [targetDate] is missing or not a `yyyy-MM-dd` date.
  static ClubDailyTarget? compute({
    required String? targetDate,
    required num? readingProgress,
    required String? progressType,
    required int? pages,
    bool isRead = false,
    DateTime? now,
  }) {
    final target = DateTime.tryParse(targetDate?.trim() ?? '');
    if (target == null) return null;

    final today = now ?? DateTime.now();
    final daysLeft =
        DateTime.utc(
          target.year,
          target.month,
          target.day,
        ).difference(DateTime.utc(today.year, today.month, today.day)).inDays +
        1;

    final totalPages = (pages != null && pages > 0) ? pages : null;
    final progress = (readingProgress ?? 0).toDouble();
    final double fractionRead;
    if (progressType == 'pages') {
      fractionRead = totalPages != null ? progress / totalPages : 0;
    } else {
      fractionRead = progress / 100;
    }
    final remaining = (1 - fractionRead).clamp(0.0, 1.0);

    if (isRead || remaining <= 0) {
      return ClubDailyTarget(
        daysLeft: daysLeft,
        percentPerDay: 0,
        pagesPerDay: totalPages != null ? 0 : null,
        finished: true,
      );
    }
    if (daysLeft <= 0) {
      return ClubDailyTarget(
        daysLeft: daysLeft,
        percentPerDay: 0,
        overdue: true,
      );
    }

    final percentPerDay = (remaining * 1000 / daysLeft - 1e-9).ceil() / 10;
    int? pagesPerDay;
    if (totalPages != null) {
      final remainingPages =
          progressType == 'pages'
              ? (totalPages - progress).clamp(0, totalPages)
              : totalPages * remaining;
      pagesPerDay = (remainingPages / daysLeft - 1e-9).ceil();
    }
    return ClubDailyTarget(
      daysLeft: daysLeft,
      percentPerDay: percentPerDay,
      pagesPerDay: pagesPerDay,
    );
  }
}
