import 'package:mylibrary/model/book.dart';
import 'package:sqflite/sqflite.dart';

class BookRepository {
  final Database db;

  BookRepository(this.db);

  Future<List<Book>> searchBooks(String input, int searchIndex) async {
    String column;
    switch (searchIndex) {
      case 0:
        column = 'b.name'; // Title
        break;
      case 1:
        column = 'b.isbn'; // ISBN
        break;
      case 2:
        column = 'a.name'; // Auth@r
        break;
      default:
        column = 'b.name';
    }

    final result = await db.rawQuery(
      '''
      select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga, b.isbn, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
        b.pages, b.created_at
      from book b 
      left join books_by_author bba on b.book_id = bba.book_id 
      left join author a on bba.author_id = a.author_id 
      left join status s on b.status_id = s.status_id 
      left join editorial e on b.editorial_id = e.editorial_id
      left join language l on b.language_id = l.language_id 
      left join place p on b.place_id = p.place_id  
      left join format f on b.format_id = f.format_id
      left join format_saga fs on b.format_saga = fs.format_id
      where lower($column) like ?
      order by b.name
      ''',
      ['%${input.toLowerCase()}%'],
    );

    return result.map((row) => Book.fromMap(row)).toList();
  }

  // Future<List<Book>> searchBooks(String query) async {
  //   final maps = await db.query(
  //     'book',
  //     where: 'title LIKE ? OR author LIKE ? OR isbn LIKE ?',
  //     whereArgs: ['%$query%', '%$query%', '%$query%'],
  //   );
  //   return maps.map((m) => Book.fromMap(m)).toList();
  // }

  Future<List<Book>> getAllBooks() async {
    final result = await db.rawQuery('''
      select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga, b.isbn, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
        b.pages, b.created_at
      from book b 
      left join status s on b.status_id = s.status_id 
      left join editorial e on b.editorial_id = e.editorial_id
      left join language l on b.language_id = l.language_id 
      left join place p on b.place_id = p.place_id  
      left join format f on b.format_id = f.format_id
      left join format_saga fs on b.format_saga_id = fs.format_id
      where b.name <> "" 
      order by b.name;
      ''');

    return result.map((row) => Book.fromMap(row)).toList();
  }

  Future<String?> getLatestBookAdded() async {
    final result = await db.rawQuery('''
      select b.name
      from book b 
      order by b.created_at desc 
      limit 1;
      ''');

    if (result.isNotEmpty) {
      return result.first['name']?.toString();
    } else {
      return null;
    }
  }

  // Future<void> insertBook(Book book) async {
  //   await db.insert('book', book.toMap(),
  //       conflictAlgorithm: ConflictAlgorithm.replace);
  // }
}
