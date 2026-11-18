import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/utils/publication_date.dart';
import 'package:myrandomlibrary/utils/release_date_helper.dart';

Book _book({
  int? year,
  String? date,
  String? releaseDate,
  String? notification,
}) => Book(
  bookId: 1,
  name: 'Test',
  saga: null,
  nSaga: null,
  sagaUniverse: null,
  formatSagaValue: null,
  isbn: null,
  asin: null,
  pages: null,
  originalPublicationYear: year,
  originalPublicationDate: date,
  loaned: null,
  statusValue: 'TBReleased',
  editorialValue: null,
  languageValue: null,
  placeValue: null,
  formatValue: null,
  createdAt: null,
  dateReadInitial: null,
  dateReadFinal: null,
  readCount: null,
  myRating: null,
  myReview: null,
  releaseDate: releaseDate,
  notificationDatetime: notification,
);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('PublicationDate', () {
    test('parses year, month and exact day precision', () {
      expect(PublicationDate.parse('1997')!.hasMonth, isFalse);
      final month = PublicationDate.parse('1997-06')!;
      expect([month.year, month.month, month.day], [1997, 6, null]);
      final day = PublicationDate.parse('1997-06-26')!;
      expect(day.fullDate, DateTime(1997, 6, 26));
    });

    test('parses legacy YYYYMMDD values', () {
      expect(
        PublicationDate.fromYearColumn(20261120)!.fullDate,
        DateTime(2026, 11, 20),
      );
      expect(PublicationDate.parse('20261120')!.toStorage(), '2026-11-20');
    });

    test('drops invalid parts instead of failing', () {
      expect(PublicationDate.fromParts(2023, 2, 30)!.toStorage(), '2023-02');
      expect(PublicationDate.fromParts(2023, 13, 1)!.hasMonth, isFalse);
      expect(PublicationDate.fromParts(null, 1, 1), isNull);
    });

    test('stores only month or day precision, never just the year', () {
      expect(const PublicationDate(2020).toStorage(), isNull);
      expect(const PublicationDate(2020, month: 3).toStorage(), '2020-03');
    });

    test('ignores a stored date that no longer matches the year', () {
      final date = PublicationDate.fromBook(_book(year: 2021, date: '2020-05'));
      expect([date!.year, date.month], [2021, null]);
    });

    test('formats each precision', () {
      expect(const PublicationDate(2020).format('en'), '2020');
      expect(const PublicationDate(2020, month: 3).format('en'), 'March 2020');
      expect(
        const PublicationDate(2020, month: 3, day: 5).format('en'),
        '05/03/2020',
      );
    });
  });

  group('bookReleaseDate', () {
    test('uses release_date and never the notification date', () {
      final book = _book(
        releaseDate: '2026-12-01T00:00:00.000',
        notification: '2026-11-24T09:00:00.000',
      );
      expect(bookReleaseDate(book), DateTime(2026, 12, 1));
      expect(
        bookReleaseDate(_book(notification: '2026-11-24T09:00:00.000')),
        isNull,
      );
    });

    test('falls back to an exact original publication date', () {
      expect(
        bookReleaseDate(_book(year: 2026, date: '2026-12-01')),
        DateTime(2026, 12, 1),
      );
      expect(bookReleaseDate(_book(year: 2026, date: '2026-12')), isNull);
    });
  });

  group('release notification presets', () {
    final release = DateTime(2026, 12, 1);

    test('matches release day, 1 day and 1 week before', () {
      expect(releaseNotificationOffset(release, DateTime(2026, 12, 1, 9)), 0);
      expect(releaseNotificationOffset(release, DateTime(2026, 11, 30, 20)), 1);
      expect(releaseNotificationOffset(release, DateTime(2026, 11, 24, 9)), 7);
      expect(
        releaseNotificationOffset(release, DateTime(2026, 11, 27, 9)),
        isNull,
      );
    });

    test('keeps the chosen time when moving with the release date', () {
      expect(
        releaseNotificationAt(
          DateTime(2027, 1, 3),
          7,
          timeOf: DateTime(2026, 11, 24, 18, 30),
        ),
        DateTime(2026, 12, 27, 18, 30),
      );
      expect(releaseNotificationAt(release, 0), DateTime(2026, 12, 1, 9));
    });

    test('flags notifications after the release day', () {
      expect(
        isNotificationAfterRelease(release, DateTime(2026, 12, 1, 23)),
        isFalse,
      );
      expect(
        isNotificationAfterRelease(release, DateTime(2026, 12, 2, 9)),
        isTrue,
      );
    });
  });
}
