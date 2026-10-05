import 'dart:math' as math;

import 'package:myrandomlibrary/discovery/catalog/concept_catalog.dart';
import 'package:myrandomlibrary/discovery/index/searchable_book.dart';
import 'package:myrandomlibrary/discovery/index/searchable_text_builder.dart';
import 'package:myrandomlibrary/discovery/matching/book_matcher.dart';
import 'package:myrandomlibrary/discovery/model/discovery_query.dart';
import 'package:myrandomlibrary/discovery/model/discovery_result.dart';
import 'package:myrandomlibrary/discovery/model/theme_concept.dart';
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';

/// Deterministic, local matcher driven by the concept catalog and literal
/// query terms, weighted by the field each hit appears in.
class KeywordBookMatcher implements BookMatcher {
  static const double directMultiplier = 1.0;
  static const double freeTermMultiplier = 0.9;
  static const double relatedMultiplier = 0.4;

  /// Weight of the second-best field for the same concept or term.
  static const double secondFieldBonus = 0.1;

  /// Maximum contribution of a single related concept, so one related
  /// concept alone never reaches the main band.
  static const double relatedConceptCap = 0.3;

  /// Maximum total related-concept contribution per query unit.
  static const double relatedCapPerUnit = 0.3;

  /// Ceiling for books that only match related concepts: several related
  /// hits can reach the main band, but never outrank a direct match.
  static const double relatedOnlyCeiling = 0.45;

  /// Penalty for a negated concept/term found outside title and genre.
  static const double negationPenalty = 0.3;

  static const Set<DiscoveryField> _excludingFields = {
    DiscoveryField.title,
    DiscoveryField.genre,
  };

  final ConceptCatalog catalog;

  KeywordBookMatcher({ConceptCatalog? catalog})
    : catalog = catalog ?? ConceptCatalog.instance;

  @override
  List<BookMatch> match(DiscoveryQuery query, List<SearchableBook> books) {
    if (query.isEmpty) return const [];
    final freeTerms = [
      for (final t in query.freeTerms) TextNormalizer.tokenize(t),
    ];
    final negatedTerms = [
      for (final t in query.negatedTerms) TextNormalizer.tokenize(t),
    ];
    final matches = <BookMatch>[];
    for (final entry in books) {
      final match = _score(query, freeTerms, negatedTerms, entry);
      if (match != null) matches.add(match);
    }
    return matches;
  }

  BookMatch? _score(
    DiscoveryQuery query,
    List<List<String>> freeTerms,
    List<List<String>> negatedTerms,
    SearchableBook entry,
  ) {
    var penalty = 1.0;
    for (final id in query.negatedConceptIds) {
      final fields = entry.conceptHits[id]?.keys ?? const [];
      if (fields.any(_excludingFields.contains)) return null;
      if (fields.isNotEmpty) penalty *= negationPenalty;
    }
    for (final term in negatedTerms) {
      final fields = DiscoveryField.values.where(
        (f) => entry.containsTerm(f, term),
      );
      if (fields.any(_excludingFields.contains)) return null;
      if (fields.isNotEmpty) penalty *= negationPenalty;
    }
    for (final id in query.directConceptIds) {
      final fields = entry.negativeHits[id]?.keys ?? const [];
      if (fields.any(_excludingFields.contains)) return null;
      if (fields.isNotEmpty) penalty *= negationPenalty;
    }

    final reasons = <MatchReason>[];
    final concepts = <ConceptMatch>[];
    var directScore = 0.0;
    var matchedUnits = 0;

    for (final id in query.directConceptIds) {
      final score = _conceptScore(entry, id, directMultiplier, false, reasons);
      if (score == null) continue;
      directScore += score;
      matchedUnits++;
      _addConcept(concepts, id, true, score);
    }

    var freeScore = 0.0;
    for (var i = 0; i < freeTerms.length; i++) {
      final contribs = <DiscoveryField, double>{
        for (final f in DiscoveryField.values)
          if (entry.containsTerm(f, freeTerms[i]))
            f: f.weight * freeTermMultiplier,
      };
      if (contribs.isEmpty) continue;
      final score = _aggregate(contribs.values);
      freeScore += score;
      matchedUnits++;
      final best = _best(contribs);
      reasons.add(
        MatchReason(
          conceptId: null,
          term: query.freeTerms[i],
          field: best,
          isRelated: false,
          contribution: contribs[best]!,
        ),
      );
    }

    var relatedScore = 0.0;
    for (final id in query.relatedConceptIds) {
      final raw = _conceptScore(entry, id, relatedMultiplier, true, reasons);
      if (raw == null) continue;
      final score = math.min(raw, relatedConceptCap);
      relatedScore += score;
      _addConcept(concepts, id, false, score);
    }

    final units = query.directConceptIds.length + query.freeTerms.length;
    final uncappedRelated = relatedScore;
    relatedScore = math.min(relatedScore, relatedCapPerUnit * units);
    final raw = directScore + freeScore + relatedScore;
    if (raw <= 0) return null;

    final ideal =
        query.directConceptIds.length * directMultiplier +
        query.freeTerms.length * freeTermMultiplier;
    final coverage = units == 0 ? 0.0 : matchedUnits / units;
    final relevance =
        matchedUnits == 0
            ? math.min(uncappedRelated / ideal, relatedOnlyCeiling)
            : (raw / ideal) * (0.6 + 0.4 * coverage);
    final penalized = (relevance * penalty).clamp(0.0, 1.0);
    if (penalized <= 0) return null;

    concepts.sort((a, b) => b.contribution.compareTo(a.contribution));
    reasons.sort((a, b) => b.contribution.compareTo(a.contribution));
    return BookMatch(
      entry: entry,
      relevance: penalized,
      coverage: coverage,
      matchedConcepts: List.unmodifiable(concepts),
      reasons: List.unmodifiable(reasons),
    );
  }

  double? _conceptScore(
    SearchableBook entry,
    String conceptId,
    double multiplier,
    bool isRelated,
    List<MatchReason> reasons,
  ) {
    final hits = entry.conceptHits[conceptId];
    if (hits == null || hits.isEmpty) return null;
    final contribs = {for (final f in hits.keys) f: f.weight * multiplier};
    final best = _best(contribs);
    reasons.add(
      MatchReason(
        conceptId: conceptId,
        term: hits[best]!,
        field: best,
        isRelated: isRelated,
        contribution: contribs[best]!,
      ),
    );
    return _aggregate(contribs.values);
  }

  void _addConcept(
    List<ConceptMatch> concepts,
    String id,
    bool isDirect,
    double score,
  ) {
    final ThemeConcept? concept = catalog.byId(id);
    if (concept == null) return;
    concepts.add(
      ConceptMatch(concept: concept, isDirect: isDirect, contribution: score),
    );
  }

  static DiscoveryField _best(Map<DiscoveryField, double> contribs) =>
      contribs.entries.reduce((a, b) => b.value > a.value ? b : a).key;

  /// Best field plus a small bonus for the second-best one, so repeated hits
  /// in one long field never dominate.
  static double _aggregate(Iterable<double> contribs) {
    final sorted = contribs.toList()..sort((a, b) => b.compareTo(a));
    if (sorted.isEmpty) return 0;
    final second = sorted.length > 1 ? sorted[1] : 0.0;
    return sorted.first + secondFieldBonus * second;
  }
}
