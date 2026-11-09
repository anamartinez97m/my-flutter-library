import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';
import 'package:myrandomlibrary/model/book.dart';

enum SuggestionKind {
  /// Give [Suggestion.value] to the books in [Suggestion.bookIds].
  assign,

  /// Merge [Suggestion.mergeFrom] spelling variants into [Suggestion.value].
  merge,

  /// Saga numbering problem: only a warning, the user fixes the books.
  sagaNumbering,
}

class Suggestion {
  final String description;
  final String field;
  final String value;
  final List<int> bookIds;
  final List<String> bookNames;
  final int confidence; // 0-100
  final SuggestionKind kind;

  /// Variants replaced by [value] ([SuggestionKind.merge]).
  final List<String> mergeFrom;

  /// Author or saga the suggestion was derived from ([SuggestionKind.assign])
  /// or the saga with the numbering problem ([SuggestionKind.sagaNumbering]).
  final String groupName;
  final bool groupIsSaga;
  final int dominantCount;
  final int groupSize;
  bool isApplied;
  bool isRejected;

  Suggestion({
    required this.description,
    required this.field,
    required this.value,
    required this.bookIds,
    required this.bookNames,
    required this.confidence,
    this.kind = SuggestionKind.assign,
    this.mergeFrom = const [],
    this.groupName = '',
    this.groupIsSaga = false,
    this.dominantCount = 0,
    this.groupSize = 0,
    this.isApplied = false,
    this.isRejected = false,
  });

  bool get isWarning => kind == SuggestionKind.sagaNumbering;

  /// Stable identifier for persisting the suggestion's state.
  String get id {
    final sortedBookIds = bookIds.toList()..sort();
    switch (kind) {
      case SuggestionKind.assign:
        return '$field|$value|${sortedBookIds.join(',')}';
      case SuggestionKind.merge:
        final variants = [value, ...mergeFrom]..sort();
        return 'merge|$field|${variants.join('|')}';
      case SuggestionKind.sagaNumbering:
        return 'saga_number|$groupName|$value|${sortedBookIds.join(',')}';
    }
  }
}

class SuggestionEngine {
  /// Fields whose value can hold several comma-separated entries.
  static const _multiValueFields = {'genre', 'author'};

  static const _variantFields = [
    'genre',
    'author',
    'editorial',
    'place',
    'language',
    'saga',
    'saga_universe',
  ];

  /// [SuggestionKind.sagaNumbering] values.
  static const numberingDuplicate = 'duplicate';
  static const numberingMissing = 'missing';

