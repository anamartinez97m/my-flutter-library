import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/utils/book_fields_csv.dart';

Book _book({
  int? bookId,
  String? name,
  String? author,
  String? genre,
  double? price,
  String? acquiredDate,
}) => Book(
  bookId: bookId,
  name: name,
  author: author,
  genre: genre,
  price: price,
  acquiredDate: acquiredDate,
  saga: null,
  nSaga: null,
  formatSagaValue: null,
  isbn: null,
  asin: null,
  pages: null,
  originalPublicationYear: null,
  loaned: null,
  statusValue: null,
  editorialValue: null,
  languageValue: null,
  placeValue: null,
  formatValue: null,
  createdAt: null,
);

void main() {
  group('BookFieldsCsv', () {
    test('export round-trips through parse', () {
      final csv = BookFieldsCsv.build([
        _book(
          bookId: 7,
          name: 'Cien años, de soledad',
          author: 'García Márquez',
          genre: 'Realismo mágico,Clásico',
          price: 12.5,
          acquiredDate: '2023',
        ),
        _book(bookId: 8, name: 'Free', price: 0),
        _book(bookId: 9, name: 'Nothing'),
      ]);
      expect(csv.startsWith('\uFEFF'), isTrue);

      final result = BookFieldsCsv.parse(csv);
      expect(result.errors, isEmpty);
      expect(result.rows, hasLength(3));
      expect(result.rows[0].bookId, 7);
      expect(result.rows[0].genres, ['Realismo mágico', 'Clásico']);
      expect(result.rows[0].price, 12.5);
      expect(result.rows[0].acquiredDate, '2023');
      expect(result.rows[1].price, 0.0);
      expect(result.rows[2].price, isNull);
      expect(result.rows[2].genres, isNull);
      expect(result.rows[2].acquiredDate, isNull);
    });

    test('reads Spanish Excel files (semicolons, comma decimals, CRLF)', () {
      const input =
          'Book ID;Title;Author;Genre;Price;Acquired Date\r\n'
          '1;A;X;Fantasía;12,99;2024-05-01\r\n'
          '2;B;Y;;€ 1.234,50;\r\n';
      final result = BookFieldsCsv.parse(input);
      expect(result.errors, isEmpty);
      expect(result.rows[0].price, 12.99);
      expect(result.rows[0].genres, ['Fantasía']);
      expect(result.rows[1].price, 1234.5);
      expect(result.rows[1].genres, isNull);
    });

    test('reports bad rows and a missing ID column', () {
      const input =
          'Book ID,Title,Author,Genre,Price,Acquired Date\n'
          'abc,A,,,,\n'
          '3,B,,,cheap,\n'
          '4,C,,,5,\n'
          '4,D,,,6,\n';
      final result = BookFieldsCsv.parse(input);
      expect(result.rows.map((r) => r.bookId), [4]);
      expect(result.errors, hasLength(3));

      expect(BookFieldsCsv.parse('Title,Price\nA,1\n').errors, hasLength(1));
    });

    test('parsePrice', () {
      expect(BookFieldsCsv.parsePrice('9.99'), 9.99);
      expect(BookFieldsCsv.parsePrice('9,99 €'), 9.99);
      expect(BookFieldsCsv.parsePrice('1,234.56'), 1234.56);
      expect(BookFieldsCsv.parsePrice('0'), 0.0);
      expect(BookFieldsCsv.parsePrice('free'), isNull);
    });
  });
}
