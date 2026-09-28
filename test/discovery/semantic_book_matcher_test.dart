import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/discovery/book_discovery_service.dart';
import 'package:myrandomlibrary/discovery/index/book_index.dart';
import 'package:myrandomlibrary/discovery/matching/keyword_book_matcher.dart';
import 'package:myrandomlibrary/discovery/matching/semantic_book_matcher.dart';
import 'package:myrandomlibrary/discovery/model/discovery_query.dart';

import 'discovery_test_utils.dart';

class _CountingEmbedder implements Embedder {
  int calls = 0;

  @override
  Future<List<double>> embed(String text) async {
    calls++;
    return const [];
  }
}

void main() {
  test('semantic matcher skeleton makes no calls and returns nothing', () {
    final embedder = _CountingEmbedder();
    final index = BookIndex()..update([makeBook(name: 'Witches')]);
    final matches = SemanticBookMatcher(
      embedder,
    ).match(DiscoveryQuery.parse('witches'), index.entries);
    expect(matches, isEmpty);
    expect(embedder.calls, 0);
  });

  test('service registers only the keyword matcher by default', () {
    final service = BookDiscoveryService();
    expect(service.matchers.single, isA<KeywordBookMatcher>());
  });

  test('adding the semantic matcher does not change keyword results', () {
    final books = [makeBook(name: 'Witches Abroad')];
    final base = BookDiscoveryService().search('witches', books);
    final combined = BookDiscoveryService(
      matchers: [
        KeywordBookMatcher(),
        SemanticBookMatcher(_CountingEmbedder()),
      ],
    ).search('witches', books);
    expect(combined.main.single.relevance, base.main.single.relevance);
  });
}