  static List<Suggestion> generateSuggestions(List<Book> books) {
    final suggestions = <Suggestion>[];

    // Filter out bundle children
    final mainBooks = books.where((b) => b.bundleParentId == null).toList();

    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'genre'));
    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'format'));
    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'language'));
    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'place'));
    suggestions.addAll(_analyzeAuthorFieldConsistency(mainBooks, 'editorial'));
    for (final field in const [
      'genre',
      'author',
      'format',
      'language',
      'place',
      'editorial',
      'saga_universe',
      'format_saga',
    ]) {
      suggestions.addAll(_analyzeSagaConsistency(mainBooks, field));
    }
    for (final field in _variantFields) {
      suggestions.addAll(_analyzeSpellingVariants(mainBooks, field));
    }
    suggestions.addAll(_analyzeSagaNumbering(mainBooks));

    // The same books can be flagged from their author and their saga.
    final seen = <String>{};
    suggestions.retainWhere((s) => seen.add(s.id));

    // Warnings last, then by confidence (desc) and affected books (desc)
    suggestions.sort((a, b) {
      if (a.isWarning != b.isWarning) return a.isWarning ? 1 : -1;
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
      case 'author':
        return book.author ?? '';
      case 'format':
        return book.formatValue ?? '';
      case 'language':
        return book.languageValue ?? '';
      case 'place':
        return book.placeValue ?? '';
      case 'editorial':
        return book.editorialValue ?? '';
      case 'saga':
        return book.saga ?? '';
      case 'saga_universe':
        return book.sagaUniverse ?? '';
      case 'format_saga':
        return book.formatSagaValue ?? '';
      default:
        return '';
    }
  }

  static List<String> _getFieldValues(Book book, String field) {
    final value = _getFieldValue(book, field).trim();
    if (value.isEmpty) return const [];
    if (!_multiValueFields.contains(field)) return [value];
    return value
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
  }

  /// Analyze: for each author, find fields where most books agree but some don't
  static List<Suggestion> _analyzeAuthorFieldConsistency(
    List<Book> books,
    String field,
  ) {
    final Map<String, List<Book>> authorBooks = {};
    for (final book in books) {
      for (final author in _getFieldValues(book, 'author')) {
        authorBooks.putIfAbsent(author, () => []).add(book);
      }
    }

    final suggestions = <Suggestion>[];
    for (final entry in authorBooks.entries) {
      if (entry.value.length < 3) continue; // Need at least 3 books
      final suggestion = _peerSuggestion(
        entry.value,
        field,
        groupName: entry.key,
        groupIsSaga: false,
      );
      if (suggestion != null) suggestions.add(suggestion);
    }
    return suggestions;
  }

  /// Analyze: for each saga, find fields where most books agree but some don't
  static List<Suggestion> _analyzeSagaConsistency(
    List<Book> books,
    String field,
  ) {
    final suggestions = <Suggestion>[];
    for (final entry in _groupBySaga(books).entries) {
      if (entry.value.length < 2) continue;
      final suggestion = _peerSuggestion(
        entry.value,
        field,
        groupName: entry.key,
        groupIsSaga: true,
      );
      if (suggestion != null) suggestions.add(suggestion);
    }
    return suggestions;
  }

  static Map<String, List<Book>> _groupBySaga(List<Book> books) {
    final Map<String, List<Book>> sagaBooks = {};
    for (final book in books) {
      final saga = book.saga?.trim();
      if (saga != null && saga.isNotEmpty) {
        sagaBooks.putIfAbsent(saga, () => []).add(book);
      }
    }
    return sagaBooks;
  }

  /// Suggests the dominant value of [field] in [group] for the books of the
  /// group that have it empty.
  static Suggestion? _peerSuggestion(
    List<Book> group,
    String field, {
    required String groupName,
    required bool groupIsSaga,
  }) {
    final Map<String, int> valueCounts = {};
    final List<Book> emptyBooks = [];

    for (final book in group) {
      final values = _getFieldValues(book, field);
      if (values.isEmpty) {
        emptyBooks.add(book);
      } else {
        for (final value in values) {
          valueCounts[value] = (valueCounts[value] ?? 0) + 1;
        }
      }
    }

    if (valueCounts.isEmpty || emptyBooks.isEmpty) return null;

    final sortedValues =
        valueCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final dominantValue = sortedValues.first.key;
    final dominantCount = sortedValues.first.value;
    final totalWithValue = group.length - emptyBooks.length;
    final confidence =
        totalWithValue > 0
            ? ((dominantCount / totalWithValue) * 100).round()
            : 0;

    if (confidence < 70) return null;

    final targets = emptyBooks.where((b) => b.bookId != null).toList();
    if (targets.isEmpty) return null;

    final where = groupIsSaga ? 'in saga "$groupName"' : 'by $groupName';
    return Suggestion(
      description:
          '$dominantCount/${group.length} books $where have "$dominantValue" as ${_fieldLabel(field)}',
      field: field,
      value: dominantValue,
      bookIds: targets.map((b) => b.bookId!).toList(),
      bookNames: targets.map((b) => b.name ?? '?').toList(),
      confidence: confidence,
      groupName: groupName,
      groupIsSaga: groupIsSaga,
      dominantCount: dominantCount,
      groupSize: group.length,
    );
  }

  /// Values of [field] that only differ by accents, capitals or punctuation,
  /// e.g. "Fantasia" and "Fantasía".
  static List<Suggestion> _analyzeSpellingVariants(
    List<Book> books,
    String field,
  ) {
    final Map<String, Map<String, List<Book>>> byNormalized = {};
    for (final book in books) {
      for (final value in _getFieldValues(book, field)) {
        final key = TextNormalizer.normalize(value);
        if (key.isEmpty) continue;
        byNormalized
            .putIfAbsent(key, () => {})
            .putIfAbsent(value, () => [])
            .add(book);
      }
    }

    final suggestions = <Suggestion>[];
    for (final variants in byNormalized.values) {
      if (variants.length < 2) continue;
      final ranked =
          variants.entries.toList()..sort((a, b) {
            final count = b.value.length.compareTo(a.value.length);
            if (count != 0) return count;
            final accents = _nonAscii(b.key).compareTo(_nonAscii(a.key));
            if (accents != 0) return accents;
            final capital = _startsUpper(b.key).compareTo(_startsUpper(a.key));
            if (capital != 0) return capital;
            return a.key.compareTo(b.key);
          });
      final target = ranked.first.key;
      final others = ranked.skip(1).toList();
      final affected = <int, Book>{};
      for (final entry in others) {
        for (final book in entry.value) {
          if (book.bookId != null) affected[book.bookId!] = book;
        }
      }
      if (affected.isEmpty) continue;

      final from = others.map((e) => e.key).toList();
      suggestions.add(
        Suggestion(
          description:
              '${from.map((v) => '"$v"').join(', ')} look like "$target" (${_fieldLabel(field)})',
          field: field,
          value: target,
          bookIds: affected.keys.toList(),
          bookNames: affected.values.map((b) => b.name ?? '?').toList(),
          confidence: 95,
          kind: SuggestionKind.merge,
          mergeFrom: from,
        ),
      );
    }
    return suggestions;
  }

  static int _nonAscii(String value) =>
      value.runes.where((r) => r > 127).length;

  static int _startsUpper(String value) =>
      value.isNotEmpty && value[0] != value[0].toLowerCase() ? 1 : 0;

  /// Sagas where two books share a number, or where some books have a
  /// number and others don't.
  static List<Suggestion> _analyzeSagaNumbering(List<Book> books) {
    final candidates =
        books
            .where(
              (b) =>
                  b.bookId != null &&
                  b.originalBookId == null &&
                  !b.isPlaceholder,
            )
            .toList();

    final suggestions = <Suggestion>[];
    for (final entry in _groupBySaga(candidates).entries) {
      final saga = entry.key;
      final sagaBooks = entry.value;
      if (sagaBooks.length < 2) continue;

      final Map<String, List<Book>> byNumber = {};
      final unnumbered = <Book>[];
      for (final book in sagaBooks) {
        final number = book.nSaga?.trim() ?? '';
        if (number.isEmpty) {
          unnumbered.add(book);
        } else {
          byNumber.putIfAbsent(_numberKey(number), () => []).add(book);
        }
      }

      for (final group in byNumber.values) {
        if (group.length < 2) continue;
        final number = group.first.nSaga!.trim();
        suggestions.add(
          Suggestion(
            description:
                '${group.length} books in saga "$saga" have number $number',
            field: 'saga',
            value: '$numberingDuplicate:$number',
            bookIds: group.map((b) => b.bookId!).toList(),
            bookNames: group.map((b) => b.name ?? '?').toList(),
            confidence: 0,
            kind: SuggestionKind.sagaNumbering,
            groupName: saga,
            groupIsSaga: true,
            groupSize: sagaBooks.length,
          ),
        );
      }

      if (byNumber.isNotEmpty && unnumbered.isNotEmpty) {
        suggestions.add(
          Suggestion(
            description:
                '${unnumbered.length} books in saga "$saga" have no number',
            field: 'saga',
            value: numberingMissing,
            bookIds: unnumbered.map((b) => b.bookId!).toList(),
            bookNames: unnumbered.map((b) => b.name ?? '?').toList(),
            confidence: 0,
            kind: SuggestionKind.sagaNumbering,
            groupName: saga,
            groupIsSaga: true,
            groupSize: sagaBooks.length,
          ),
        );
      }
    }
    return suggestions;
  }

  static String _numberKey(String number) {
    final parsed = double.tryParse(number.replaceAll(',', '.'));
    return parsed != null ? parsed.toString() : number.toLowerCase();
  }

  static String _fieldLabel(String field) {
    switch (field) {
      case 'format_saga':
        return 'format saga';
      case 'saga_universe':
        return 'saga universe';
      default:
        return field;
    }
  }
}
