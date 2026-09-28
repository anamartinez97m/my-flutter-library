import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/discovery/book_discovery_service.dart';
import 'package:myrandomlibrary/discovery/index/book_index.dart';
import 'package:myrandomlibrary/discovery/index/searchable_book.dart';
import 'package:myrandomlibrary/discovery/matching/book_matcher.dart';
import 'package:myrandomlibrary/discovery/model/discovery_query.dart';
import 'package:myrandomlibrary/discovery/model/discovery_result.dart';
import 'package:myrandomlibrary/model/book.dart';

import 'discovery_test_utils.dart';

class _FixedMatcher implements BookMatcher {
  final Map<String, double> relevanceByTitle;

  _FixedMatcher(this.relevanceByTitle);

  @override
  List<BookMatch> match(DiscoveryQuery query, List<SearchableBook> books) => [
    for (final e in books)
      if (relevanceByTitle.containsKey(e.book.name))
        BookMatch(
          entry: e,
          relevance: relevanceByTitle[e.book.name]!,
          coverage: 1,
          matchedConcepts: const [],
          reasons: const [],
        ),
  ];
}

void main() {
  late BookDiscoveryService service;

  setUp(() => service = BookDiscoveryService());

  List<String?> names(List<DiscoveryResult> results) =>
      results.map((r) => r.book.name).toList();

  DiscoveryResult? find(DiscoveryResults r, String name) =>
      [
        ...r.main,
        ...r.looselyRelated,
      ].where((x) => x.book.name == name).firstOrNull;

  final library = <Book>[
    makeBook(
      name: 'The Witching Hour',
      genre: 'Fantasy, Witches',
      description: 'A coven gathers on Halloween night.',
    ),
    makeBook(
      name: 'Kingdom of Swords',
      genre: 'Fantasy',
      description: 'A young mage embarks on a journey across realms.',
    ),
    makeBook(
      name: 'Snowed In For The Holidays',
      genre: 'Christmas, Romance',
      description: 'A festive love story.',
    ),
    makeBook(
      name: 'The Secret History',
      genre: 'Literary Fiction',
      description: 'Students at an elite university form a secret society.',
    ),
    makeBook(
      name: 'Hexed Hearts',
      genre: 'Romance, Witches',
      description: 'She casts a spell and falls in love.',
    ),
    makeBook(
      name: 'Just Romance',
      genre: 'Romance',
      description: 'Two strangers fall in love.',
    ),
    makeBook(
      name: 'It',
      genre: 'Horror',
      description: 'A spooky clown haunts a small town.',
    ),
    makeBook(
      name: 'Pumpkin Spice Mysteries',
      genre: 'Cozy, Mystery',
      description: 'A spooky whodunit in a quiet village.',
    ),
  ];

  test('empty, short and noise-only queries return nothing', () {
    for (final q in ['', ' ', 'a', 'the book']) {
      expect(service.search(q, library).isEmpty, isTrue, reason: q);
    }
  });

  test('no matches returns an empty result', () {
    expect(service.search('cyberpunk', library).isEmpty, isTrue);
  });

  test('only books from the given library are returned', () {
    final r = service.search('witches', library);
    for (final x in [...r.main, ...r.looselyRelated]) {
      expect(library.any((b) => identical(b, x.book)), isTrue);
    }
  });

  test('ranking: title > genre > description > related', () {
    final books = [
      makeBook(name: 'Related', genre: 'Magic'),
      makeBook(name: 'Desc', description: 'There is a witch.'),
      makeBook(name: 'Genre', genre: 'Witches'),
      makeBook(name: 'Witches Abroad'),
    ];
    final r = service.search('witches', books);
    expect(names(r.main), ['Witches Abroad', 'Genre', 'Desc']);
    expect(names(r.looselyRelated), ['Related']);
  });

  test('romance with witches prefers books matching both', () {
    final r = service.search('romance with witches', library);
    expect(r.main.first.book.name, 'Hexed Hearts');
    expect(
      r.main.first.relevance,
      greaterThan(find(r, 'Just Romance')!.relevance),
    );
  });

  test('Halloween matches a witch book', () {
    final r = service.search('Halloween', library);
    expect(names(r.main), contains('The Witching Hour'));
  });

  test('Halloween does not strongly match a generic fantasy book', () {
    final r = service.search('Halloween', library);
    expect(names(r.main), isNot(contains('Kingdom of Swords')));
  });

  test('a book with only related concepts is at most loosely related', () {
    final books = [makeBook(name: 'Hannah', genre: 'Witches')];
    final r = service.search('Halloween', books);
    expect(r.main, isEmpty);
    expect(names(r.looselyRelated), ['Hannah']);
  });

  test('Winter does not automatically match every Christmas book', () {
    final r = service.search('winter', library);
    expect(names(r.main), isNot(contains('Snowed In For The Holidays')));
  });

  test('Dark Academia matches via university / secret society', () {
    final r = service.search('dark academia', library);
    expect(r.main.first.book.name, 'The Secret History');
  });

  test('spooky but not horror excludes horror-genre books', () {
    final r = service.search('something spooky but not horror', library);
    expect(find(r, 'It'), isNull);
    expect(names(r.main), contains('Pumpkin Spice Mysteries'));
  });

  test('Spanish query matches an English witch book and vice versa', () {
    final es = service.search('brujas', library);
    expect(names(es.main), contains('Hexed Hearts'));

    final spanishBook = makeBook(
      name: 'La casa de las brujas',
      genre: 'Fantasía',
      description: 'Una historia de brujería.',
    );
    final en = service.search('witches', [spanishBook]);
    expect(names(en.main), ['La casa de las brujas']);
  });

  test('results expose responsible concepts and reasons', () {
    final r = service.search('Halloween', library);
    final hit = find(r, 'The Witching Hour')!;
    expect(hit.matchedConcepts.first.concept.id, 'halloween');
    expect(hit.matchedConcepts.first.isDirect, isTrue);
    expect(hit.matchedConcepts.any((c) => c.concept.id == 'witches'), isTrue);
    expect(hit.reasons, isNotEmpty);
    expect(hit.relevancePercent, inInclusiveRange(0, 100));
  });

  test('unread books come first within a band; relevance unchanged', () {
    final read = makeBook(name: 'Witches Read', status: 'yes');
    final unread = makeBook(name: 'Unread', genre: 'Witches');
    final r = service.search('witches', [read, unread]);
    expect(names(r.main), ['Unread', 'Witches Read']);
    expect(r.main.last.relevance, greaterThan(r.main.first.relevance));
  });

  test('band boundaries at 0.15 and 0.35', () {
    final books = [
      for (final n in ['a', 'b', 'c', 'd', 'e']) makeBook(name: n),
    ];
    final fixed = BookDiscoveryService(
      matchers: [
        _FixedMatcher({'a': 0.35, 'b': 0.349, 'c': 0.15, 'd': 0.149, 'e': 0.9}),
      ],
    );
    final r = fixed.search('anything goes', books);
    expect(names(r.main), ['e', 'a']);
    expect(names(r.looselyRelated), ['b', 'c']);
  });

  test('multiple matchers are merged by strongest relevance', () {
    final books = [makeBook(name: 'x'), makeBook(name: 'y')];
    final merged = BookDiscoveryService(
      matchers: [
        _FixedMatcher({'x': 0.2, 'y': 0.9}),
        _FixedMatcher({'x': 0.8}),
      ],
    );
    final r = merged.search('whatever', books);
    expect(names(r.main), ['y', 'x']);
    expect(r.main.last.relevance, 0.8);
  });

  test('bundle children and placeholders are never returned', () {
    final r = service.search('witches', [
      makeBook(name: 'Witches Child', bundleParentId: 99),
      makeBook(name: 'Witches Placeholder', isPlaceholder: true),
    ]);
    expect(r.isEmpty, isTrue);
  });

  test('index is reused across searches of the same library', () {
    final index = BookIndex();
    final s = BookDiscoveryService(index: index);
    s.search('witches', library);
    final entries = index.entries;
    s.search('romance', library);
    expect(identical(index.entries, entries), isTrue);
  });
}
