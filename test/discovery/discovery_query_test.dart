import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/discovery/model/discovery_query.dart';

void main() {
  DiscoveryQuery parse(String q) => DiscoveryQuery.parse(q);

  test('recognises single concepts from keywords and display names', () {
    expect(parse('Halloween').directConceptIds, ['halloween']);
    expect(parse('something spooky').directConceptIds, ['halloween']);
    expect(parse('brujas').directConceptIds, ['witches']);
  });

  test('multi-concept queries keep every direct concept in order', () {
    final q = parse('romance with witches');
    expect(q.directConceptIds, ['romance', 'witches']);
    expect(q.directConceptTerms, {'romance': 'romance', 'witches': 'witches'});
  });

  test('longest phrase wins', () {
    expect(parse('dark academia').directConceptIds, ['dark_academia']);
    expect(parse('dark fantasy with vampires').directConceptIds, [
      'dark_fantasy',
      'vampires',
    ]);
    expect(parse('fantasy romance').directConceptIds, ['fantasy_romance']);
  });

  test('related concepts are one hop and exclude direct/negated ones', () {
    final q = parse('Halloween');
    expect(q.relatedConceptIds, containsAll(['witches', 'ghosts', 'autumn']));
    expect(q.relatedConceptIds, isNot(contains('halloween')));
    expect(q.relatedConceptIds, isNot(contains('fantasy')));
    expect(q.relatedConceptIds, isNot(contains('magic')));
  });

  group('negation', () {
    test('English patterns', () {
      for (final q in [
        'something spooky but not horror',
        'spooky not horror',
        'spooky without horror',
        'spooky, no horror',
      ]) {
        final parsed = parse(q);
        expect(parsed.directConceptIds, ['halloween'], reason: q);
        expect(parsed.negatedConceptIds, {'horror'}, reason: q);
        expect(parsed.relatedConceptIds, isNot(contains('horror')));
      }
    });

    test('Spanish patterns', () {
      for (final q in ['algo de brujas sin terror', 'brujas pero no terror']) {
        final parsed = parse(q);
        expect(parsed.directConceptIds, ['witches'], reason: q);
        expect(parsed.negatedConceptIds, {'horror'}, reason: q);
      }
    });

    test('window closes at a break word', () {
      final q = parse('not horror but with witches');
      expect(q.negatedConceptIds, {'horror'});
      expect(q.directConceptIds, ['witches']);
    });

    test('negated free terms are tracked separately', () {
      final q = parse('witches without zombies');
      expect(q.negatedTerms, ['zombies']);
      expect(q.freeTerms, isEmpty);
    });
  });

  test('residual meaningful words become free terms', () {
    final q = parse('books by Sanderson about witches');
    expect(q.freeTerms, ['sanderson']);
    expect(q.directConceptIds, ['witches']);
    expect(parse('Mistborn').freeTerms, ['mistborn']);
  });

  test('stop words and concept words are not free terms', () {
    final q = parse('I want a cozy book please');
    expect(q.freeTerms, isEmpty);
    expect(q.directConceptIds, ['cozy']);
  });

  test('empty and noise-only queries are empty', () {
    expect(parse('').isEmpty, isTrue);
    expect(parse('   ').isEmpty, isTrue);
    expect(parse('!!!').isEmpty, isTrue);
    expect(parse('a book').isEmpty, isTrue);
    expect(parse('not horror').isEmpty, isTrue);
    expect(parse('witch').isEmpty, isFalse);
  });

  test('normalizes accents and case', () {
    final q = parse('BRUJERÍA y Otoño');
    expect(q.normalized, 'brujeria y otono');
    expect(q.directConceptIds, ['witches', 'autumn']);
  });
}
