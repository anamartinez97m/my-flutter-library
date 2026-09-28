import 'package:myrandomlibrary/discovery/catalog/concept_catalog.dart';
import 'package:myrandomlibrary/discovery/index/searchable_text_builder.dart';
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';
import 'package:myrandomlibrary/model/book.dart';

/// A [Book] with its fields pre-normalized, tokenized and scanned against the
/// concept catalog, so queries never re-process book text.
class SearchableBook {
  static const Set<String> _readStatuses = {'yes', 'repeated'};

  final Book book;

  /// Normalized token segments per field. A phrase never spans segments.
  final Map<DiscoveryField, List<List<String>>> segments;

  /// Singular/plural forms of every token per field, for free-term lookup.
  final Map<DiscoveryField, Set<String>> _forms;

  /// conceptId → field → first book text that matched one of the concept's
  /// catalog phrases.
  final Map<String, Map<DiscoveryField, String>> conceptHits;

  /// conceptId → field → first book text that matched a negative keyword.
  final Map<String, Map<DiscoveryField, String>> negativeHits;

  SearchableBook._(
    this.book,
    this.segments,
    this._forms,
    this.conceptHits,
    this.negativeHits,
  );

  factory SearchableBook.from(Book book, ConceptCatalog catalog) {
    final segments = <DiscoveryField, List<List<String>>>{};
    final forms = <DiscoveryField, Set<String>>{};
    final conceptHits = <String, Map<DiscoveryField, String>>{};
    final negativeHits = <String, Map<DiscoveryField, String>>{};

    SearchableTextBuilder.fields(book).forEach((field, values) {
      final fieldSegments =
          [
            for (final value in values)
              for (final segment in TextNormalizer.segments(value))
                TextNormalizer.tokenize(segment),
          ].where((tokens) => tokens.isNotEmpty).toList();
      segments[field] = fieldSegments;
      forms[field] = {
        for (final tokens in fieldSegments)
          for (final token in tokens) ...TextNormalizer.forms(token),
      };
      for (final tokens in fieldSegments) {
        _record(conceptHits, field, tokens, catalog.phrases.scan(tokens));
        _record(
          negativeHits,
          field,
          tokens,
          catalog.negativePhrases.scan(tokens),
        );
      }
    });

    return SearchableBook._(book, segments, forms, conceptHits, negativeHits);
  }

  static void _record(
    Map<String, Map<DiscoveryField, String>> target,
    DiscoveryField field,
    List<String> tokens,
    List<PhraseHit> hits,
  ) {
    for (final hit in hits) {
      final text = tokens.sublist(hit.start, hit.end).join(' ');
      for (final id in hit.conceptIds) {
        target.putIfAbsent(id, () => {}).putIfAbsent(field, () => text);
      }
    }
  }

  /// Whether the user has finished this book at least once.
  bool get isRead => _readStatuses.contains(book.statusValue?.toLowerCase());

  String get sortTitle => TextNormalizer.normalize(book.name);

  /// Whether the normalized [term] (one or more tokens) occurs in [field] on
  /// token boundaries, allowing singular/plural variants.
  bool containsTerm(DiscoveryField field, List<String> term) {
    if (term.isEmpty) return false;
    if (term.length == 1) {
      final fieldForms = _forms[field];
      if (fieldForms == null) return false;
      return TextNormalizer.forms(term.first).any(fieldForms.contains);
    }
    for (final tokens in segments[field] ?? const <List<String>>[]) {
      for (var i = 0; i + term.length <= tokens.length; i++) {
        var matched = true;
        for (var k = 0; k < term.length; k++) {
          if (!PhraseIndex.tokensEquivalent(term[k], tokens[i + k])) {
            matched = false;
            break;
          }
        }
        if (matched) return true;
      }
    }
    return false;
  }
}
