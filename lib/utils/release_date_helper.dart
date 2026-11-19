import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/utils/publication_date.dart';

/// Parses a stored date that is either ISO 8601 or a `YYYYMMDD` string.
DateTime? parseStoredDate(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value.length == 8 && int.tryParse(value) != null) {
    return DateTime(
      int.parse(value.substring(0, 4)),
      int.parse(value.substring(4, 6)),
      int.parse(value.substring(6, 8)),
    );
  }
  return DateTime.tryParse(value);
}

/// The day a TBReleased book comes out.
///
/// Uses `release_date`, falling back to a full original publication date.
/// The notification date is never used: it can be set days before release.
DateTime? bookReleaseDate(Book book) {
  final releaseDate = parseStoredDate(book.releaseDate);
  if (releaseDate != null) {
    return DateTime(releaseDate.year, releaseDate.month, releaseDate.day);
  }
  return PublicationDate.fromBook(book)?.fullDate;
}

/// Notification presets, in days before the release date.
const releaseNotificationOffsets = <int>[0, 1, 7];

/// The preset (days before release) that [notification] matches, if any.
int? releaseNotificationOffset(DateTime? release, DateTime? notification) {
  if (release == null || notification == null) return null;
  final releaseDay = DateTime.utc(release.year, release.month, release.day);
  final notificationDay = DateTime.utc(
    notification.year,
    notification.month,
    notification.day,
  );
  final days = releaseDay.difference(notificationDay).inDays;
  return releaseNotificationOffsets.contains(days) ? days : null;
}

/// A notification [daysBefore] the release day at the time of [timeOf]
/// (09:00 when null).
DateTime releaseNotificationAt(
  DateTime release,
  int daysBefore, {
  DateTime? timeOf,
}) {
  return DateTime(
    release.year,
    release.month,
    release.day - daysBefore,
    timeOf?.hour ?? 9,
    timeOf?.minute ?? 0,
  );
}

/// Whether [notification] falls on a later day than [release].
bool isNotificationAfterRelease(DateTime? release, DateTime? notification) {
  if (release == null || notification == null) return false;
  final releaseDay = DateTime(release.year, release.month, release.day);
  final notificationDay = DateTime(
    notification.year,
    notification.month,
    notification.day,
  );
  return notificationDay.isAfter(releaseDay);
}
