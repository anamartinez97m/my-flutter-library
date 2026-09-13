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

    test('rejects a row without a title', () {
      final rowWithoutTitle = [...row]..[1] = '';
      expect(
        CsvImportHelper.parseBundleBookFromCsv(rowWithoutTitle, headers, 42),
        isNull,
      );
    });
  });
}
