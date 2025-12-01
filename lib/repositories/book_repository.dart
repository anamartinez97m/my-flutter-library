import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/model/read_date.dart';
import 'package:sqflite/sqflite.dart';

class BookRepository {
  final Database db;

  BookRepository(this.db);

  Future<List<Book>> searchBooks(String input, int searchIndex) async {
    String whereClause;
    switch (searchIndex) {
      case 0:
        whereClause = 'lower(b.name) like ?'; // Title
        break;
      case 1:
        // Search by ISBN or ASIN
        whereClause = '(lower(b.isbn) like ? OR lower(b.asin) like ?)';
        break;
      case 2:
        whereClause = 'lower(a.name) like ?'; // Author
        break;
      case 3:
        whereClause = '(lower(b.saga) like ? OR lower(b.saga_universe) like ?)'; // Saga or Saga Universe
        break;
      default:
        whereClause = 'lower(b.name) like ?';
    }

    final searchParam = '%${input.toLowerCase()}%';
    final params = (searchIndex == 1 || searchIndex == 3) ? [searchParam, searchParam] : [searchParam];

    // First, search all books (including individual bundle books)
    final allResults = await db.rawQuery(
      '''
      select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga, b.saga_universe, b.isbn, b.asin, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
        b.pages, b.created_at, b.date_read_initial, b.date_read_final, 
        b.read_count, b.my_rating, b.my_review,
        b.is_bundle, b.bundle_count, b.bundle_numbers, b.bundle_start_dates, b.bundle_end_dates, b.bundle_pages, b.bundle_publication_years, b.bundle_titles, b.bundle_authors,
        b.tbr, b.is_tandem, b.original_book_id,
        b.notification_enabled, b.notification_datetime, b.bundle_parent_id,
        b.reading_progress, b.progress_type,
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
      where $whereClause
      group by b.book_id
      order by b.name
      ''',
      params,
    );

    // Process results: if a book is an individual bundle book, replace it with its parent
    final Set<int> addedBookIds = {};
    final List<Book> finalResults = [];
    
    for (var row in allResults) {
      final book = Book.fromMap(row);
      
      if (book.bundleParentId != null) {
        // This is an individual bundle book - add the parent instead
        if (!addedBookIds.contains(book.bundleParentId)) {
          final parent = await getBookById(book.bundleParentId!);
          if (parent != null) {
            finalResults.add(parent);
            addedBookIds.add(book.bundleParentId!);
          }
        }
      } else {
        // Regular book or bundle parent - add it
        if (book.bookId != null && !addedBookIds.contains(book.bookId)) {
          finalResults.add(book);
          addedBookIds.add(book.bookId!);
        }
      }
    }

    return finalResults;
  }

  Future<List<Book>> getAllBooks() async {
    final result = await db.rawQuery('''
      select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga, b.saga_universe, b.isbn, b.asin, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
        b.pages, b.created_at, b.date_read_initial, b.date_read_final, 
        b.read_count, b.my_rating, b.my_review,
        b.is_bundle, b.bundle_count, b.bundle_numbers, b.bundle_start_dates, b.bundle_end_dates, b.bundle_pages, b.bundle_publication_years, b.bundle_titles, b.bundle_authors,
        b.tbr, b.is_tandem, b.original_book_id,
        b.notification_enabled, b.notification_datetime, b.bundle_parent_id,
        b.reading_progress, b.progress_type,
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
      where b.name <> "" AND b.bundle_parent_id IS NULL
      group by b.book_id
      order by b.name;
      ''');

    return result.map((row) => Book.fromMap(row)).toList();
  }

  Future<String?> getLatestBookAdded() async {
    final result = await db.rawQuery('''
      SELECT name FROM book 
      WHERE name IS NOT NULL AND name != '' 
      ORDER BY created_at DESC 
      LIMIT 1
    ''');

    if (result.isNotEmpty) {
      return result.first['name'] as String?;
    }
    return null;
  }

