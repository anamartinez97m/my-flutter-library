import 'package:myrandomlibrary/discovery/index/searchable_book.dart';
import 'package:myrandomlibrary/discovery/matching/book_matcher.dart';
import 'package:myrandomlibrary/discovery/model/discovery_query.dart';

/// Turns text into a vector. Future implementations may wrap an on-device
/// model or a remote API; none is bundled.
abstract class Embedder {
  Future<List<double>> embed(String text);
}

/// Extension point for embedding-based matching.
///
/// Intended flow: `Book → SearchableTextBuilder.build → Embedder → vector
/// (cached) → cosine similarity against the query vector`, emitting
/// [BookMatch]es with `MatchSource.semantic` reasons that
/// `BookDiscoveryService` merges with keyword matches.
///
/// Not implemented and not registered: it makes no calls and returns no
/// matches.
class SemanticBookMatcher implements BookMatcher {
  final Embedder embedder;

  SemanticBookMatcher(this.embedder);

  @override
  List<BookMatch> match(DiscoveryQuery query, List<SearchableBook> books) =>
      const [];
}
