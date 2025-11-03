import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/model/book.dart';
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
        column = 'a.name'; // Author
        break;
      case 3:
        column = 'b.saga'; // Saga
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
        b.pages, b.created_at, b.date_read_initial, b.date_read_final, 
        b.read_count, b.my_rating, b.my_review,
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
        b.pages, b.created_at, b.date_read_initial, b.date_read_final, 
        b.read_count, b.my_rating, b.my_review,
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
    const withoutAccents =
        'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';

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
      final idColumn =
          tableName == 'format_saga' ? 'format_id' : '${tableName}_id';
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
    final idColumn =
        tableName == 'format_saga' ? 'format_id' : '${tableName}_id';
    final valueColumn =
        tableName == 'status' ||
                tableName == 'format' ||
                tableName == 'format_saga'
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
    final valueColumn =
        tableName == 'status' ||
                tableName == 'format' ||
                tableName == 'format_saga'
            ? 'value'
            : 'name';

    return await db.insert(tableName, {valueColumn: value});
  }

  /// Update a value in a lookup table
  Future<int> updateLookupValue(
    String tableName,
    int id,
    String newValue,
  ) async {
    // format_saga table uses 'format_id' not 'format_saga_id'
    final idColumn =
        tableName == 'format_saga' ? 'format_id' : '${tableName}_id';
    final valueColumn =
        tableName == 'status' ||
                tableName == 'format' ||
                tableName == 'format_saga'
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
    final idColumn =
        tableName == 'format_saga' ? 'format_id' : '${tableName}_id';

    return await db.delete(tableName, where: '$idColumn = ?', whereArgs: [id]);
  }

  /// Delete a book and its relationships
  Future<void> deleteBook(int bookId) async {
    // Delete from junction tables first
    await db.delete(
      'books_by_author',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    await db.delete(
      'books_by_genre',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );

    // Delete the book
    await db.delete('book', where: 'book_id = ?', whereArgs: [bookId]);
  }

  /// Check if books already exist in the database with the same ISBN
  /// Returns list of book_ids if found, empty list otherwise
  /// Logic: If ISBN exists, check by ISBN only. If ISBN empty, check by name. If name also empty, check by status+author+saga+nSaga
  Future<List<int>> findDuplicateBooks(Book book) async {
    // Check by ISBN only if ISBN exists and is not empty
    if (book.isbn != null && book.isbn!.isNotEmpty) {
      final results = await db.query(
        'book',
        columns: ['book_id', 'name'],
        where: 'isbn = ?',
        whereArgs: [book.isbn],
      );
      if (results.isNotEmpty) {
        return results.map((r) => r['book_id'] as int).toList();
      }
      return [];
    }

    // Only check by name if ISBN is empty
    if (book.name != null && book.name!.isNotEmpty) {
      final result = await db.query(
        'book',
        columns: ['book_id', 'isbn'],
        where: 'LOWER(name) = ?',
        whereArgs: [book.name!.toLowerCase()],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return [result.first['book_id'] as int];
      }
      // If name exists but no match, continue to TBReleased check
    }

    // If no name match and status is 'TBReleased', check by status+author+saga+nSaga
    if (book.statusValue != null && 
        book.statusValue!.toLowerCase() == 'tbreleased' &&
        book.author != null && 
        book.author!.isNotEmpty) {
      // Get status_id
      final statusId = await _getOrInsertLookupId(
        'status',
        'value',
        book.statusValue,
      );
      
      // For TBReleased books, we need to check author, saga, and nSaga combination
      final result = await db.rawQuery(
        '''
        SELECT DISTINCT b.book_id, b.name, b.saga, b.n_saga, s.value as status
        FROM book b
        LEFT JOIN books_by_author bba ON b.book_id = bba.book_id
        LEFT JOIN author a ON bba.author_id = a.author_id
        LEFT JOIN status s ON b.status_id = s.status_id
        WHERE b.status_id = ?
          AND LOWER(a.name) = ?
          AND LOWER(COALESCE(b.saga, '')) = ?
          AND LOWER(COALESCE(b.n_saga, '')) = ?
        LIMIT 1
        ''',
        [
          statusId,
          book.author!.toLowerCase(),
          (book.saga ?? '').toLowerCase(),
          (book.nSaga ?? '').toLowerCase(),
        ],
      );
      
      if (result.isNotEmpty) {
        return [result.first['book_id'] as int];
      }
    }

    return [];
  }

  /// Update an existing book with new data, only updating non-empty fields
  Future<void> updateBookWithNewData(int existingBookId, Book newBook) async {
    // Get the existing book first
    final existingBooks = await db.query(
      'book',
      where: 'book_id = ?',
      whereArgs: [existingBookId],
    );
    
    if (existingBooks.isEmpty) return;
    
    final existing = existingBooks.first;
    
    // Prepare update map - only update if new value is not null/empty
    final Map<String, dynamic> updates = {};
    
    // Update simple fields only if they're empty in existing and not empty in new
    if ((existing['name'] == null || existing['name'].toString().isEmpty) && 
        newBook.name != null && newBook.name!.isNotEmpty) {
      updates['name'] = newBook.name;
    }
    if ((existing['isbn'] == null || existing['isbn'].toString().isEmpty) && 
        newBook.isbn != null && newBook.isbn!.isNotEmpty) {
      updates['isbn'] = newBook.isbn;
    }
    if ((existing['saga'] == null || existing['saga'].toString().isEmpty) && 
        newBook.saga != null && newBook.saga!.isNotEmpty) {
      updates['saga'] = newBook.saga;
    }
    if ((existing['n_saga'] == null || existing['n_saga'].toString().isEmpty) && 
        newBook.nSaga != null && newBook.nSaga!.isNotEmpty) {
      updates['n_saga'] = newBook.nSaga;
    }
    if (existing['pages'] == null && newBook.pages != null) {
      updates['pages'] = newBook.pages;
    }
    if (existing['original_publication_year'] == null && 
        newBook.originalPublicationYear != null) {
      updates['original_publication_year'] = newBook.originalPublicationYear;
    }
    if ((existing['loaned'] == null || existing['loaned'].toString().isEmpty) && 
        newBook.loaned != null && newBook.loaned!.isNotEmpty) {
      updates['loaned'] = newBook.loaned;
    }
    
    // Update lookup table references only if empty in existing
    if (existing['status_id'] == null && newBook.statusValue != null) {
      final statusId = await _getOrInsertLookupId('status', 'value', newBook.statusValue);
      if (statusId != null) updates['status_id'] = statusId;
    }
    if (existing['editorial_id'] == null && newBook.editorialValue != null) {
      final editorialId = await _getOrInsertLookupId('editorial', 'name', newBook.editorialValue);
      if (editorialId != null) updates['editorial_id'] = editorialId;
    }
    if (existing['language_id'] == null && newBook.languageValue != null) {
      final languageId = await _getOrInsertLookupId('language', 'name', newBook.languageValue);
      if (languageId != null) updates['language_id'] = languageId;
    }
    if (existing['place_id'] == null && newBook.placeValue != null) {
      final placeId = await _getOrInsertLookupId('place', 'name', newBook.placeValue);
      if (placeId != null) updates['place_id'] = placeId;
    }
    if (existing['format_id'] == null && newBook.formatValue != null) {
      final formatId = await _getOrInsertLookupId('format', 'value', newBook.formatValue);
      if (formatId != null) updates['format_id'] = formatId;
    }
    if (existing['format_saga_id'] == null && newBook.formatSagaValue != null) {
      final formatSagaId = await _getOrInsertLookupId('format_saga', 'value', newBook.formatSagaValue);
      if (formatSagaId != null) updates['format_saga_id'] = formatSagaId;
    }
    
    // Update reading information only if empty
    if (existing['date_read_initial'] == null && newBook.dateReadInitial != null) {
      updates['date_read_initial'] = newBook.dateReadInitial;
    }
    if (existing['date_read_final'] == null && newBook.dateReadFinal != null) {
      updates['date_read_final'] = newBook.dateReadFinal;
    }
    if ((existing['read_count'] == null || existing['read_count'] == 0) && 
        newBook.readCount != null && newBook.readCount! > 0) {
      updates['read_count'] = newBook.readCount;
    }
    if (existing['my_rating'] == null && newBook.myRating != null) {
      updates['my_rating'] = newBook.myRating;
    }
    if ((existing['my_review'] == null || existing['my_review'].toString().isEmpty) && 
        newBook.myReview != null && newBook.myReview!.isNotEmpty) {
      updates['my_review'] = newBook.myReview;
    }
    
    // Apply updates if any
    if (updates.isNotEmpty) {
      await db.update(
        'book',
        updates,
        where: 'book_id = ?',
        whereArgs: [existingBookId],
      );
    }
    
    // Update authors if existing book has no authors
    final existingAuthors = await db.query(
      'books_by_author',
      where: 'book_id = ?',
      whereArgs: [existingBookId],
    );
    if (existingAuthors.isEmpty && newBook.author != null && newBook.author!.isNotEmpty) {
      await _linkAuthors(existingBookId, newBook.author);
    }
    
    // Update genres if existing book has no genres
    final existingGenres = await db.query(
      'books_by_genre',
      where: 'book_id = ?',
      whereArgs: [existingBookId],
    );
    if (existingGenres.isEmpty && newBook.genre != null && newBook.genre!.isNotEmpty) {
      await _linkGenres(existingBookId, newBook.genre);
    }
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
      'date_read_initial': book.dateReadInitial,
      'date_read_final': book.dateReadFinal,
      'read_count': book.readCount ?? 0,
      'my_rating': book.myRating,
      'my_review': book.myReview,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Link authors (many-to-many relationship)
    await _linkAuthors(bookId, book.author);

    // Link genres (many-to-many relationship)
    await _linkGenres(bookId, book.genre);

    return bookId;
  }
}
