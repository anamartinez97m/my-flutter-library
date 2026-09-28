import 'package:myrandomlibrary/discovery/index/searchable_text_builder.dart';
import 'package:myrandomlibrary/discovery/model/theme_concept.dart';
import 'package:myrandomlibrary/model/book.dart';

/// Which matching strategy produced a hit. Internal: never shown in the UI.
enum MatchSource { keyword, semantic }

/// Why a book matched: which text was found in which field.
class MatchReason {
  /// Concept the hit belongs to; `null` for literal free-term hits.
  final String? conceptId;

  /// The book text (or query term) that matched.
  final String term;
  final DiscoveryField field;
  final bool isRelated;
  final double contribution;
  final MatchSource source;

  const MatchReason({
    required this.conceptId,
    required this.term,
    required this.field,
    required this.isRelated,
    required this.contribution,
    this.source = MatchSource.keyword,
  });
}

/// A concept a book matched, direct (named in the query) or related.
class ConceptMatch {
  final ThemeConcept concept;
  final bool isDirect;
  final double contribution;

  const ConceptMatch({
    required this.concept,
    required this.isDirect,
    required this.contribution,
  });
}

/// One ranked book from the user's library.
class DiscoveryResult {
  final Book book;

  /// How well the book matches the query (0..1). Not a quality rating.
  final double relevance;

  /// Share of the query's direct concepts and free terms the book matched.
  final double coverage;

  /// Ordered by contribution, strongest first.
  final List<ConceptMatch> matchedConcepts;

  /// Ordered by contribution, strongest first.
  final List<MatchReason> reasons;

  const DiscoveryResult({
    required this.book,
    required this.relevance,
    required this.coverage,
    required this.matchedConcepts,
    required this.reasons,
  });

  int get relevancePercent => (relevance * 100).round();
}

/// Results of a discovery search split into relevance bands.
class DiscoveryResults {
  final String query;
  final List<DiscoveryResult> main;
  final List<DiscoveryResult> looselyRelated;

  const DiscoveryResults({
    required this.query,
    required this.main,
    required this.looselyRelated,
  });

  static const DiscoveryResults empty = DiscoveryResults(
    query: '',
    main: [],
    looselyRelated: [],
  );

  bool get isEmpty => main.isEmpty && looselyRelated.isEmpty;
}
