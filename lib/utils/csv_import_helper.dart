import 'package:flutter/foundation.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/db/database_helper.dart';

/// Result of CSV import operation
class CsvImportResult {
  final int importedCount;
  final int skippedCount;
  final int duplicateCount;
  final List<String> duplicateBooks;
  final List<String> errors;

  CsvImportResult({
    required this.importedCount,
    required this.skippedCount,
    required this.duplicateCount,
    required this.duplicateBooks,
    required this.errors,
  });
}

/// Helper class for CSV import operations
class CsvImportHelper {
  /// Normalize date to yyyy-mm-dd format
  /// Handles various input formats: yyyy/mm/dd, dd/mm/yyyy, mm/dd/yyyy, yyyy-mm-dd
  static String? normalizeDateFormat(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    final trimmed = dateStr.trim();

    // Already in yyyy-mm-dd format
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(trimmed)) {
      return trimmed.split('T')[0]; // Remove time component if present
    }

    try {
      // Try to parse various formats
      DateTime? date;

      // Format: yyyy/mm/dd or yyyy-mm-dd
      if (RegExp(r'^\d{4}[/-]\d{1,2}[/-]\d{1,2}').hasMatch(trimmed)) {
        final parts = trimmed.split(RegExp(r'[/-]'));
        date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      // Format: dd/mm/yyyy or dd-mm-yyyy
      else if (RegExp(r'^\d{1,2}[/-]\d{1,2}[/-]\d{4}').hasMatch(trimmed)) {
        final parts = trimmed.split(RegExp(r'[/-]'));
        date = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      if (date != null) {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      debugPrint('Error normalizing date "$dateStr": $e');
    }

    return trimmed; // Return as-is if we can't parse it
  }

  /// Map status values across languages
  /// Returns the database value that matches the input status semantically
  static Future<String?> mapStatusValue(
    String? inputStatus,
    DatabaseHelper dbHelper,
  ) async {
    if (inputStatus == null || inputStatus.isEmpty) return null;

    final normalized = inputStatus.toLowerCase().trim();

    // Get all existing status values from database
    final db = await dbHelper.database;
    final statusList = await db.query('status', columns: ['value']);
    final existingStatuses =
        statusList.map((s) => s['value'] as String).toList();

    // Define semantic mappings
    // "read" / "yes" / "si" / "sí" -> all mean "read"
    final readVariants = [
      'read',
      'yes',
      'si',
      'sí',
      'y',
      'finished',
      'completed',
    ];
    // "to-read" / "no" / "tbr" -> all mean "not read yet"
    final toReadVariants = ['to-read', 'no', 'n', 'tbr', 'unread', 'pending'];
    // "tbreleased" -> special status for unreleased books
    final tbReleasedVariants = ['tbreleased', 'unreleased', 'upcoming'];

    // Check which semantic group the input belongs to
    String? semanticGroup;
    if (readVariants.contains(normalized)) {
      semanticGroup = 'read';
    } else if (toReadVariants.contains(normalized)) {
      semanticGroup = 'to-read';
    } else if (tbReleasedVariants.contains(normalized)) {
      semanticGroup = 'tbreleased';
    }

    if (semanticGroup == null) {
      // Unknown status, return as-is
      return inputStatus;
    }

    // Find matching status in database
    for (final existing in existingStatuses) {
      final existingNormalized = existing.toLowerCase().trim();

      if (semanticGroup == 'read' &&
          readVariants.contains(existingNormalized)) {
        return existing;
      } else if (semanticGroup == 'to-read' &&
          toReadVariants.contains(existingNormalized)) {
        return existing;
      } else if (semanticGroup == 'tbreleased' &&
          tbReleasedVariants.contains(existingNormalized)) {
        return existing;
      }
    }

    // No match found, return the input as-is (will be created as new status)
    return inputStatus;
  }

  /// Detect CSV format based on headers
  static CsvFormat detectCsvFormat(List<dynamic> headers) {
    final headerStr = headers.map((h) => h.toString().toLowerCase()).toList();

    // Check for exported format (from settings export)
    // Has headers like: Title, Author, ISBN, ASIN, Status, etc.
    if (headerStr.contains('title') &&
        headerStr.contains('author') &&
        headerStr.contains('status') &&
        (headerStr.contains('isbn') || headerStr.contains('asin'))) {
      return CsvFormat.format1;
    }

    // Check for Format 1 (legacy custom format with 'read' instead of 'status')
    if (headerStr.contains('read') &&
        headerStr.contains('title') &&
        headerStr.contains('publisher') &&
        headerStr.contains('binding')) {
      return CsvFormat.format1;
    }

    // Check for Format 2 (Goodreads format)
    if (headerStr.contains('exclusive shelf') &&
        headerStr.contains('my rating') &&
        headerStr.contains('bookshelves') &&
        headerStr.contains('read count')) {
      return CsvFormat.format2;
    }

    return CsvFormat.unknown;
  }

  /// Parse a book from CSV row based on format
  static Book? parseBookFromCsv(
    List<dynamic> row,
    CsvFormat format,
    List<dynamic> headers, {
    String? filterTag,
  }) {
    try {
      if (format == CsvFormat.format1) {
        return _parseFormat1(row, headers);
      } else if (format == CsvFormat.format2) {
        return _parseFormat2(row, headers, filterTag: filterTag);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parse Format 1: read, title, author, publisher, genre, saga, n_saga,
  /// format_saga, isbn13, asin, number of pages, original publication year,
  /// language, place, binding, loaned
  static Book? _parseFormat1(List<dynamic> row, List<dynamic> headers) {
    final headerMap = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      headerMap[headers[i].toString().toLowerCase()] = i;
    }

    String? getValue(String key) {
      final index = headerMap[key];
      if (index == null || index >= row.length) return null;
      final value = row[index]?.toString().trim();
      return value?.isEmpty ?? true ? null : value;
    }

    // Handle both 'read' (legacy) and 'status' (exported) column names
    final statusValue = getValue('status') ?? getValue('read');
    var title = getValue('title');
    final author = getValue('author');
    // Handle both 'publisher' and 'editorial' column names
    final publisher = getValue('editorial') ?? getValue('publisher');
    final genre = getValue('genre');
    var saga = getValue('saga');
    var nSaga = getValue('n_saga') ?? getValue('n saga');
    final sagaUniverse = getValue('saga universe');
    final formatSaga = getValue('format saga') ?? getValue('format_saga');
    var isbn = getValue('isbn') ?? getValue('isbn13');
    var asin = getValue('asin');
    final pagesStr = getValue('pages') ?? getValue('number of pages');
    final pubYearStr = getValue('original publication year');
    final language = getValue('language');
    final place = getValue('place');
    // Handle both 'binding' (legacy) and 'format' (exported) column names
    final format = getValue('format') ?? getValue('binding');
    final loaned = getValue('loaned');
    final dateReadInitial = getValue('date read initial');
    final dateReadFinal = getValue('date read final');
    final readCountStr = getValue('read count');
    final myRatingStr = getValue('my rating');
    final myReview = getValue('my review');
    final notes = getValue('notes');
    final priceStr = getValue('price');

    // Remove trailing comma from saga if present
    if (saga != null && saga.endsWith(',')) {
      saga = saga.substring(0, saga.length - 1).trim();
    }

    // Extract saga and nSaga from title if present (Title #number)
    if (title != null) {
      final sagaMatch = RegExp(r'\((.+?)\s+#(\d+)\)$').firstMatch(title);
      if (sagaMatch != null) {
        saga = saga ?? sagaMatch.group(1);
        nSaga = nSaga ?? sagaMatch.group(2);
        title = title.replaceAll(sagaMatch.group(0)!, '').trim();
      }
    }

    // Clean ISBN if it has ="" format
    if (isbn != null && isbn.startsWith('="') && isbn.endsWith('"')) {
      isbn = isbn.substring(2, isbn.length - 1);
    }

    // Clean ASIN if it has ="" format
    if (asin != null && asin.startsWith('="') && asin.endsWith('"')) {
      asin = asin.substring(2, asin.length - 1);
    }

    // Allow empty title for TBReleased books with author and saga
    final isTBReleased = statusValue?.toLowerCase() == 'tbreleased';
    if ((title == null || title.isEmpty) && !isTBReleased) {
      return null;
    }

    return Book(
      bookId: null,
      name: title,
      isbn: isbn,
      asin: asin,
      author: author,
      saga: saga,
      nSaga: nSaga,
      sagaUniverse: sagaUniverse,
      formatSagaValue: formatSaga,
      pages: pagesStr != null ? int.tryParse(pagesStr) : null,
      originalPublicationYear:
          pubYearStr != null ? int.tryParse(pubYearStr) : null,
      loaned: loaned ?? 'no',
      statusValue: statusValue,
      editorialValue: publisher,
      languageValue: language,
      placeValue: place,
      formatValue: format,
      createdAt: DateTime.now().toIso8601String(),
      genre: genre,
      dateReadInitial: normalizeDateFormat(dateReadInitial),
      dateReadFinal: normalizeDateFormat(dateReadFinal),
      readCount: readCountStr != null ? int.tryParse(readCountStr) : 0,
      myRating: myRatingStr != null ? double.tryParse(myRatingStr) : null,
      myReview: myReview,
      notes: notes,
      price: priceStr != null ? double.tryParse(priceStr) : null,
    );
  }

  /// Parse Format 2: Title, Author, ISBN13, ASIN, My Rating, Publisher, Binding,
  /// Number of Pages, Original Publication Year, Date Read, Date Added,
  /// Bookshelves, Exclusive Shelf, My Review, Read Count
  /// If [filterTag] is provided, only books with that tag in bookshelves will be imported
  static Book? _parseFormat2(
    List<dynamic> row,
    List<dynamic> headers, {
    String? filterTag,
  }) {
    final headerMap = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      headerMap[headers[i].toString().toLowerCase()] = i;
    }

    String? getValue(String key) {
      final index = headerMap[key];
      if (index == null || index >= row.length) return null;
      final value = row[index]?.toString().trim();
      return value?.isEmpty ?? true ? null : value;
    }

    final exclusiveShelf = getValue('exclusive shelf');
    var title = getValue('title');
    final author = getValue('author');
    final publisher = getValue('publisher');
    var isbn = getValue('isbn13') ?? getValue('isbn');
    var asin = getValue('asin');
    final pagesStr = getValue('number of pages');
    final pubYearStr = getValue('original publication year');
    final format = getValue('binding');
    final dateRead = getValue('date read');
    final dateAdded = getValue('date added');
    final bookshelves = getValue('bookshelves');
    final myRatingStr = getValue('my rating');
    final myReview = getValue('my review');
    final readCountStr = getValue('read count');

    // Check if book should be imported based on bookshelves
    bool isOwned = false;
    bool isReadLoaned = false;
    if (headerMap.containsKey('bookshelves') && bookshelves != null) {
      final shelvesLower = bookshelves.toLowerCase();
      isOwned = shelvesLower.contains('owned');
      isReadLoaned = shelvesLower.contains('read-loaned');
    }

    // Filter by tag if provided
    if (filterTag != null && headerMap.containsKey('bookshelves')) {
      if (bookshelves == null ||
          !bookshelves.toLowerCase().contains(filterTag.toLowerCase())) {
        return null;
      }
    } else if (filterTag == null && headerMap.containsKey('bookshelves')) {
      // Default behavior: only import if bookshelves contains "owned" or "read-loaned"
      if (!isOwned && !isReadLoaned) {
        return null;
      }
    }

    // Map exclusive shelf to status
    String? statusValue;
    if (exclusiveShelf != null) {
      if (exclusiveShelf.toLowerCase() == 'read') {
        statusValue = 'yes';
      } else if (exclusiveShelf.toLowerCase() == 'to-read') {
        statusValue = 'no';
      }
    }

    // Extract saga and nSaga from title if present
    String? saga;
    String? nSaga;
    if (title != null) {
      final sagaMatch = RegExp(r'\((.+?)\s+#(\d+)\)$').firstMatch(title);
      if (sagaMatch != null) {
        saga = sagaMatch.group(1);
        nSaga = sagaMatch.group(2);
        title = title.replaceAll(sagaMatch.group(0)!, '').trim();
      }
    }

    // Remove trailing comma from saga if present
    if (saga != null && saga.endsWith(',')) {
      saga = saga.substring(0, saga.length - 1).trim();
    }

    // Clean ISBN if it has ="" format
    if (isbn != null && isbn.startsWith('="') && isbn.endsWith('"')) {
      isbn = isbn.substring(2, isbn.length - 1);
    }

    // Clean ASIN if it has ="" format
    if (asin != null && asin.startsWith('="') && asin.endsWith('"')) {
      asin = asin.substring(2, asin.length - 1);
    }

    // Parse date added (set time to 01:00)
    String? createdAt;
    if (dateAdded != null) {
      try {
        final date = DateTime.parse(dateAdded);
        createdAt =
            DateTime(date.year, date.month, date.day, 1, 0).toIso8601String();
      } catch (e) {
        createdAt = DateTime.now().toIso8601String();
      }
    } else {
      createdAt = DateTime.now().toIso8601String();
    }

    // Allow empty title for TBReleased books with author and saga
    final isTBReleased = statusValue?.toLowerCase() == 'tbreleased';
    if ((title == null || title.isEmpty) && !isTBReleased) {
      return null;
    }

    return Book(
      bookId: null,
      name: title,
      isbn: isbn,
      asin: asin,
      author: author,
      saga: saga,
      nSaga: nSaga,
      formatSagaValue: null,
      pages: pagesStr != null ? int.tryParse(pagesStr) : null,
      originalPublicationYear:
          pubYearStr != null ? int.tryParse(pubYearStr) : null,
      loaned: isReadLoaned ? 'yes' : 'no',
      statusValue: statusValue,
      editorialValue: publisher,
      languageValue: null,
      placeValue: null,
      formatValue: format,
      createdAt: createdAt,
      genre: null,
      dateReadInitial: normalizeDateFormat(
        dateAdded,
      ), // Date Added -> Date Read Started
      dateReadFinal: normalizeDateFormat(
        dateRead,
      ), // Date Read -> Date Read Finished
      readCount: readCountStr != null ? int.tryParse(readCountStr) : 0,
      myRating: myRatingStr != null ? double.tryParse(myRatingStr) : null,
      myReview: myReview,
    );
  }
}

enum CsvFormat { format1, format2, unknown }
