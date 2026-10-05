import 'dart:convert';

import 'package:myrandomlibrary/model/book.dart';

/// Book fields the discovery engine searches, strongest signal first.
enum DiscoveryField { title, genre, saga, description, author, notes }

extension DiscoveryFieldWeight on DiscoveryField {
  /// How strongly a hit in this field signals relevance.
  double get weight => switch (this) {
    DiscoveryField.title => 1.00,
    DiscoveryField.genre => 0.85,
    DiscoveryField.saga => 0.70,
    DiscoveryField.description => 0.55,
    DiscoveryField.author => 0.25,
    DiscoveryField.notes => 0.20,
  };
}

/// Extracts the raw searchable text of a [Book]. Null-safe: missing metadata
/// simply yields no values.
class SearchableTextBuilder {
  const SearchableTextBuilder._();

  /// Raw (un-normalized) values per field.
  static Map<DiscoveryField, List<String>> fields(Book book) => {
    DiscoveryField.title: _nonEmpty([book.name, ..._bundleTitles(book)]),
    DiscoveryField.genre: _nonEmpty(book.genre?.split(',') ?? const []),
    DiscoveryField.saga: _nonEmpty([book.saga, book.sagaUniverse]),
    DiscoveryField.description: _nonEmpty([book.description]),
    DiscoveryField.author: _nonEmpty([book.author]),
    DiscoveryField.notes: _nonEmpty([book.notes, book.myReview]),
  };

  /// Canonical single-document text for a book. This is the input a future
  /// embedding step would consume.
  static String build(Book book) {
    final f = fields(book);
    final lines = <String>[
      if (f[DiscoveryField.title]!.isNotEmpty)
        'Title: ${f[DiscoveryField.title]!.join('; ')}',
      if (book.author?.trim().isNotEmpty ?? false)
        'Author: ${book.author!.trim()}',
      if (f[DiscoveryField.genre]!.isNotEmpty)
        'Genres: ${f[DiscoveryField.genre]!.join(', ')}',
      if (book.saga?.trim().isNotEmpty ?? false) 'Saga: ${book.saga!.trim()}',
      if (book.sagaUniverse?.trim().isNotEmpty ?? false)
        'Universe: ${book.sagaUniverse!.trim()}',
      if (book.description?.trim().isNotEmpty ?? false)
        'Description: ${book.description!.trim()}',
    ];
    return lines.join('\n');
  }

  static List<String> _bundleTitles(Book book) {
    final raw = book.bundleTitles;
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Object>().map((t) => t.toString()).toList();
      }
    } on FormatException {
      // Not JSON: treat as plain text.
    }
    return [raw];
  }

  static List<String> _nonEmpty(Iterable<String?> values) =>
      values
          .whereType<String>()
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toList();
}
