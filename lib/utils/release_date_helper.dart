import 'package:myrandomlibrary/model/book.dart';

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

/// The date a TBReleased book is expected to come out.
///
/// The release notification date goes first because it is the date the home
/// card counts down to, so sorting by this matches what the user sees. Falls
/// back to `release_date` and to a `YYYYMMDD` publication year.
DateTime? bookReleaseDate(Book book) {
  final notificationDate = parseStoredDate(book.notificationDatetime);
  if (notificationDate != null) return notificationDate;

  final releaseDate = parseStoredDate(book.releaseDate);
  if (releaseDate != null) return releaseDate;

  final publicationDate = book.originalPublicationYear;
  if (publicationDate != null && publicationDate > 9999) {
    return DateTime(
      publicationDate ~/ 10000,
      (publicationDate % 10000) ~/ 100,
      publicationDate % 100,
    );
  }
  return null;
}