  /// Get distinct saga names from all books
  Future<List<String>> getDistinctSagas() async {
    final result = await db.rawQuery('''
      SELECT DISTINCT saga FROM book 
      WHERE saga IS NOT NULL AND saga != '' 
      ORDER BY saga
    ''');

    return result.map((row) => row['saga'] as String).toList();
  }

  /// Get distinct saga universe names from all books
  Future<List<String>> getDistinctSagaUniverses() async {
    final result = await db.rawQuery('''
      SELECT DISTINCT saga_universe 
      FROM book 
      WHERE saga_universe IS NOT NULL AND saga_universe != ''
      ORDER BY saga_universe
    ''');

    return result.map((row) => row['saga_universe'] as String).toList();
  }

  /// Get count of books marked as TBR
  Future<int> getTBRCount() async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM book 
      WHERE tbr = 1
    ''');

    return result.first['count'] as int;
  }

  /// Get all books marked as TBR
  Future<List<Book>> getTBRBooks() async {
    final result = await db.rawQuery('''
      select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga, b.saga_universe, b.isbn, b.asin, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
        b.pages, b.created_at, b.date_read_initial, b.date_read_final, 
        b.read_count, b.my_rating, b.my_review,
        b.is_bundle, b.bundle_count, b.bundle_numbers, b.bundle_start_dates, b.bundle_end_dates, b.bundle_pages, b.bundle_publication_years, b.bundle_titles, b.bundle_authors,
        b.tbr, b.is_tandem, b.original_book_id,
        b.notification_enabled, b.notification_datetime, b.bundle_parent_id,
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
      where b.tbr = 1 AND b.bundle_parent_id IS NULL
      group by b.book_id
      order by b.name
    ''');

    return result.map((row) => Book.fromMap(row)).toList();
  }

  /// Get tandem books for a specific saga or saga_universe
  Future<List<Book>> getTandemBooks(String? saga, String? sagaUniverse) async {
    if (saga == null && sagaUniverse == null) return [];

    String whereClause;
    List<dynamic> params;

    if (saga != null && sagaUniverse != null) {
      whereClause = '(b.saga = ? OR b.saga_universe = ?) AND b.is_tandem = 1';
      params = [saga, sagaUniverse];
    } else if (saga != null) {
      whereClause = 'b.saga = ? AND b.is_tandem = 1';
      params = [saga];
    } else {
      whereClause = 'b.saga_universe = ? AND b.is_tandem = 1';
      params = [sagaUniverse!];
    }

    final result = await db.rawQuery('''
      select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga, b.saga_universe, b.isbn, b.asin, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
        b.pages, b.created_at, b.date_read_initial, b.date_read_final, 
        b.read_count, b.my_rating, b.my_review,
        b.is_bundle, b.bundle_count, b.bundle_numbers, b.bundle_start_dates, b.bundle_end_dates, b.bundle_pages, b.bundle_publication_years, b.bundle_titles, b.bundle_authors,
        b.tbr, b.is_tandem, b.original_book_id,
        b.notification_enabled, b.notification_datetime, b.bundle_parent_id,
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
      where $whereClause
      group by b.book_id
      order by b.name
    ''', params);

    return result.map((row) => Book.fromMap(row)).toList();
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

  /// Get unique saga values from books for autocomplete
  Future<List<String>> getUniqueSagas() async {
    final result = await db.rawQuery(
      '''
      SELECT DISTINCT saga 
      FROM book 
      WHERE saga IS NOT NULL AND saga != ''
      ORDER BY saga
      ''',
    );
    return result.map((row) => row['saga'] as String).toList();
  }

  /// Get all values from a lookup table
  Future<List<Map<String, dynamic>>> getLookupValues(String tableName) async {
    // Special handling for saga and saga_universe which are stored in book table
    if (tableName == 'saga_universe') {
      final result = await db.rawQuery('''
        SELECT DISTINCT saga_universe as name
        FROM book
        WHERE saga_universe IS NOT NULL AND saga_universe != ''
        ORDER BY saga_universe
      ''');
      // Add a fake ID for compatibility with the UI
      return result.asMap().entries.map((entry) {
        return {
          'saga_universe_id': entry.key + 1,
          'name': entry.value['name'],
        };
      }).toList();
    }
    
    if (tableName == 'saga') {
      final result = await db.rawQuery('''
        SELECT DISTINCT saga as name
        FROM book
        WHERE saga IS NOT NULL AND saga != ''
        ORDER BY saga
      ''');
      // Add a fake ID for compatibility with the UI
      return result.asMap().entries.map((entry) {
        return {
          'saga_id': entry.key + 1,
          'name': entry.value['name'],
        };
      }).toList();
    }
    
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
      distinct: true,
    );

    return result;
  }

  /// Add a new value to a lookup table
  Future<int> addLookupValue(String tableName, String value) async {
    // saga and saga_universe are text fields in book table, not lookup tables
    // Return a fake ID for compatibility
    if (tableName == 'saga' || tableName == 'saga_universe') {
      return 0; // No actual insert needed
    }
    
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
    // saga and saga_universe are text fields in book table, not lookup tables
    // We need to get the old value first and update all books with it
    if (tableName == 'saga' || tableName == 'saga_universe') {
      // Get the old value from the fake ID
      final allValues = await getLookupValues(tableName);
      if (id > 0 && id <= allValues.length) {
        final oldValue = allValues[id - 1]['name'] as String;
        return await db.rawUpdate(
          'UPDATE book SET $tableName = ? WHERE $tableName = ?',
          [newValue, oldValue],
        );
      }
      return 0;
    }
    
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
    
    // Delete read dates (CASCADE should handle this, but being explicit)
    await db.delete(
      'book_read_dates',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );

    // Delete the book
    await db.delete('book', where: 'book_id = ?', whereArgs: [bookId]);
  }

  /// Check if books already exist in the database with the same ISBN, ASIN, or name
  /// Returns list of book_ids if found, empty list otherwise
  /// Logic: Always check by name first, then by ISBN/ASIN, then by status+author+saga+nSaga for TBReleased
  Future<List<int>> findDuplicateBooks(Book book) async {
    final Set<int> duplicateIds = {};
    
    // Always check by name first if available
    if (book.name != null && book.name!.isNotEmpty) {
      final nameResults = await db.query(
        'book',
        columns: ['book_id'],
        where: 'LOWER(name) = ?',
        whereArgs: [book.name!.toLowerCase()],
      );
      if (nameResults.isNotEmpty) {
        duplicateIds.addAll(nameResults.map((r) => r['book_id'] as int));
      }
    }
    
    // Also check by ISBN or ASIN if either exists and is not empty
    if ((book.isbn != null && book.isbn!.isNotEmpty) || 
        (book.asin != null && book.asin!.isNotEmpty)) {
      final isbnAsinResults = await db.rawQuery(
        '''
        SELECT book_id FROM book 
        WHERE (isbn IS NOT NULL AND isbn != '' AND isbn = ?) 
           OR (asin IS NOT NULL AND asin != '' AND asin = ?)
        ''',
        [book.isbn ?? '', book.asin ?? ''],
      );
      if (isbnAsinResults.isNotEmpty) {
        duplicateIds.addAll(isbnAsinResults.map((r) => r['book_id'] as int));
      }
    }
    
    // If we found duplicates by name or ISBN/ASIN, return them
    if (duplicateIds.isNotEmpty) {
      return duplicateIds.toList();
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
    if ((existing['asin'] == null || existing['asin'].toString().isEmpty) && 
        newBook.asin != null && newBook.asin!.isNotEmpty) {
      updates['asin'] = newBook.asin;
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
    if ((existing['date_read_initial'] == null || existing['date_read_initial'].toString().isEmpty) && 
        newBook.dateReadInitial != null && newBook.dateReadInitial!.isNotEmpty) {
      updates['date_read_initial'] = newBook.dateReadInitial;
    }
    if ((existing['date_read_final'] == null || existing['date_read_final'].toString().isEmpty) && 
        newBook.dateReadFinal != null && newBook.dateReadFinal!.isNotEmpty) {
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
    final bookData = {
      'name': book.name ?? 'unknown',
      'isbn': book.isbn,
      'asin': book.asin,
      'saga': book.saga,
      'n_saga': book.nSaga,
      'saga_universe': book.sagaUniverse,
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
      'is_bundle': book.isBundle == true ? 1 : 0,
      'bundle_count': book.bundleCount,
      'bundle_numbers': book.bundleNumbers,
      'bundle_start_dates': book.bundleStartDates,
      'bundle_end_dates': book.bundleEndDates,
      'bundle_pages': book.bundlePages,
      'bundle_publication_years': book.bundlePublicationYears,
      'bundle_titles': book.bundleTitles,
      'bundle_authors': book.bundleAuthors,
      'tbr': book.tbr == true ? 1 : 0,
      'is_tandem': book.isTandem == true ? 1 : 0,
      'original_book_id': book.originalBookId,
      'notification_enabled': book.notificationEnabled == true ? 1 : 0,
      'notification_datetime': book.notificationDatetime,
      'bundle_parent_id': book.bundleParentId,
    };
    
    // If book has an ID, preserve it (for updates)
    if (book.bookId != null) {
      bookData['book_id'] = book.bookId;
    }
    
    final bookId = await db.insert('book', bookData, conflictAlgorithm: ConflictAlgorithm.replace);

    // Link authors (many-to-many relationship)
    await _linkAuthors(bookId, book.author);

    // Link genres (many-to-many relationship)
    await _linkGenres(bookId, book.genre);

    return bookId;
  }

  // ==================== Read Dates Methods ====================

  /// Get all read dates for a specific book
  /// If bundleBookIndex is provided, only returns dates for that bundle book
  Future<List<ReadDate>> getReadDatesForBook(int bookId, {int? bundleBookIndex}) async {
    String whereClause = 'book_id = ?';
    List<dynamic> whereArgs = [bookId];
    
    if (bundleBookIndex != null) {
      whereClause += ' AND bundle_book_index = ?';
      whereArgs.add(bundleBookIndex);
    }
    // Note: We don't filter by bundle_book_index IS NULL anymore
    // This allows individual bundle books to load their own reading sessions
    
    final result = await db.query(
      'book_read_dates',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date_started DESC',
    );
    
    // Debug logging
    if (result.isEmpty) {
      // Check if there are ANY sessions for this book with different conditions
      final allForBook = await db.query('book_read_dates', where: 'book_id = ?', whereArgs: [bookId]);
      debugPrint('BookRepository: No read dates found for book $bookId with bundleBookIndex=$bundleBookIndex. Total for this book_id: ${allForBook.length}');
      if (allForBook.isNotEmpty) {
        debugPrint('  Sample: ${allForBook.first}');
      }
    }
    
    return result.map((row) => ReadDate.fromMap(row)).toList();
  }
  
  /// Get all read dates for all books in a bundle
  /// Returns a map of bundleBookIndex -> List<ReadDate>
  Future<Map<int, List<ReadDate>>> getAllBundleReadDates(int bookId) async {
    final result = await db.query(
      'book_read_dates',
      where: 'book_id = ? AND bundle_book_index IS NOT NULL',
      whereArgs: [bookId],
      orderBy: 'bundle_book_index, date_started DESC',
    );
    
    final Map<int, List<ReadDate>> bundleDates = {};
    for (var row in result) {
      final readDate = ReadDate.fromMap(row);
      final index = readDate.bundleBookIndex!;
      if (!bundleDates.containsKey(index)) {
        bundleDates[index] = [];
      }
      bundleDates[index]!.add(readDate);
    }
    
    return bundleDates;
  }

  /// Add a new read date entry for a book
  Future<int> addReadDate(ReadDate readDate) async {
    return await db.insert('book_read_dates', readDate.toMap());
  }

  /// Update an existing read date entry
  Future<int> updateReadDate(ReadDate readDate) async {
    return await db.update(
      'book_read_dates',
      readDate.toMap(),
      where: 'read_date_id = ?',
      whereArgs: [readDate.readDateId],
    );
  }

  /// Delete a read date entry
  Future<int> deleteReadDate(int readDateId) async {
    return await db.delete(
      'book_read_dates',
      where: 'read_date_id = ?',
      whereArgs: [readDateId],
    );
  }

  /// Delete all read dates for a specific book
  Future<int> deleteAllReadDatesForBook(int bookId) async {
    return await db.delete(
      'book_read_dates',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }

  /// Get the count of read sessions for a book
  Future<int> getReadCountForBook(int bookId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM book_read_dates WHERE book_id = ? AND date_finished IS NOT NULL AND date_finished != ""',
      [bookId],
    );
    return result.first['count'] as int;
  }

  /// Helper method to parse date strings that can be either full dates (YYYY-MM-DD) or year-only (YYYY)
  DateTime? _parseFlexibleDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    try {
      // Try parsing as full date first
      return DateTime.parse(dateStr);
    } catch (e) {
      // If it fails, check if it's a year-only format (4 digits)
      if (dateStr.length == 4 && int.tryParse(dateStr) != null) {
        // Return January 1st of that year
        return DateTime(int.parse(dateStr), 1, 1);
      }
      return null;
    }
  }

  /// Get all years that have books read in them (from book_read_dates table)
  Future<List<int>> getYearsWithReadBooks() async {
    final result = await db.rawQuery('''
      SELECT DISTINCT CAST(substr(date_finished, 1, 4) AS INTEGER) as year
      FROM book_read_dates
      WHERE date_finished IS NOT NULL AND date_finished != ""
      ORDER BY year DESC
    ''');
    return result.map((row) => row['year'] as int).toList();
  }

  /// Get books and pages count per year from book_read_dates table
  /// Groups by original book (repeated books count as their original)
  /// For books spanning multiple years, counts them for the year with more days
  /// Handles bundles by counting each book in the bundle separately
  /// Only counts repeated books if they were read in different years
  Future<Map<String, Map<int, int>>> getBooksAndPagesPerYear() async {
    // Get all read dates with book info, including bundle information
    // Count each bundle book separately (by bundle_book_index)
    final result = await db.rawQuery('''
      SELECT 
        rd.read_date_id,
        rd.date_started,
        rd.date_finished,
        rd.bundle_book_index,
        COALESCE(orig.book_id, b.book_id) as book_id,
        COALESCE(orig.pages, b.pages, 0) as pages,
        COALESCE(orig.is_bundle, b.is_bundle, 0) as is_bundle,
        COALESCE(orig.bundle_pages, b.bundle_pages) as bundle_pages
      FROM book_read_dates rd
      INNER JOIN book b ON rd.book_id = b.book_id
      LEFT JOIN status s ON b.status_id = s.status_id
      LEFT JOIN book orig ON b.original_book_id = orig.book_id AND LOWER(s.value) = 'repeated'
      WHERE rd.date_finished IS NOT NULL 
        AND rd.date_finished != ""
        -- Exclude whole bundle books (only include individual bundle books or non-bundle books)
        AND NOT (COALESCE(orig.is_bundle, b.is_bundle, 0) = 1 AND rd.bundle_book_index IS NULL)
    ''');
    
    final Map<int, int> booksPerYear = {};
    final Map<int, int> pagesPerYear = {};
    
    // Track which books have been counted in which years to avoid duplicates
    // Key: "bookId_bundleIndex" (or just "bookId" for non-bundle books)
    final Map<String, Set<int>> countedBooksPerYear = {};
    
    debugPrint('📊 getBooksAndPagesPerYear: Processing ${result.length} read dates');
    
    for (var row in result) {
      try {
        final dateFinishedStr = row['date_finished'] as String;
        final dateFinished = _parseFlexibleDate(dateFinishedStr);
        
        if (dateFinished == null) {
          debugPrint('  ⚠️  Could not parse date: $dateFinishedStr');
          continue;
        }
        
        final bookId = row['book_id'] as int;
        final pages = row['pages'] as int;
        final isBundle = (row['is_bundle'] as int) == 1;
        final bundleBookIndex = row['bundle_book_index'] as int?;
        final bundlePagesJson = row['bundle_pages'] as String?;
        
        // Skip whole bundle books (only count individual bundle books)
        if (isBundle && bundleBookIndex == null) {
          debugPrint('  ⏭️  Skipping whole bundle book: bookId=$bookId');
          continue;
        }
        
        // Use the year from date_finished to match the book list logic
        final targetYear = dateFinished.year;
        
        // Create unique key for this book/bundle book
        final bookKey = bundleBookIndex != null 
            ? '${bookId}_$bundleBookIndex' 
            : bookId.toString();
        
        // Check if this book has already been counted for this year
        if (!countedBooksPerYear.containsKey(bookKey)) {
          countedBooksPerYear[bookKey] = {};
        }
        
        // Only count if not already counted for this year
        if (!countedBooksPerYear[bookKey]!.contains(targetYear)) {
          countedBooksPerYear[bookKey]!.add(targetYear);
          booksPerYear[targetYear] = (booksPerYear[targetYear] ?? 0) + 1;
          debugPrint('  ✅ Counted: bookKey=$bookKey, year=$targetYear, isBundle=$isBundle, bundleIndex=$bundleBookIndex');
          
          // For pages: use individual bundle book pages if available
          int pagesToAdd = pages;
          if (isBundle && bundleBookIndex != null && bundlePagesJson != null) {
            try {
              final List<dynamic> bundlePagesList = jsonDecode(bundlePagesJson);
              if (bundleBookIndex < bundlePagesList.length && bundlePagesList[bundleBookIndex] != null) {
                pagesToAdd = bundlePagesList[bundleBookIndex] as int;
              }
            } catch (e) {
              // If parsing fails, use total pages
            }
          }
          
          pagesPerYear[targetYear] = (pagesPerYear[targetYear] ?? 0) + pagesToAdd;
        }
      } catch (e) {
        debugPrint('Error parsing dates for book: $e');
      }
    }
    
    debugPrint('📊 Final counts: $booksPerYear');
    
    return {
      'books': booksPerYear,
      'pages': pagesPerYear,
    };
  }

  /// Get books read in a specific year (including original books for repeated reads)
  Future<List<Map<String, dynamic>>> getBooksReadInYear(int year) async {
    final result = await db.rawQuery('''
      SELECT DISTINCT 
        COALESCE(orig.book_id, b.book_id) as book_id,
        COALESCE(orig_s.value, s.value) as statusValue,
        COALESCE(orig.name, b.name) as name,
        COALESCE(orig_e.name, e.name) as editorialValue,
        COALESCE(orig.saga, b.saga) as saga,
        COALESCE(orig.n_saga, b.n_saga) as n_saga,
        COALESCE(orig.saga_universe, b.saga_universe) as saga_universe,
        COALESCE(orig.isbn, b.isbn) as isbn,
        COALESCE(orig.asin, b.asin) as asin,
        COALESCE(orig_l.name, l.name) as languageValue,
        COALESCE(orig_p.name, p.name) as placeValue,
        COALESCE(orig_f.value, f.value) as formatValue,
        COALESCE(orig_fs.value, fs.value) as formatSagaValue,
        COALESCE(orig.loaned, b.loaned) as loaned,
        COALESCE(orig.original_publication_year, b.original_publication_year) as original_publication_year,
        COALESCE(orig.pages, b.pages) as pages,
        COALESCE(orig.created_at, b.created_at) as created_at,
        COALESCE(orig.date_read_initial, b.date_read_initial) as date_read_initial,
        COALESCE(orig.date_read_final, b.date_read_final) as date_read_final,
        COALESCE(orig.read_count, b.read_count) as read_count,
        COALESCE(orig.my_rating, b.my_rating) as my_rating,
        COALESCE(orig.my_review, b.my_review) as my_review,
        COALESCE(orig.is_bundle, b.is_bundle) as is_bundle,
        COALESCE(orig.bundle_count, b.bundle_count) as bundle_count,
        COALESCE(orig.bundle_numbers, b.bundle_numbers) as bundle_numbers,
        COALESCE(orig.bundle_start_dates, b.bundle_start_dates) as bundle_start_dates,
        COALESCE(orig.bundle_end_dates, b.bundle_end_dates) as bundle_end_dates,
        COALESCE(orig.bundle_pages, b.bundle_pages) as bundle_pages,
        COALESCE(orig.bundle_publication_years, b.bundle_publication_years) as bundle_publication_years,
        COALESCE(orig.bundle_titles, b.bundle_titles) as bundle_titles,
        COALESCE(orig.bundle_authors, b.bundle_authors) as bundle_authors,
        COALESCE(orig.tbr, b.tbr) as tbr,
        COALESCE(orig.is_tandem, b.is_tandem) as is_tandem,
        COALESCE(orig.original_book_id, b.original_book_id) as original_book_id,
        COALESCE(orig_authors.author, authors.author) as author,
        COALESCE(orig_genres.genre, genres.genre) as genre,
        MAX(rd.date_finished) as latest_read_date,
        rd.bundle_book_index
      FROM book b
      INNER JOIN book_read_dates rd ON b.book_id = rd.book_id
      LEFT JOIN status s ON b.status_id = s.status_id
      
