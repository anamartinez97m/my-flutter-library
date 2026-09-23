import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/utils/csv_import_helper.dart';

void main() {
  group('bundle CSV parsing', () {
    const headers = [
      'Read',
      'title',
      'author',
      'pages',
      'saga number',
      'original publication year',
      'parent',
    ];
    const row = [
      'read',
      'The Individual Book',
      'An Author',
      '321',
      '2.5',
      '2024',
      'The Bundle',
    ];

    test('extracts the parent title', () {
      expect(CsvImportHelper.getBundleParentTitle(row, headers), 'The Bundle');
    });

    test('creates an individual book linked to its bundle', () {
      final book = CsvImportHelper.parseBundleBookFromCsv(row, headers, 42);

      expect(book?.name, 'The Individual Book');
      expect(book?.author, 'An Author');
      expect(book?.pages, 321);
      expect(book?.nSaga, '2.5');
      expect(book?.originalPublicationYear, 2024);
      expect(book?.statusValue, 'read');
      expect(book?.bundleParentId, 42);
      expect(book?.isBundle, isFalse);
    });

    test('imports normal book metadata for a bundle child', () {
      const richHeaders = [
        'Parent',
        'Title',
        'Author',
        'Status',
        'ISBN',
        'ASIN',
        'Editorial',
        'Genre',
        'Saga',
        'N_Saga',
        'Saga Universe',
        'Format Saga',
        'Pages',
        'Original Publication Year',
        'Language',
        'Place',
        'Format',
        'Loaned',
        'Read Count',
        'My Rating',
        'My Review',
        'Notes',
        'Price',
        'TBR',
        'Is Tandem',
        'Release Date',
        'Reading Progress',
        'Progress Type',
        'Acquired Date',
      ];
      const richRow = [
        'The Bundle',
        'Rich Bundle Book',
        'An Author',
        'Started',
        '9781234567890',
        'B012345678',
        'An Editorial',
        'Fantasy',
        'A Saga',
        '3',
        'A Universe',
        'Trilogy',
        '450',
        '2025',
        'English',
        'Home',
        'Hardcover',
        'yes',
        '2',
        '4.5',
        'A review',
        'Some notes',
        '19.99',
        'yes',
        'yes',
        '2025-10-01',
        '120',
        'pages',
        '2025-01-15',
      ];

      final book = CsvImportHelper.parseBundleBookFromCsv(
        richRow,
        richHeaders,
        42,
      );

      expect(book?.bundleParentId, 42);
      expect(book?.isBundle, isFalse);
      expect(book?.name, 'Rich Bundle Book');
      expect(book?.isbn, '9781234567890');
      expect(book?.editorialValue, 'An Editorial');
      expect(book?.genre, 'Fantasy');
      expect(book?.saga, 'A Saga');
      expect(book?.nSaga, '3');
      expect(book?.sagaUniverse, 'A Universe');
      expect(book?.formatSagaValue, 'Trilogy');
      expect(book?.languageValue, 'English');
      expect(book?.formatValue, 'Hardcover');
      expect(book?.readCount, 2);
      expect(book?.myRating, 4.5);
      expect(book?.notes, 'Some notes');
      expect(book?.price, 19.99);
      expect(book?.tbr, isTrue);
      expect(book?.isTandem, isTrue);
      expect(book?.readingProgress, 120);
      expect(book?.acquiredDate, '2025-01-15');
    });

    test('rejects a row without a title', () {
      final rowWithoutTitle = [...row]..[1] = '';
      expect(
        CsvImportHelper.parseBundleBookFromCsv(rowWithoutTitle, headers, 42),
        isNull,
      );
    });
  });
}
