import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/discovery/index/book_index.dart';
import 'package:myrandomlibrary/discovery/index/searchable_text_builder.dart';
import 'package:myrandomlibrary/discovery/matching/book_matcher.dart';
import 'package:myrandomlibrary/discovery/matching/keyword_book_matcher.dart';
import 'package:myrandomlibrary/discovery/model/discovery_query.dart';
import 'package:myrandomlibrary/model/book.dart';

import 'discovery_test_utils.dart';

void main() {
  final matcher = KeywordBookMatcher();

  Map<String?, BookMatch> run(String query, List<Book> books) {
    final index = BookIndex()..update(books);
    return {
      for (final m in matcher.match(DiscoveryQuery.parse(query), index.entries))
        m.entry.book.name: m,
    };
  }

  double rel(Map<String?, BookMatch> r, String name) => r[name]!.relevance;

  test('field strength: title > genre > description > related', () {
    final r = run('witches', [
      makeBook(name: 'The Witches'),
      makeBook(name: 'G', genre: 'Witches'),
      makeBook(name: 'D', description: 'A witch lives here.'),
      makeBook(name: 'R', genre: 'Magic'),
    ]);
    expect(rel(r, 'The Witches'), greaterThan(rel(r, 'G')));
    expect(rel(r, 'G'), greaterThan(rel(r, 'D')));
    expect(rel(r, 'D'), greaterThan(rel(r, 'R')));
  });

  test('a single related hit stays below the main band', () {
    final r = run('Halloween', [makeBook(name: 'Witchy', genre: 'Witches')]);
    expect(rel(r, 'Witchy'), lessThan(0.35));
    expect(r['Witchy']!.coverage, 0);
    expect(r['Witchy']!.matchedConcepts.single.isDirect, isFalse);
  });

  test('related-only matches are capped below any direct match', () {
    final r = run('Halloween', [
      makeBook(
        name: 'Witchy',
        genre: 'Witches, Supernatural, Horror, Occult, Ghosts',
      ),
      makeBook(name: 'Direct', description: 'Set on Halloween night.'),
    ]);
    expect(rel(r, 'Witchy'), KeywordBookMatcher.relatedOnlyCeiling);
    expect(rel(r, 'Direct'), greaterThan(rel(r, 'Witchy')));
    expect(r['Witchy']!.matchedConcepts.every((c) => !c.isDirect), isTrue);
  });

  test('notes/review hit scores below a description hit', () {
    final r = run('witches', [
      makeBook(name: 'D', description: 'About a witch.'),
      makeBook(name: 'N', notes: 'Loved the witch.'),
      makeBook(name: 'V', myReview: 'Great witches.'),
    ]);
    expect(rel(r, 'D'), greaterThan(rel(r, 'N')));
    expect(rel(r, 'D'), greaterThan(rel(r, 'V')));
    expect(r['N']!.reasons.single.field, DiscoveryField.notes);
  });

  test('matches via metadata when the title says nothing', () {
    final r = run('vampires', [
      makeBook(name: 'Interview', genre: 'Gothic', description: 'A vampire.'),
    ]);
    expect(r['Interview']!.reasons.first.field, DiscoveryField.description);
  });

  test('multiple matching concepts are exposed', () {
    final r = run('romance with witches', [
      makeBook(name: 'Both', genre: 'Romance', description: 'A coven.'),
    ]);
    expect(
      r['Both']!.matchedConcepts.map((c) => c.concept.id),
      containsAll(['romance', 'witches']),
    );
  });

  test('case-insensitive and accent-insensitive matching', () {
    final r = run('BRUJERÍA', [
      makeBook(name: 'A', genre: 'brujeria'),
      makeBook(name: 'B', description: 'WITCHCRAFT everywhere.'),
    ]);
    expect(r.keys, containsAll(['A', 'B']));
  });

  test('word boundaries: war does not match warrior', () {
    expect(run('war', [makeBook(name: 'The Warrior Queen')]), isEmpty);
  });

  test('books matching more query concepts rank higher', () {
    final r = run('romance with witches', [
      makeBook(name: 'Both', genre: 'Romance, Witches'),
      makeBook(name: 'OnlyWitch', genre: 'Witches'),
      makeBook(name: 'OnlyRomance', genre: 'Romance'),
    ]);
    expect(rel(r, 'Both'), greaterThan(rel(r, 'OnlyWitch')));
    expect(rel(r, 'Both'), greaterThan(rel(r, 'OnlyRomance')));
    expect(r['Both']!.coverage, 1);
    expect(r['OnlyWitch']!.coverage, 0.5);
  });

  test('repeated hits in one field do not dominate', () {
    final r = run('witches', [
      makeBook(name: 'T', genre: 'Witches'),
      makeBook(name: 'Spam', description: 'witch witch witch witch witch.'),
    ]);
    expect(rel(r, 'T'), greaterThan(rel(r, 'Spam')));
  });

  test('negated concept in genre or title excludes the book', () {
    final r = run('something spooky but not horror', [
      makeBook(name: 'Spooky Horror', genre: 'Horror', description: 'Spooky.'),
      makeBook(name: 'Cozy Spooky', genre: 'Spooky, Cozy'),
    ]);
    expect(r.containsKey('Spooky Horror'), isFalse);
    expect(r.containsKey('Cozy Spooky'), isTrue);
  });

  test('negated concept in description is penalised', () {
    final r = run('spooky not horror', [
      makeBook(name: 'A', genre: 'Spooky', description: 'Pure horror.'),
      makeBook(name: 'B', genre: 'Spooky'),
    ]);
    expect(rel(r, 'A'), lessThan(rel(r, 'B') * 0.5));
  });

  test('negated free terms exclude or penalise', () {
    final r = run('witches without zombies', [
      makeBook(name: 'Z', genre: 'Witches, Zombies'),
      makeBook(name: 'W', genre: 'Witches'),
    ]);
    expect(r.containsKey('Z'), isFalse);
    expect(r.containsKey('W'), isTrue);
  });

  test('catalog negative keywords penalise the concept', () {
    final r = run('cozy', [
      makeBook(name: 'Messy', genre: 'Cozy', description: 'So much gore.'),
      makeBook(name: 'Nice', genre: 'Cozy'),
      makeBook(name: 'Grim', genre: 'Cozy, Grimdark'),
    ]);
    expect(rel(r, 'Messy'), lessThan(rel(r, 'Nice')));
    expect(r.containsKey('Grim'), isFalse);
  });

  test('free terms match literal text such as author and saga', () {
    final r = run('Sanderson', [
      makeBook(name: 'Mistborn', author: 'Brandon Sanderson'),
      makeBook(name: 'Other', author: 'Someone Else'),
    ]);
    expect(r.keys, ['Mistborn']);
    expect(r['Mistborn']!.reasons.single.field, DiscoveryField.author);

    final saga = run('stormlight', [
      makeBook(name: 'Book', saga: 'The Stormlight Archive'),
    ]);
    expect(saga['Book']!.reasons.single.field, DiscoveryField.saga);
  });

  test('missing metadata never crashes and never matches', () {
    expect(run('witches', [makeBook(), makeBook(name: '')]), isEmpty);
  });

  test('reasons and concepts are ordered by contribution', () {
    final r = run('Halloween', [
      makeBook(
        name: 'Night',
        genre: 'Halloween',
        description: 'A coven of witches.',
      ),
    ]);
    final m = r['Night']!;
    expect(m.matchedConcepts.first.concept.id, 'halloween');
    expect(m.matchedConcepts.first.isDirect, isTrue);
    expect(m.reasons.first.field, DiscoveryField.genre);
    expect(
      m.reasons.any((x) => x.conceptId == 'witches' && x.isRelated),
      isTrue,
    );
  });

  test('relevance is always within 0..1', () {
    final r = run('witches', [
      makeBook(
        name: 'Witches',
        genre: 'Witches, Magic, Occult, Supernatural',
        description: 'Witch coven magic spells.',
        notes: 'witches',
      ),
    ]);
    expect(rel(r, 'Witches'), inInclusiveRange(0, 1));
  });

  test('empty query yields no matches', () {
    expect(run('', [makeBook(name: 'Witches')]), isEmpty);
  });
}
