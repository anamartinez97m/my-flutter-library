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
        b.pages, b.created_at,
        GROUP_CONCAT(DISTINCT a.name) as author,
        GROUP_CONCAT(DISTINCT g.name) as genre
      from book b 
      left join books_by_author bba on b.book_id = bba.book_id 
      left join author a on bba.author_id = a.author_id 
      left join books_by_genre bbg on b.book_id = bbg.book_id 
      left join genre g on bbg.genre_id = g.genre_id
      left join status s on b.status_id = s.status_id 
      left join editorial e on b.editorial_id = e.editorial_id
      left join language l on b.language_id = l.language_id 
      left join place p on b.place_id = p.place_id  
      left join format f on b.format_id = f.format_id
      left join format_saga fs on b.format_saga = fs.format_id
      where lower($column) like ?
      group by b.book_id
      order by b.name
      ''',
      ['%${input.toLowerCase()}%'],
    );

    return result.map((row) => Book.fromMap(row)).toList();
  }

  Future<List<Book>> getAllBooks() async {
    final result = await db.rawQuery('''
      select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga, b.isbn, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
        b.pages, b.created_at,
        GROUP_CONCAT(DISTINCT a.name) as author,
        GROUP_CONCAT(DISTINCT g.name) as genre
      from book b 
      left join books_by_author bba on b.book_id = bba.book_id 
      left join author a on bba.author_id = a.author_id
      left join books_by_genre bbg on b.book_id = bbg.book_id 
      left join genre g on bbg.genre_id = g.genre_id
      left join status s on b.status_id = s.status_id 
      left join editorial e on b.editorial_id = e.editorial_id
      left join language l on b.language_id = l.language_id 
      left join place p on b.place_id = p.place_id  
      left join format f on b.format_id = f.format_id
      left join format_saga fs on b.format_saga_id = fs.format_id
      where b.name <> "" 
      group by b.book_id
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

  /// Removes accents from a string for case-insensitive comparison
  String _removeAccents(String text) {
    const accents = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    const withoutAccents = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    
    String result = text;
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Helper method to get or insert a value in a lookup table
  /// Uses case-insensitive and accent-insensitive comparison
  Future<int?> _getOrInsertLookupId(
    String tableName,
    String valueColumn,
    String? value,
  ) async {
    if (value == null || value.isEmpty) {
      return null;
    }

    // Normalize the value for comparison (lowercase + no accents)
    final normalizedValue = _removeAccents(value.toLowerCase());

    // Try to find existing value using case-insensitive and accent-insensitive comparison
    final result = await db.rawQuery(
      '''
      SELECT * FROM $tableName 
      WHERE LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        $valueColumn,
        'á','a'),'é','e'),'í','i'),'ó','o'),'ú','u'),'ñ','n'),'ü','u'),
        'Á','A'),'É','E'),'Í','I'),'Ó','O'),'Ú','U'),'Ñ','N'),'Ü','U')) = ?
      LIMIT 1
      ''',
      [normalizedValue],
    );

    if (result.isNotEmpty) {
      // Return existing ID
      // format_saga table uses 'format_id' not 'format_saga_id'
      final idColumn = tableName == 'format_saga' ? 'format_id' : '${tableName}_id';
      return result.first[idColumn] as int?;
    }

    // Insert new value (with original capitalization and accents) and return ID
    final id = await db.insert(tableName, {valueColumn: value});
    return id;
  }

  /// Helper method to link book with authors (handles comma-separated authors)
  Future<void> _linkAuthors(int bookId, String? authorsStr) async {
    if (authorsStr == null || authorsStr.isEmpty) {
      return;
    }

    // Split by comma in case of multiple authors
    final authors = authorsStr
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty);

    for (final authorName in authors) {
      // Get or insert author
      final authorId = await _getOrInsertLookupId('author', 'name', authorName);

      if (authorId != null) {
        // Link book to author (avoid duplicates)
        await db.insert('books_by_author', {
          'author_id': authorId,
          'book_id': bookId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  /// Helper method to link book with genres (handles comma-separated genres)
  Future<void> _linkGenres(int bookId, String? genresStr) async {
    if (genresStr == null || genresStr.isEmpty) {
      return;
    }

    // Split by comma in case of multiple genres
    final genres = genresStr
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty);

    for (final genreName in genres) {
      // Get or insert genre
      final genreId = await _getOrInsertLookupId('genre', 'name', genreName);

      if (genreId != null) {
        // Link book to genre (avoid duplicates)
        await db.insert('books_by_genre', {
          'genre_id': genreId,
          'book_id': bookId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  /// Get all values from a lookup table
  Future<List<Map<String, dynamic>>> getLookupValues(String tableName) async {
    // format_saga table uses 'format_id' not 'format_saga_id'
    final idColumn = tableName == 'format_saga' ? 'format_id' : '${tableName}_id';
    final valueColumn = tableName == 'status' || tableName == 'format' || tableName == 'format_saga' 
        ? 'value' 
        : 'name';
    
    final result = await db.query(
      tableName,
      columns: [idColumn, valueColumn],
      orderBy: valueColumn,
    );
    
    return result;
  }

  /// Add a new value to a lookup table
  Future<int> addLookupValue(String tableName, String value) async {
    final valueColumn = tableName == 'status' || tableName == 'format' || tableName == 'format_saga' 
        ? 'value' 
        : 'name';
    
    return await db.insert(tableName, {valueColumn: value});
  }

  /// Update a value in a lookup table
  Future<int> updateLookupValue(String tableName, int id, String newValue) async {
    // format_saga table uses 'format_id' not 'format_saga_id'
    final idColumn = tableName == 'format_saga' ? 'format_id' : '${tableName}_id';
    final valueColumn = tableName == 'status' || tableName == 'format' || tableName == 'format_saga' 
        ? 'value' 
        : 'name';
    
    return await db.update(
      tableName,
      {valueColumn: newValue},
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  /// Delete a value from a lookup table
  Future<int> deleteLookupValue(String tableName, int id) async {
    // format_saga table uses 'format_id' not 'format_saga_id'
    final idColumn = tableName == 'format_saga' ? 'format_id' : '${tableName}_id';
    
    return await db.delete(
      tableName,
      where: '$idColumn = ?',
      whereArgs: [id],
    );
  }

  /// Delete a book and its relationships
  Future<void> deleteBook(int bookId) async {
    // Delete from junction tables first
    await db.delete('books_by_author', where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('books_by_genre', where: 'book_id = ?', whereArgs: [bookId]);
    
    // Delete the book
    await db.delete('book', where: 'book_id = ?', whereArgs: [bookId]);
  }

  Future<int> addBook(Book book) async {
    // Get or insert lookup table values
    final statusId = await _getOrInsertLookupId(
      'status',
      'value',
      book.statusValue,
    );
    final editorialId = await _getOrInsertLookupId(
      'editorial',
      'name',
      book.editorialValue,
    );
    final languageId = await _getOrInsertLookupId(
      'language',
      'name',
      book.languageValue,
    );
    final placeId = await _getOrInsertLookupId(
      'place',
      'name',
      book.placeValue,
    );
    final formatId = await _getOrInsertLookupId(
      'format',
      'value',
      book.formatValue,
    );
    final formatSagaId = await _getOrInsertLookupId(
      'format_saga',
      'value',
      book.formatSagaValue,
    );

    // Insert into book table with resolved IDs
    final bookId = await db.insert('book', {
      'name': book.name ?? 'unknown',
      'isbn': book.isbn,
      'saga': book.saga,
      'n_saga': book.nSaga,
      'pages': book.pages,
      'original_publication_year': book.originalPublicationYear,
      'loaned': book.loaned,
      'status_id': statusId,
      'editorial_id': editorialId,
      'language_id': languageId,
      'place_id': placeId,
      'format_id': formatId,
      'format_saga_id': formatSagaId,
      'created_at': book.createdAt ?? DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Link authors (many-to-many relationship)
    await _linkAuthors(bookId, book.author);

    // Link genres (many-to-many relationship)
    await _linkGenres(bookId, book.genre);

    return bookId;
  }
}
