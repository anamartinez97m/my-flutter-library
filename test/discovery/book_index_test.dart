import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/discovery/index/book_index.dart';
import 'package:myrandomlibrary/discovery/index/searchable_text_builder.dart';
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';

import 'discovery_test_utils.dart';

void main() {
  group('SearchableTextBuilder', () {
    test('extracts every field and splits genres', () {
      final book = makeBook(
        name: 'The Witch Hour',
        author: 'Jane Doe',
        genre: 'Fantasy, Romance',
        saga: 'Coven',
        sagaUniverse: 'Moonverse',
        description: 'A tale.',
        notes: 'Loved it',
        myReview: 'Great',
        bundleTitles: '["Part One","Part Two"]',
      );
      final fields = SearchableTextBuilder.fields(book);
      expect(fields[DiscoveryField.title], [
        'The Witch Hour',
        'Part One',
        'Part Two',
      ]);
      expect(fields[DiscoveryField.genre], ['Fantasy', 'Romance']);
      expect(fields[DiscoveryField.saga], ['Coven', 'Moonverse']);
      expect(fields[DiscoveryField.notes], ['Loved it', 'Great']);
    });

    test('falls back to raw bundle titles when not JSON', () {
      final book = makeBook(name: 'Omnibus', bundleTitles: 'Book A, Book B');
      expect(SearchableTextBuilder.fields(book)[DiscoveryField.title], [
        'Omnibus',
        'Book A, Book B',
      ]);
    });

    test('missing metadata yields empty fields and never throws', () {
      final fields = SearchableTextBuilder.fields(makeBook());
      for (final values in fields.values) {
        expect(values, isEmpty);
      }
      expect(SearchableTextBuilder.build(makeBook()), isEmpty);
    });

    test('build produces canonical text for embeddings', () {
      final text = SearchableTextBuilder.build(
        makeBook(
          name: 'Dracula',
          author: 'Bram Stoker',
          genre: 'Horror,Gothic',
          description: 'A vampire.',
        ),
      );
      expect(text, contains('Title: Dracula'));
      expect(text, contains('Author: Bram Stoker'));
      expect(text, contains('Genres: Horror, Gothic'));
      expect(text, contains('Description: A vampire.'));
    });

    test('field weights are ordered strongest first', () {
      final weights = DiscoveryField.values.map((f) => f.weight).toList();
      final sorted = [...weights]..sort((a, b) => b.compareTo(a));
      expect(weights, sorted);
    });
  });

  group('SearchableBook', () {
    test('records concept hits per field', () {
      final entry =
          (BookIndex()..update([
                makeBook(
                  name: 'Coven',
                  genre: 'Fantasy',
                  description: 'A young witch discovers her powers.',
                ),
              ]))
              .entries
              .single;
      expect(
        entry.conceptHits['witches']?[DiscoveryField.description],
        'witch',
      );
      expect(entry.conceptHits['witches']?[DiscoveryField.title], 'coven');
      expect(entry.conceptHits['fantasy']?[DiscoveryField.genre], 'fantasy');
    });

    test('phrases never span sentences', () {
      final entry =
          (BookIndex()..update([
                makeBook(description: 'It was dark. Fantasy was all she had.'),
              ]))
              .entries
              .single;
      expect(entry.conceptHits.containsKey('dark_fantasy'), isFalse);
    });

    test('containsTerm matches whole tokens and plural variants', () {
      final entry =
          (BookIndex()..update([
                makeBook(description: 'Three witches and a warrior.'),
              ]))
              .entries
              .single;
      bool has(String term) => entry.containsTerm(
        DiscoveryField.description,
        TextNormalizer.tokenize(term),
      );
      expect(has('witch'), isTrue);
      expect(has('warrior'), isTrue);
      expect(has('war'), isFalse);
      expect(has('witches and'), isTrue);
      expect(has('witch warrior'), isFalse);
      expect(entry.containsTerm(DiscoveryField.genre, ['witch']), isFalse);
    });

    test('isRead covers yes and repeated only', () {
      final index =
          BookIndex()..update([
            makeBook(status: 'Yes'),
            makeBook(status: 'repeated'),
            makeBook(status: 'started'),
            makeBook(status: null),
          ]);
      expect(index.entries.map((e) => e.isRead), [true, true, false, false]);
    });

    test('negative keywords are recorded separately', () {
      final entry =
          (BookIndex()
                ..update([makeBook(genre: 'Grimdark', description: 'Gore.')]))
              .entries
              .single;
      expect(entry.negativeHits['cozy'], isNotNull);
    });
  });

  group('BookIndex', () {
    test('excludes bundle children and placeholders', () {
      final index =
          BookIndex()..update([
            makeBook(name: 'Main'),
            makeBook(name: 'Child', bundleParentId: 1),
            makeBook(name: 'Placeholder', isPlaceholder: true),
          ]);
      expect(index.entries.map((e) => e.book.name), ['Main']);
    });

    test('rebuilds only when the book list changes', () {
      final books = [makeBook(name: 'A'), makeBook(name: 'B')];
      final index = BookIndex();
      expect(index.update(books), isTrue);
      final first = index.entries;
      expect(index.update(List.of(books)), isFalse);
      expect(identical(index.entries, first), isTrue);
      expect(index.update([books.first, makeBook(name: 'B')]), isTrue);
      expect(index.update([books.first]), isTrue);
    });
  });
}