      -- If this is a repeated book, join to the original book
      LEFT JOIN book orig ON b.original_book_id = orig.book_id AND LOWER(s.value) = 'repeated'
      LEFT JOIN status orig_s ON orig.status_id = orig_s.status_id
      LEFT JOIN editorial orig_e ON orig.editorial_id = orig_e.editorial_id
      LEFT JOIN language orig_l ON orig.language_id = orig_l.language_id
      LEFT JOIN place orig_p ON orig.place_id = orig_p.place_id
      LEFT JOIN format orig_f ON orig.format_id = orig_f.format_id
      LEFT JOIN format_saga orig_fs ON orig.format_saga_id = orig_fs.format_id
      
      -- Get authors for original book
      LEFT JOIN (
        SELECT bba.book_id, GROUP_CONCAT(DISTINCT a.name) as author
        FROM books_by_author bba
        LEFT JOIN author a ON bba.author_id = a.author_id
        GROUP BY bba.book_id
      ) orig_authors ON orig.book_id = orig_authors.book_id
      
      -- Get genres for original book
      LEFT JOIN (
        SELECT bbg.book_id, GROUP_CONCAT(DISTINCT g.name) as genre
        FROM books_by_genre bbg
        LEFT JOIN genre g ON bbg.genre_id = g.genre_id
        GROUP BY bbg.book_id
      ) orig_genres ON orig.book_id = orig_genres.book_id
      
