import 'package:csv/csv.dart';
import 'package:myrandomlibrary/model/book.dart';

/// One row of the price/genre/acquired-date CSV. A null field means
/// "leave the stored value unchanged".
class BookFieldsCsvRow {
  final int line;
  final int bookId;
  final List<String>? genres;
  final double? price;
  final String? acquiredDate;

  const BookFieldsCsvRow({
    required this.line,
    required this.bookId,
    this.genres,
    this.price,
    this.acquiredDate,
  });
}

class BookFieldsCsvParseResult {
  final List<BookFieldsCsvRow> rows;

  /// Human-readable problems, e.g. `Line 12: invalid price "abc"`.
  final List<String> errors;

  const BookFieldsCsvParseResult(this.rows, this.errors);
}

/// Admin-only CSV round-trip for book id, title, authors, genre, price and
/// acquired date. Import only updates genre, price and acquired date of books
/// matched by id; title and authors are there for reference.
class BookFieldsCsv {
  static const headers = <String>[
    'Book ID',
    'Title',
    'Author',
    'Genre',
    'Price',
    'Acquired Date',
  ];

  static const _bom = '\uFEFF';

  static String build(List<Book> books) {
    final rows = <List<dynamic>>[
      headers,
      for (final book in books)
        [
          book.bookId?.toString() ?? '',
          book.name ?? '',
          book.author ?? '',
          book.genre ?? '',
          book.price?.toString() ?? '',
          book.acquiredDate ?? '',
        ],
    ];
    // BOM so Excel opens accents correctly.
    return _bom + const ListToCsvConverter().convert(rows);
  }

  static BookFieldsCsvParseResult parse(String input) {
    var text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.startsWith(_bom)) text = text.substring(1);

    final firstLine = text.split('\n').first;
    // Excel in a Spanish locale saves CSV with ';'.
    final delimiter =
        ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length
            ? ';'
            : ',';

    final table = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(text);

    if (table.isEmpty) {
      return const BookFieldsCsvParseResult([], ['The file is empty']);
    }

    final headerIndex = <String, int>{};
    for (var i = 0; i < table.first.length; i++) {
      headerIndex[_normalizeHeader(table.first[i].toString())] = i;
    }
    final idCol = headerIndex['bookid'];
    if (idCol == null) {
      return const BookFieldsCsvParseResult([], [
        'Missing "Book ID" column. Use the file from "Export prices & genres".',
      ]);
    }
    final genreCol = headerIndex['genre'];
    final priceCol = headerIndex['price'];
    final acquiredCol = headerIndex['acquireddate'];

    String? cell(List<dynamic> row, int? col) {
      if (col == null || col >= row.length) return null;
      final value = row[col].toString().trim();
      return value.isEmpty ? null : value;
    }

    final rows = <BookFieldsCsvRow>[];
    final errors = <String>[];
    final seenIds = <int>{};

    for (var r = 1; r < table.length; r++) {
      final row = table[r];
      final line = r + 1;
      if (row.every((c) => c.toString().trim().isEmpty)) continue;

      final idStr = cell(row, idCol);
      final bookId = idStr == null ? null : int.tryParse(idStr);
      if (bookId == null) {
        errors.add('Line $line: invalid book ID "${idStr ?? ''}"');
        continue;
      }
      if (!seenIds.add(bookId)) {
        errors.add('Line $line: book ID $bookId appears more than once');
        continue;
      }

      final priceStr = cell(row, priceCol);
      double? price;
      if (priceStr != null) {
        price = parsePrice(priceStr);
        if (price == null) {
          errors.add('Line $line: invalid price "$priceStr"');
          continue;
        }
      }

      final genreStr = cell(row, genreCol);
      final genres =
          genreStr
              ?.split(',')
              .map((g) => g.trim())
              .where((g) => g.isNotEmpty)
              .toList();

      rows.add(
        BookFieldsCsvRow(
          line: line,
          bookId: bookId,
          genres: (genres == null || genres.isEmpty) ? null : genres,
          price: price,
          acquiredDate: cell(row, acquiredCol),
        ),
      );
    }

    return BookFieldsCsvParseResult(rows, errors);
  }

  /// Accepts `12.99`, `12,99`, `€12,99`, `1.234,56`, `1,234.56`.
  static double? parsePrice(String input) {
    var s = input.replaceAll(RegExp(r'[^0-9.,\-]'), '');
    if (s.isEmpty) return null;
    final lastDot = s.lastIndexOf('.');
    final lastComma = s.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      final decimal = lastDot > lastComma ? '.' : ',';
      final thousands = decimal == '.' ? ',' : '.';
      s = s.replaceAll(thousands, '').replaceAll(decimal, '.');
    } else {
      s = s.replaceAll(',', '.');
    }
    final value = double.tryParse(s);
    if (value == null || value < 0) return null;
    return value;
  }

  static String _normalizeHeader(String header) => header
      .replaceAll('\uFEFF', '')
      .toLowerCase()
      .replaceAll(RegExp(r'[\s_\-]'), '');
}

/// What an import would change on one book. Null fields stay as they are.
class BookFieldsChange {
  final int bookId;
  final String name;
  final List<String>? genres;
  final double? price;
  final String? acquiredDate;

  const BookFieldsChange({
    required this.bookId,
    required this.name,
    this.genres,
    this.price,
    this.acquiredDate,
  });
}

class BookFieldsUpdatePlan {
  final List<BookFieldsChange> changes;
  final List<int> unknownIds;
  final int unchanged;

  /// Genre names in the file that don't exist yet and would be created.
  final List<String> newGenres;

  const BookFieldsUpdatePlan({
    required this.changes,
    required this.unknownIds,
    required this.unchanged,
    required this.newGenres,
  });
}
