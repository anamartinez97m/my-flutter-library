import 'package:intl/intl.dart';
import 'package:myrandomlibrary/model/book.dart';

/// An original publication date known to the year, the month or the day.
///
/// Stored in `book.original_publication_date` as `YYYY-MM` or `YYYY-MM-DD`
/// (null when only the year is known); the year is also kept in
/// `book.original_publication_year`.
class PublicationDate {
  final int year;
  final int? month;
  final int? day;

  const PublicationDate(this.year, {this.month, this.day})
    : assert(day == null || month != null);

  /// Builds a date from form input, dropping a day the month doesn't have.
  static PublicationDate? fromParts(int? year, int? month, int? day) {
    if (year == null || year <= 0) return null;
    if (month == null || month < 1 || month > 12) {
      return PublicationDate(year);
    }
    if (day == null || day < 1 || day > daysInMonth(year, month)) {
      return PublicationDate(year, month: month);
    }
    return PublicationDate(year, month: month, day: day);
  }

  /// Parses `YYYY`, `YYYY-MM`, `YYYY-MM-DD`, an ISO datetime or the legacy
  /// `YYYYMMDD` form.
  static PublicationDate? parse(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;

    final compact = RegExp(r'^(\d{4})(\d{2})(\d{2})$').firstMatch(text);
    if (compact != null) {
      return fromParts(
        int.parse(compact.group(1)!),
        int.parse(compact.group(2)!),
        int.parse(compact.group(3)!),
      );
    }

    final iso = RegExp(
      r'^(\d{1,4})(?:[-/](\d{1,2})(?:[-/](\d{1,2}))?)?(?:[T ].*)?$',
    ).firstMatch(text);
    if (iso == null) return null;
    return fromParts(
      int.parse(iso.group(1)!),
      iso.group(2) != null ? int.parse(iso.group(2)!) : null,
      iso.group(3) != null ? int.parse(iso.group(3)!) : null,
    );
  }

  /// Reads a year column value, which older versions filled with `YYYYMMDD`
  /// for TBReleased books.
  static PublicationDate? fromYearColumn(int? value) {
    if (value == null || value <= 0) return null;
    if (value > 9999) return parse(value.toString());
    return PublicationDate(value);
  }

  static PublicationDate? fromBook(Book book) {
    final fromYear = fromYearColumn(book.originalPublicationYear);
    final stored = parse(book.originalPublicationDate);
    if (stored != null && (fromYear == null || fromYear.year == stored.year)) {
      return stored;
    }
    return fromYear;
  }

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  bool get hasMonth => month != null;
  bool get hasDay => day != null;

  /// The full date when the day is known.
  DateTime? get fullDate => hasDay ? DateTime(year, month!, day!) : null;

  /// Value for `original_publication_date`, null when only the year is known.
  String? toStorage() {
    if (!hasMonth) return null;
    final y = year.toString().padLeft(4, '0');
    final m = month!.toString().padLeft(2, '0');
    if (!hasDay) return '$y-$m';
    return '$y-$m-${day!.toString().padLeft(2, '0')}';
  }

  /// `2020`, `May 2020` / `mayo de 2020`, or `14/05/2020`.
  String format([String? locale]) {
    if (hasDay) {
      return '${day!.toString().padLeft(2, '0')}/'
          '${month!.toString().padLeft(2, '0')}/$year';
    }
    if (hasMonth) {
      return DateFormat.yMMMM(locale).format(DateTime(year, month!));
    }
    return year.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is PublicationDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toStorage() ?? year.toString();
}
