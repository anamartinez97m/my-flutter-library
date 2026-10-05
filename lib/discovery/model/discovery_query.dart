import 'package:myrandomlibrary/discovery/catalog/concept_catalog.dart';
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';

/// A parsed free-text discovery query.
///
/// The raw text is never assumed to be a concept id: catalog phrases are
/// recognised (longest first), expanded one hop to related concepts, negation
/// windows are applied and remaining meaningful words become free terms that
/// are matched literally against book fields.
class DiscoveryQuery {
  /// Tokens that open a negation window (`not horror`, `sin terror`).
  static const Set<String> negationTriggers = {
    'not',
    'no',
    'without',
    'except',
    'excluding',
    'nor',
    'sin',
    'ni',
    'excepto',
    'salvo',
  };

  /// Tokens that close a negation window (`not horror but with witches`).
  static const Set<String> negationBreaks = {
    'but',
    'and',
    'with',
    'yet',
    'pero',
    'y',
    'con',
    'aunque',
  };

  static const Set<String> stopWords = {
    // English
    'a', 'an', 'the', 'some', 'something', 'anything', 'any', 'book',
    'books', 'novel', 'novels', 'read', 'reads', 'reading', 'story',
    'stories', 'with', 'and', 'or', 'but', 'of', 'in', 'on', 'for', 'to',
    'about',
    'by',
    'from',
    'that',
    'this',
    'like',
    'i',
    'im',
    'me',
    'my',
    'want',
    'wanna',
    'would', 'mood', 'feel', 'feeling', 'kind', 'type', 'sort', 'lots',
    'lot', 'very', 'really', 'more', 'please', 'give', 'show', 'find',
    'is', 'are', 'be', 'it', 'its', 'set', 'where', 'who', 'what', 'has',
    'have', 'yet', 'also', 'plus', 'good', 'great', 'vibes', 'vibe',
    // Spanish
    'un', 'una', 'unos', 'unas', 'el', 'la', 'los', 'las', 'lo', 'de',
    'del', 'al', 'con', 'y', 'e', 'o', 'u', 'pero', 'que', 'algo',
    'alguno', 'alguna', 'libro', 'libros', 'novela', 'novelas', 'historia',
    'historias', 'sobre', 'para', 'por', 'en', 'mi', 'quiero',
    'leer', 'lectura', 'tipo', 'muy', 'mas', 'como', 'es', 'son', 'hay',
    'donde', 'tenga', 'tengan', 'aunque', 'ambientado', 'ambientada',
  };

  final String raw;
  final String normalized;

  /// Concepts named directly in the query, in order of appearance.
  final List<String> directConceptIds;

  /// Query text that triggered each direct concept.
  final Map<String, String> directConceptTerms;

  /// One-hop related concepts of the direct ones (never transitive).
  final Set<String> relatedConceptIds;

  /// Concepts the user explicitly does not want.
  final Set<String> negatedConceptIds;

  /// Meaningful residual words, matched literally.
  final List<String> freeTerms;

  /// Residual words inside a negation window.
  final List<String> negatedTerms;

  const DiscoveryQuery._({
    required this.raw,
    required this.normalized,
    required this.directConceptIds,
    required this.directConceptTerms,
    required this.relatedConceptIds,
    required this.negatedConceptIds,
    required this.freeTerms,
    required this.negatedTerms,
  });

  /// Whether the query has anything positive to search for.
  bool get isEmpty => directConceptIds.isEmpty && freeTerms.isEmpty;

  factory DiscoveryQuery.parse(String raw, {ConceptCatalog? catalog}) {
    final cat = catalog ?? ConceptCatalog.instance;
    final tokens = TextNormalizer.tokenize(raw);
    final negatedAt = _negationMask(tokens);

    final direct = <String>[];
    final directTerms = <String, String>{};
    final negated = <String>{};
    final covered = List<bool>.filled(tokens.length, false);

    for (final hit in cat.phrases.scan(tokens, longestOnly: true)) {
      for (var k = hit.start; k < hit.end; k++) {
        covered[k] = true;
      }
      final text = tokens.sublist(hit.start, hit.end).join(' ');
      final isNegated = negatedAt[hit.start];
      for (final id in hit.conceptIds) {
        if (isNegated) {
          negated.add(id);
        } else if (!directTerms.containsKey(id)) {
          direct.add(id);
          directTerms[id] = text;
        }
      }
    }
    direct.removeWhere(negated.contains);
    directTerms.removeWhere((id, _) => negated.contains(id));

    final related = <String>{
      for (final id in direct) ...cat.related(id).map((c) => c.id),
    }..removeWhere((id) => directTerms.containsKey(id) || negated.contains(id));

    final free = <String>[];
    final negatedFree = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (covered[i] ||
          negationTriggers.contains(token) ||
          stopWords.contains(token) ||
          token.length < 2) {
        continue;
      }
      final target = negatedAt[i] ? negatedFree : free;
      if (!target.contains(token)) target.add(token);
    }

    return DiscoveryQuery._(
      raw: raw,
      normalized: tokens.join(' '),
      directConceptIds: List.unmodifiable(direct),
      directConceptTerms: Map.unmodifiable(directTerms),
      relatedConceptIds: Set.unmodifiable(related),
      negatedConceptIds: Set.unmodifiable(negated),
      freeTerms: List.unmodifiable(free),
      negatedTerms: List.unmodifiable(negatedFree),
    );
  }

  /// `true` for tokens inside a negation window: after a trigger, up to the
  /// next break word.
  static List<bool> _negationMask(List<String> tokens) {
    final mask = List<bool>.filled(tokens.length, false);
    var inWindow = false;
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (negationTriggers.contains(token)) {
        inWindow = true;
      } else if (negationBreaks.contains(token)) {
        inWindow = false;
      } else {
        mask[i] = inWindow;
      }
    }
    return mask;
  }
}
