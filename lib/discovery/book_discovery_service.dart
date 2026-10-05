import 'package:myrandomlibrary/discovery/index/book_index.dart';
import 'package:myrandomlibrary/discovery/matching/book_matcher.dart';
import 'package:myrandomlibrary/discovery/matching/keyword_book_matcher.dart';
import 'package:myrandomlibrary/discovery/model/discovery_query.dart';
import 'package:myrandomlibrary/discovery/model/discovery_result.dart';
import 'package:myrandomlibrary/discovery/index/searchable_book.dart';
import 'package:myrandomlibrary/model/book.dart';

/// Entry point for theme discovery: parses the query, runs every registered
/// [BookMatcher] over the user's library, merges and ranks the results.
class BookDiscoveryService {
  static const double mainThreshold = 0.35;
  static const double looseThreshold = 0.15;
  static const int minQueryLength = 2;

  final BookIndex index;
  final List<BookMatcher> matchers;

  BookDiscoveryService({BookIndex? index, List<BookMatcher>? matchers})
    : index = index ?? BookIndex(),
      matchers = matchers ?? [KeywordBookMatcher(catalog: index?.catalog)];

  /// Ranks [books] against [rawQuery]. Only books from [books] are returned.
  DiscoveryResults search(String rawQuery, List<Book> books) {
    if (rawQuery.trim().length < minQueryLength) return DiscoveryResults.empty;
    final query = DiscoveryQuery.parse(rawQuery, catalog: index.catalog);
    if (query.isEmpty) return DiscoveryResults.empty;
    index.update(books);

    final merged = <SearchableBook, BookMatch>{};
    for (final matcher in matchers) {
      for (final match in matcher.match(query, index.entries)) {
        final existing = merged[match.entry];
        merged[match.entry] =
            existing == null ? match : _merge(existing, match);
      }
    }

    final ranked =
        merged.values.where((m) => m.relevance >= looseThreshold).toList()
          ..sort(_compare);
    final main = <DiscoveryResult>[];
    final loose = <DiscoveryResult>[];
    for (final m in ranked) {
      (m.relevance >= mainThreshold ? main : loose).add(_toResult(m));
    }
    return DiscoveryResults(query: rawQuery, main: main, looselyRelated: loose);
  }

  /// Keeps the strongest relevance and combines explanations.
  static BookMatch _merge(BookMatch a, BookMatch b) {
    final strongest = b.relevance > a.relevance ? b : a;
    final other = identical(strongest, a) ? b : a;
    final conceptIds = strongest.matchedConcepts.map((c) => c.concept.id);
    return BookMatch(
      entry: strongest.entry,
      relevance: strongest.relevance,
      coverage:
          strongest.coverage > other.coverage
              ? strongest.coverage
              : other.coverage,
      matchedConcepts: [
        ...strongest.matchedConcepts,
        ...other.matchedConcepts.where(
          (c) => !conceptIds.contains(c.concept.id),
        ),
      ],
      reasons: [...strongest.reasons, ...other.reasons],
    );
  }

  /// Unread first, then relevance, coverage, concept count and title.
  static int _compare(BookMatch a, BookMatch b) {
    if (a.entry.isRead != b.entry.isRead) return a.entry.isRead ? 1 : -1;
    final byRelevance = b.relevance.compareTo(a.relevance);
    if (byRelevance != 0) return byRelevance;
    final byCoverage = b.coverage.compareTo(a.coverage);
    if (byCoverage != 0) return byCoverage;
    final byConcepts = b.matchedConcepts.length.compareTo(
      a.matchedConcepts.length,
    );
    if (byConcepts != 0) return byConcepts;
    return a.entry.sortTitle.compareTo(b.entry.sortTitle);
  }

  static DiscoveryResult _toResult(BookMatch m) => DiscoveryResult(
    book: m.entry.book,
    relevance: m.relevance,
    coverage: m.coverage,
    matchedConcepts: m.matchedConcepts,
    reasons: m.reasons,
  );
}
