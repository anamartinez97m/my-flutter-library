import 'package:myrandomlibrary/discovery/index/searchable_book.dart';
import 'package:myrandomlibrary/discovery/model/discovery_query.dart';
import 'package:myrandomlibrary/discovery/model/discovery_result.dart';

/// A book scored by one [BookMatcher].
class BookMatch {
  final SearchableBook entry;

  /// Query match strength in 0..1, comparable across matchers.
  final double relevance;
  final double coverage;
  final List<ConceptMatch> matchedConcepts;
  final List<MatchReason> reasons;

  const BookMatch({
    required this.entry,
    required this.relevance,
    required this.coverage,
    required this.matchedConcepts,
    required this.reasons,
  });
}

/// Strategy that scores indexed books against a query. The discovery service
/// only depends on this contract, so strategies can be combined or swapped.
abstract class BookMatcher {
  /// Returns a match for every book with a non-zero relevance. Books that
  /// must be excluded (e.g. negated in their genre) are simply omitted.
  List<BookMatch> match(DiscoveryQuery query, List<SearchableBook> books);
}
