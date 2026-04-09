import 'package:myrandomlibrary/model/book.dart';

class Suggestion {
  final String description;
  final String field;
  final String value;
  final List<int> bookIds;
  final List<String> bookNames;
  final int confidence; // 0-100
  bool isApplied;
  bool isRejected;

  Suggestion({
    required this.description,
    required this.field,
    required this.value,
    required this.bookIds,
    required this.bookNames,
    required this.confidence,
    this.isApplied = false,
    this.isRejected = false,
  });
}

class SuggestionEngine {
  static List<Suggestion> generateSuggestions(List<Book> books) {
    final suggestions = <Suggestion>[];

    // Filter out bundle children
    final mainBooks = books.where((b) => b.bundleParentId == null).toList();

    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'genre'));
    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'format'));
    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'language'));
    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'place'));
    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'editorial'));
    suggestions.addAll(_analyzeSagaConsistency(mainBooks, 'genre'));
    suggestions.addAll(_analyzeSagaConsistency(mainBooks, 'format'));
    suggestions.addAll(_analyzeSagaConsistency(mainBooks, 'language'));
    suggestions.addAll(_analyzeSagaConsistency(mainBooks, 'format_saga'));
    suggestions.addAll(_analyzeMissingFieldFromPeers(mainBooks));

    // Sort by confidence (desc) then by number of affected books (desc)
    suggestions.sort((a, b) {
      final confDiff = b.confidence.compareTo(a.confidence);
      if (confDiff != 0) return confDiff;
      return b.bookIds.length.compareTo(a.bookIds.length);
    });

    return suggestions;
  }

  static String _getFieldValue(Book book, String field) {
    switch (field) {
      case 'genre':
        return book.genre ?? '';
      case 'format':
        return book.formatValue ?? '';
      case 'language':
        return book.languageValue ?? '';
      case 'place':
        return book.placeValue ?? '';
      case 'editorial':
        return book.editorialValue ?? '';
      case 'format_saga':
        return book.formatSagaValue ?? '';
      default:
        return '';
    }
  }

  /// Analyze: for each author, find fields where most books agree but some don't
  static List<Suggestion> _analyzeAuthorFieldConsistency(
    List<Book> books,
    String field,
  ) {
    final suggestions = <Suggestion>[];

    // Group books by author
    final Map<String, List<Book>> authorBooks = {};
    for (final book in books) {
      final authors =
          book.author?.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList() ?? [];
      for (final author in authors) {
        authorBooks.putIfAbsent(author, () => []).add(book);
      }
    }

    for (final entry in authorBooks.entries) {
      final author = entry.key;
      final authorBookList = entry.value;

      if (authorBookList.length < 3) continue; // Need at least 3 books

      // Count values for this field
      final Map<String, List<Book>> valueCounts = {};
      final List<Book> emptyBooks = [];

      for (final book in authorBookList) {
        final value = _getFieldValue(book, field);
        if (value.isEmpty) {
          emptyBooks.add(book);
        } else {
          // For genre, handle comma-separated
          if (field == 'genre') {
            final genres = value.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty);
            for (final genre in genres) {
              valueCounts.putIfAbsent(genre, () => []).add(book);
            }
          } else {
            valueCounts.putIfAbsent(value, () => []).add(book);
          }
        }
      }

      if (valueCounts.isEmpty || emptyBooks.isEmpty) continue;

      // Find the dominant value
      final sortedValues = valueCounts.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));

      final dominantValue = sortedValues.first.key;
      final dominantCount = sortedValues.first.value.length;
      final totalWithValue = authorBookList.length - emptyBooks.length;

      // Calculate confidence
      final confidence = totalWithValue > 0
          ? ((dominantCount / totalWithValue) * 100).round()
          : 0;

      if (confidence < 70) continue; // Below threshold

      // Find books that are missing this value
      final targetBooks = <Book>[];
      for (final book in emptyBooks) {
        targetBooks.add(book);
      }

      // Also check books that have a DIFFERENT value (for non-genre fields)
      if (field != 'genre') {
        for (final book in authorBookList) {
          final value = _getFieldValue(book, field);
          if (value.isNotEmpty && value != dominantValue) {
            // Don't suggest changing existing values for non-genre fields
            // Only suggest for empty ones
          }
        }
      }

      if (targetBooks.isEmpty) continue;

      final bookIds = targetBooks
          .where((b) => b.bookId != null)
          .map((b) => b.bookId!)
          .toList();
      final bookNames = targetBooks
          .map((b) => b.name ?? '?')
          .toList();

      if (bookIds.isEmpty) continue;

      suggestions.add(Suggestion(
        description:
            '$dominantCount/${authorBookList.length} books by $author have "$dominantValue" as ${_fieldLabel(field)}',
        field: field,
        value: dominantValue,
        bookIds: bookIds,
        bookNames: bookNames,
        confidence: confidence,
      ));
    }

    return suggestions;
  }

  /// Analyze: for each saga, find fields where most books agree but some don't
  static List<Suggestion> _analyzeSagaConsistency(
    List<Book> books,
    String field,
  ) {
    final suggestions = <Suggestion>[];

    // Group books by saga
    final Map<String, List<Book>> sagaBooks = {};
    for (final book in books) {
      final saga = book.saga;
      if (saga != null && saga.isNotEmpty) {
        sagaBooks.putIfAbsent(saga, () => []).add(book);
      }
    }

    for (final entry in sagaBooks.entries) {
      final saga = entry.key;
      final sagaBookList = entry.value;

      if (sagaBookList.length < 2) continue;

      final Map<String, List<Book>> valueCounts = {};
      final List<Book> emptyBooks = [];

      for (final book in sagaBookList) {
        final value = _getFieldValue(book, field);
        if (value.isEmpty) {
          emptyBooks.add(book);
        } else {
          if (field == 'genre') {
            final genres = value.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty);
            for (final genre in genres) {
              valueCounts.putIfAbsent(genre, () => []).add(book);
            }
          } else {
            valueCounts.putIfAbsent(value, () => []).add(book);
          }
        }
      }

      if (valueCounts.isEmpty || emptyBooks.isEmpty) continue;

      final sortedValues = valueCounts.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));

      final dominantValue = sortedValues.first.key;
      final dominantCount = sortedValues.first.value.length;
      final totalWithValue = sagaBookList.length - emptyBooks.length;

      final confidence = totalWithValue > 0
          ? ((dominantCount / totalWithValue) * 100).round()
          : 0;

      if (confidence < 70) continue;

      final bookIds = emptyBooks
          .where((b) => b.bookId != null)
          .map((b) => b.bookId!)
          .toList();
      final bookNames = emptyBooks
          .map((b) => b.name ?? '?')
          .toList();

      if (bookIds.isEmpty) continue;

      suggestions.add(Suggestion(
        description:
            '$dominantCount/${sagaBookList.length} books in saga "$saga" have "$dominantValue" as ${_fieldLabel(field)}',
        field: field,
        value: dominantValue,
        bookIds: bookIds,
        bookNames: bookNames,
        confidence: confidence,
      ));
    }

    return suggestions;
  }

  /// Find books missing common fields that their saga/author peers have
  static List<Suggestion> _analyzeMissingFieldFromPeers(List<Book> books) {
    final suggestions = <Suggestion>[];

    // Group by saga, check if some books are missing language that others have
    final Map<String, List<Book>> sagaBooks = {};
    for (final book in books) {
      final saga = book.saga;
      if (saga != null && saga.isNotEmpty) {
        sagaBooks.putIfAbsent(saga, () => []).add(book);
      }
    }

    for (final entry in sagaBooks.entries) {
      final saga = entry.key;
      final sagaBookList = entry.value;

      if (sagaBookList.length < 2) continue;

      // Check editorial field specifically (common to miss in sagas)
      final Map<String, int> editorialCounts = {};
      final List<Book> missingEditorial = [];

      for (final book in sagaBookList) {
        final editorial = book.editorialValue;
        if (editorial != null && editorial.isNotEmpty) {
          editorialCounts[editorial] = (editorialCounts[editorial] ?? 0) + 1;
        } else {
          missingEditorial.add(book);
        }
      }

      if (editorialCounts.isNotEmpty && missingEditorial.isNotEmpty) {
        final sortedEditorials = editorialCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final dominantEditorial = sortedEditorials.first.key;
        final totalWithEditorial = sagaBookList.length - missingEditorial.length;
        final confidence = totalWithEditorial > 0
            ? ((sortedEditorials.first.value / totalWithEditorial) * 100).round()
            : 0;

        if (confidence >= 70) {
          final bookIds = missingEditorial
              .where((b) => b.bookId != null)
              .map((b) => b.bookId!)
              .toList();
          final bookNames = missingEditorial
              .map((b) => b.name ?? '?')
              .toList();

          if (bookIds.isNotEmpty) {
            suggestions.add(Suggestion(
              description:
                  'Books in saga "$saga" are missing editorial, but peers have "$dominantEditorial"',
              field: 'editorial',
              value: dominantEditorial,
              bookIds: bookIds,
              bookNames: bookNames,
              confidence: confidence,
            ));
          }
        }
      }
    }

    return suggestions;
  }

  static String _fieldLabel(String field) {
    switch (field) {
      case 'genre':
        return 'genre';
      case 'format':
        return 'format';
      case 'language':
        return 'language';
      case 'place':
        return 'place';
      case 'editorial':
        return 'editorial';
      case 'format_saga':
        return 'format saga';
      default:
        return field;
    }
  }
}
