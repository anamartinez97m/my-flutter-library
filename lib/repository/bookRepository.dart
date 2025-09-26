import 'package:mylibrary/model/book.dart';
import 'package:sqflite/sqflite.dart';

class BookRepository {
  final Database db;

  BookRepository(this.db);

  Future<List<Book>> searchBooks(String input) async {
    final result = await db.rawQuery(
      '''
      select b.book_id as bookId, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga as nSaga, b.isbn, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue
      from book b 
      left join books_by_author bba on b.book_id = bba.book_id 
      left join author a on bba.author_id = a.author_id 
      left join status s on b.status_id = s.status_id 
      left join editorial e on b.editorial_id = e.editorial_id
      left join language l on b.language_id = l.language_id 
      left join place p on b.place_id = p.place_id  
      left join format f on b.format_id = f.format_id
      where lower(a.name) like ? or (b.isbn) like ? or lower(b.name) like ?
      order by b.name
      ''',
      ['%${input.toLowerCase()}%', '%$input%', '%${input.toLowerCase()}%'],
    );

    return result.map((row) => Book.fromMap(row)).toList();
  }

  Future<List<Book>> getAllBooks() async {
    final result = await db.rawQuery('''
      select b.book_id as bookId, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga as nSaga, b.isbn, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue
      from book b 
      left join status s on b.status_id = s.status_id 
      left join editorial e on b.editorial_id = e.editorial_id
      left join language l on b.language_id = l.language_id 
      left join place p on b.place_id = p.place_id  
      left join format f on b.format_id = f.format_id
      where b.name <> "" 
      order by b.name;
      ''');
    return result.map((row) => Book.fromMap(row)).toList();
  }

  // Future<void> insertBook(Book book) async {
  //   await db.insert('book', book.toMap(),
  //       conflictAlgorithm: ConflictAlgorithm.replace);
  // }
}
