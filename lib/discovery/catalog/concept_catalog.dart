import 'package:myrandomlibrary/discovery/catalog/concept_catalog_data.dart';
import 'package:myrandomlibrary/discovery/model/theme_concept.dart';
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';

/// A catalog phrase located in a token sequence.
class PhraseHit {
  /// Index of the first matched token.
  final int start;

  /// Number of tokens covered.
  final int length;

  /// The normalized catalog phrase that matched.
  final String phrase;

  /// Concepts that list [phrase] among their terms.
  final Set<String> conceptIds;

  const PhraseHit({
    required this.start,
    required this.length,
    required this.phrase,
    required this.conceptIds,
  });

  int get end => start + length;
}

class _Phrase {
  final String text;
  final List<String> tokens;
  final Set<String> conceptIds = {};

  _Phrase(this.text, this.tokens);
}

/// Normalized phrase → concept ids lookup that matches on token boundaries
/// and treats singular/plural variants as equal.
class PhraseIndex {
  final Map<String, _Phrase> _phrases = {};
  final Map<String, List<_Phrase>> _byFirstForm = {};

  PhraseIndex._();

  factory PhraseIndex.build(Map<String, Iterable<String>> termsByConcept) {
    final index = PhraseIndex._();
    termsByConcept.forEach((conceptId, terms) {
      for (final term in terms) {
        index._add(term, conceptId);
      }
    });
    return index;
  }

  void _add(String term, String conceptId) {
    final tokens = TextNormalizer.tokenize(term);
    if (tokens.isEmpty) return;
    final text = tokens.join(' ');
    final existing = _phrases[text];
    if (existing != null) {
      existing.conceptIds.add(conceptId);
      return;
    }
    final phrase = _Phrase(text, tokens)..conceptIds.add(conceptId);
    _phrases[text] = phrase;
    for (final form in TextNormalizer.forms(tokens.first)) {
      _byFirstForm.putIfAbsent(form, () => []).add(phrase);
    }
  }

  int get length => _phrases.length;

  /// Finds catalog phrases in [tokens].
  ///
  /// With [longestOnly], scanning is greedy left-to-right and hits never
  /// overlap (`dark academia` wins over `dark`). Otherwise every phrase found
  /// at every position is reported.
  List<PhraseHit> scan(List<String> tokens, {bool longestOnly = false}) {
    final hits = <PhraseHit>[];
    var i = 0;
    while (i < tokens.length) {
      final atPosition = _matchesAt(tokens, i);
      if (atPosition.isEmpty) {
        i++;
        continue;
      }
      if (longestOnly) {
        final longest = atPosition.fold<_Phrase>(
          atPosition.first,
          (best, p) => p.tokens.length > best.tokens.length ? p : best,
        );
        hits.add(_hit(i, longest));
        i += longest.tokens.length;
      } else {
        for (final phrase in atPosition) {
          hits.add(_hit(i, phrase));
        }
        i++;
      }
    }
    return hits;
  }

  PhraseHit _hit(int start, _Phrase phrase) => PhraseHit(
    start: start,
    length: phrase.tokens.length,
    phrase: phrase.text,
    conceptIds: Set.unmodifiable(phrase.conceptIds),
  );

  List<_Phrase> _matchesAt(List<String> tokens, int start) {
    final candidates = <_Phrase>{};
    for (final form in TextNormalizer.forms(tokens[start])) {
      candidates.addAll(_byFirstForm[form] ?? const []);
    }
    return candidates.where((p) => _matchesTail(p, tokens, start)).toList();
  }

  static bool _matchesTail(_Phrase phrase, List<String> tokens, int start) {
    if (start + phrase.tokens.length > tokens.length) return false;
    for (var k = 1; k < phrase.tokens.length; k++) {
      if (!tokensEquivalent(phrase.tokens[k], tokens[start + k])) return false;
    }
    return true;
  }

  /// Whether two normalized tokens are equal up to singular/plural form.
  static bool tokensEquivalent(String a, String b) {
    if (a == b) return true;
    final formsA = TextNormalizer.forms(a);
    return TextNormalizer.forms(b).any(formsA.contains);
  }
}

/// Loads, validates and indexes [ThemeConcept]s. Consumers only use this
/// generic API and never reference concept ids directly.
class ConceptCatalog {
  final List<ThemeConcept> concepts;
  final List<String> _suggestedIds;
  final Map<String, ThemeConcept> _byId;
  late final PhraseIndex phrases = PhraseIndex.build({
    for (final c in concepts) c.id: c.allTerms,
  });
  late final PhraseIndex negativePhrases = PhraseIndex.build({
    for (final c in concepts) c.id: c.negativeKeywords,
  });

  ConceptCatalog(this.concepts, {List<String> suggestedIds = const []})
    : _suggestedIds = suggestedIds,
      _byId = {for (final c in concepts) c.id: c};

  /// The bundled catalog, built lazily once.
  static final ConceptCatalog instance = ConceptCatalog(
    kThemeConcepts,
    suggestedIds: kSuggestedConceptIds,
  );

  ThemeConcept? byId(String id) => _byId[id];

  /// One-hop related concepts of [id] (never transitive).
  List<ThemeConcept> related(String id) {
    final concept = _byId[id];
    if (concept == null) return const [];
    return concept.relatedConceptIds
        .where((r) => r != id)
        .map((r) => _byId[r])
        .whereType<ThemeConcept>()
        .toList();
  }

  List<ThemeConcept> get suggestions =>
      _suggestedIds.map((id) => _byId[id]).whereType<ThemeConcept>().toList();

  /// Integrity problems in the catalog; empty when the catalog is sound.
  List<String> validate() {
    final problems = <String>[];
    final seen = <String>{};
    for (final c in concepts) {
      if (!seen.add(c.id)) problems.add('Duplicate concept id "${c.id}"');
      if (c.displayName.trim().isEmpty || c.displayNameEs.trim().isEmpty) {
        problems.add('"${c.id}" is missing a display name');
      }
      if (c.emoji.trim().isEmpty) problems.add('"${c.id}" has no emoji');
      if (c.keywords.isEmpty) problems.add('"${c.id}" has no EN keywords');
      if (c.keywordsEs.isEmpty) problems.add('"${c.id}" has no ES keywords');
      for (final term in c.allTerms.followedBy(c.negativeKeywords)) {
        if (TextNormalizer.normalize(term).isEmpty) {
          problems.add('"${c.id}" has a term that normalizes to nothing');
        }
      }
      for (final r in c.relatedConceptIds) {
        if (!_byId.containsKey(r)) {
          problems.add('"${c.id}" relates to unknown concept "$r"');
        } else if (r == c.id) {
          problems.add('"${c.id}" relates to itself');
        }
      }
    }
    for (final id in _suggestedIds) {
      if (!_byId.containsKey(id)) problems.add('Unknown suggestion "$id"');
    }
    return problems;
  }
}
