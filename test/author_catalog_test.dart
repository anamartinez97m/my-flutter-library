import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrandomlibrary/model/author_catalog_item.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/services/author_catalog_service.dart';
import 'package:myrandomlibrary/utils/author_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Book _book(
  int id,
  String name, {
  String author = 'Andy Weir',
  String status = 'No',
  String? isbn,
  String? saga,
  String? nSaga,
  int? year,
  bool? isBundle,
}) => Book(
  bookId: id,
  name: name,
  saga: saga,
  nSaga: nSaga,
  formatSagaValue: null,
  isbn: isbn,
  asin: null,
  pages: null,
  originalPublicationYear: year,
  loaned: null,
  statusValue: status,
  editorialValue: null,
  languageValue: null,
  placeValue: null,
  formatValue: null,
  createdAt: null,
  author: author,
  isBundle: isBundle,
);

CatalogWork _work(
  String title, {
  int? year,
  Set<String> isbns = const {},
  String source = CatalogSource.openLibrary,
  Set<String>? titles,
}) => CatalogWork(
  key: AuthorCatalog.titleKey(title),
  title: title,
  titles: titles ?? {title},
  authors: const ['Andy Weir'],
  year: year,
  isbns: isbns,
  sources: {source},
);

void main() {
  group('noise and authors', () {
    test('box sets, summaries and split parts are noise', () {
      for (final title in [
        'Summary of Project Hail Mary',
        'The Martian: Study Guide',
        'Mistborn Boxed Set',
        'Stormlight Archive Series Collection 4 Books Bundles Set',
        'Words of Radiance, Part Two',
        'Resumen de El marciano',
      ]) {
        expect(AuthorCatalog.isNoise(title), isTrue, reason: title);
      }
      for (final title in [
        'The Martian',
        'Artemis',
        'Mistborn: The Final Empire',
      ]) {
        expect(AuthorCatalog.isNoise(title), isFalse, reason: title);
      }
    });

    test('author must be listed, and first in anthologies', () {
      expect(
        AuthorCatalog.isByAuthor('J. K. Rowling', ['J.K. Rowling']),
        isTrue,
      );
      expect(AuthorCatalog.isByAuthor('Andy Weir', ['Andrew Weir']), isFalse);
      expect(
        AuthorCatalog.isByAuthor('Andy Weir', ['A', 'B', 'C', 'Andy Weir']),
        isFalse,
      );
      expect(
        AuthorCatalog.isByAuthor('Andy Weir', ['Andy Weir', 'A', 'B', 'C']),
        isTrue,
      );
    });
  });

  test('non-Latin names, series subtitles and ordinary words', () {
    expect(AuthorCatalog.sameAuthor('村上春樹', '村上春樹'), isTrue);
    expect(AuthorCatalog.isNoise('ノルウェイの森'), isFalse);
    expect(AuthorCatalog.isNoise('Wolf Pack'), isFalse);
    expect(
      AuthorCatalog.sameTitle('Dune: House Atreides', 'Dune: House Harkonnen'),
      isFalse,
    );
    expect(
      AuthorCatalog.sameTitle('The Martian: A Novel', 'The Martian'),
      isTrue,
    );
  });

  test('merge collapses every row an incoming work matches', () {
    final merged = AuthorCatalog.merge(
      [
        _work('The Martian', year: 2011),
        _work('Marciano', isbns: {'9788490705780'}),
      ],
      [
        _work(
          'The Martian',
          isbns: {'9788490705780'},
          source: CatalogSource.googleBooks,
        ),
      ],
    );
    expect(merged.single.titles, containsAll(['The Martian', 'Marciano']));
  });

  test('merge joins works sharing a title or an ISBN', () {
    final merged = AuthorCatalog.merge(
      [
        _work('The Martian', year: 2011, isbns: {'9788490705780'}),
      ],
      [
        _work(
          'Marciano',
          year: 2014,
          isbns: {'9788490705780'},
          source: CatalogSource.googleBooks,
        ),
        _work(
          'The Martian: A Novel',
          year: 2014,
          source: CatalogSource.googleBooks,
        ),
        _work('Randomize', year: 2023, source: CatalogSource.googleBooks),
      ],
    );
    expect(merged, hasLength(2));
    expect(merged.first.year, 2011);
    expect(merged.first.sources, {
      CatalogSource.openLibrary,
      CatalogSource.googleBooks,
    });
    expect(merged.first.titles, containsAll(['The Martian', 'Marciano']));
  });

  group('build', () {
    final works = [
      _work('The Martian', year: 2011, isbns: {'9788490705780'}),
      _work('Project Hail Mary', year: 2021),
      _work('Artemis', year: 2017),
      _work('Randomize', year: 2023),
    ];

    test('matches by ISBN, title and translation; each book used once', () {
      final library = [
        _book(1, 'El marciano', isbn: '849070578X', status: 'Yes'),
        _book(2, 'Proyecto Hail Mary'),
        _book(3, 'Artemisa'),
        _book(4, 'Artemisa', status: 'Repeated'),
        _book(5, 'The Egg'),
      ];
      final items = AuthorCatalog.build(
        works: works,
        library: AuthorCatalog.libraryBooks(library, 'Andy Weir'),
        overrides: CatalogOverrides(),
      );
      String? owner(String key) =>
          items.firstWhere((i) => i.key == key).book?.name;
      expect(owner(AuthorCatalog.titleKey('The Martian')), 'El marciano');
      expect(
        owner(AuthorCatalog.titleKey('Project Hail Mary')),
        'Proyecto Hail Mary',
      );
      expect(owner(AuthorCatalog.titleKey('Artemis')), 'Artemisa');
      expect(owner(AuthorCatalog.titleKey('Randomize')), isNull);
      expect(
        items
            .where((i) => i.match == CatalogMatch.libraryOnly)
            .map((i) => i.title),
        ['The Egg'],
      );
      expect(items.firstWhere((i) => i.title == 'El marciano').isRead, isTrue);
    });

    test('manual links and "not my copy" override automatic matches', () {
      final library = [_book(3, 'Artemisa'), _book(6, 'Aleatorio')];
      final artemis = AuthorCatalog.titleKey('Artemis');
      final randomize = AuthorCatalog.titleKey('Randomize');
      final items = AuthorCatalog.build(
        works: works,
        library: library,
        overrides: CatalogOverrides(
          links: {randomize: 6},
          notMine: {CatalogOverrides.pair(artemis, 3)},
          hidden: {AuthorCatalog.titleKey('The Martian')},
        ),
      );
      final byKey = {for (final i in items) i.key: i};
      expect(byKey[randomize]!.match, CatalogMatch.manual);
      expect(byKey[artemis]!.book, isNull);
      expect(byKey['local:3'], isNotNull);
      expect(byKey[AuthorCatalog.titleKey('The Martian')]!.hidden, isTrue);
    });
  });

  test('filter and group', () {
    final items = AuthorCatalog.build(
      works: [
        _work('The Final Empire', year: 2006),
        _work('The Well of Ascension', year: 2007),
        _work('Elantris', year: 2005),
        _work('Warbreaker', year: 2009),
        _work('White Sand'),
      ],
      library: [
        _book(
          1,
          'The Well of Ascension',
          saga: 'Mistborn',
          nSaga: '2',
          status: 'Yes',
          author: 'Andy Weir',
        ),
        _book(2, 'The Final Empire', saga: 'Mistborn', nSaga: '1'),
        _book(3, 'Elantris'),
      ],
      overrides: CatalogOverrides(),
    );
    expect(
      AuthorCatalog.filter(
        items,
        filter: CatalogFilter.missing,
      ).map((i) => i.title),
      ['Warbreaker', 'White Sand'],
    );
    expect(AuthorCatalog.filter(items, filter: CatalogFilter.unread).length, 2);
    expect(
      AuthorCatalog.filter(
        items,
        filter: CatalogFilter.all,
        query: 'elan',
      ).single.title,
      'Elantris',
    );

    final sections = AuthorCatalog.group(items, CatalogSort.oldest);
    expect(sections.map((s) => s.kind), [
      CatalogSectionKind.saga,
      CatalogSectionKind.others,
      CatalogSectionKind.unknownYear,
    ]);
    expect(sections[0].items.map((i) => i.title), [
      'The Final Empire',
      'The Well of Ascension',
    ]);
    expect(sections[1].items.map((i) => i.title), ['Elantris', 'Warbreaker']);
    expect(sections[2].items.single.title, 'White Sand');
  });

  test('service merges Open Library and Google Books and caches', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (request.url.host == 'openlibrary.org') {
        return http.Response(
          jsonEncode({
            'numFound': 2,
            'docs': [
              {
                'key': '/works/1',
                'title': 'The Martian',
                'author_name': ['Andy Weir'],
                'first_publish_year': 2011,
                'isbn': ['9780553418026'],
                'cover_i': 7,
              },
              {
                'key': '/works/2',
                'title': 'Summary of The Martian',
                'author_name': ['Andy Weir'],
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'items': [
            {
              'volumeInfo': {
                'title': 'The Martian',
                'authors': ['Andy Weir'],
                'publishedDate': '2014-02-11',
                'industryIdentifiers': [
                  {'type': 'ISBN_13', 'identifier': '9780553418026'},
                ],
              },
            },
            {
              'volumeInfo': {
                'title': 'Randomize',
                'authors': ['Andy Weir'],
                'publishedDate': '2023',
                'imageLinks': {'thumbnail': 'http://books.google.com/x'},
              },
            },
            {
              'volumeInfo': {
                'title': 'Fan Guide',
                'authors': ['Someone Else'],
              },
            },
          ],
        }),
        200,
      );
    });
    final service = AuthorCatalogService(client: client);
    final result = await service.load('Andy Weir');
    expect(result.sources, {
      CatalogSource.openLibrary,
      CatalogSource.googleBooks,
    });
    expect(result.works.map((w) => w.title), ['The Martian', 'Randomize']);
    expect(result.works.first.year, 2011);
    expect(result.works.last.coverUrl, 'https://books.google.com/x');
    expect(result.works.last.key, 'gb:randomize');

    final callsBefore = calls;
    final cached = await service.load('Andy Weir');
    expect(cached.fromCache, isTrue);
    expect(cached.works, hasLength(2));
    expect(calls, callsBefore);
  });
}