      -- Get authors for current book
      LEFT JOIN (
        SELECT bba.book_id, GROUP_CONCAT(DISTINCT a.name) as author
        FROM books_by_author bba
        LEFT JOIN author a ON bba.author_id = a.author_id
        GROUP BY bba.book_id
      ) authors ON b.book_id = authors.book_id
      
      -- Get genres for current book
      LEFT JOIN (
        SELECT bbg.book_id, GROUP_CONCAT(DISTINCT g.name) as genre
        FROM books_by_genre bbg
        LEFT JOIN genre g ON bbg.genre_id = g.genre_id
        GROUP BY bbg.book_id
      ) genres ON b.book_id = genres.book_id
      
      LEFT JOIN editorial e ON b.editorial_id = e.editorial_id
      LEFT JOIN language l ON b.language_id = l.language_id
      LEFT JOIN place p ON b.place_id = p.place_id
      LEFT JOIN format f ON b.format_id = f.format_id
      LEFT JOIN format_saga fs ON b.format_saga_id = fs.format_id
      
      WHERE CAST(substr(rd.date_finished, 1, 4) AS INTEGER) = ?
        AND rd.date_finished IS NOT NULL 
        AND rd.date_finished != ""
        -- Exclude whole bundle books (only include individual bundle books or non-bundle books)
        AND NOT (COALESCE(orig.is_bundle, b.is_bundle, 0) = 1 AND rd.bundle_book_index IS NULL)
      GROUP BY COALESCE(orig.book_id, b.book_id), rd.bundle_book_index
      ORDER BY latest_read_date DESC
    ''', [year]);
    
    return result;
  }

  /// Delete read dates for a specific bundle book
  Future<void> deleteReadDatesForBundleBook(int bookId, int bundleIndex) async {
    await db.delete(
      'book_read_dates',
      where: 'book_id = ? AND bundle_book_index = ?',
      whereArgs: [bookId, bundleIndex],
    );
  }

  // ==================== Bundle Books Methods ====================

  /// Get all individual books that belong to a bundle
  Future<List<Book>> getBundleBooks(int parentBookId) async {
    final result = await db.rawQuery('''
      select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga, b.saga_universe, b.isbn, b.asin, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
        b.pages, b.created_at, b.date_read_initial, b.date_read_final, 
        b.read_count, b.my_rating, b.my_review,
        b.is_bundle, b.bundle_count, b.bundle_numbers, b.bundle_start_dates, b.bundle_end_dates, b.bundle_pages, b.bundle_publication_years, b.bundle_titles, b.bundle_authors,
        b.tbr, b.is_tandem, b.original_book_id,
        b.notification_enabled, b.notification_datetime, b.bundle_parent_id,
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
      where b.bundle_parent_id = ?
      group by b.book_id
      order by b.n_saga, b.name
    ''', [parentBookId]);

    return result.map((row) => Book.fromMap(row)).toList();
  }

  /// Delete all individual books that belong to a bundle
  Future<void> deleteBundleBooks(int parentBookId) async {
    // Get all bundle books first
    final bundleBooks = await getBundleBooks(parentBookId);
    
    // Delete each bundle book (this will also delete their relationships)
    for (var book in bundleBooks) {
      if (book.bookId != null) {
        await deleteBook(book.bookId!);
      }
    }
  }

  /// Get book by ID
  Future<Book?> getBookById(int bookId) async {
    final result = await db.rawQuery('''
      select b.book_id, s.value as statusValue, b.name, e.name as editorialValue, 
        b.saga, b.n_saga, b.saga_universe, b.isbn, b.asin, l.name as languageValue, 
        p.name as placeValue, f.value as formatValue,
        fs.value as formatSagaValue, b.loaned, b.original_publication_year, 
        b.pages, b.created_at, b.date_read_initial, b.date_read_final, 
        b.read_count, b.my_rating, b.my_review,
        b.is_bundle, b.bundle_count, b.bundle_numbers, b.bundle_start_dates, b.bundle_end_dates, b.bundle_pages, b.bundle_publication_years, b.bundle_titles, b.bundle_authors,
        b.tbr, b.is_tandem, b.original_book_id,
        b.notification_enabled, b.notification_datetime, b.bundle_parent_id,
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
      where b.book_id = ?
      group by b.book_id
    ''', [bookId]);

    if (result.isEmpty) return null;
    return Book.fromMap(result.first);
  }
}
