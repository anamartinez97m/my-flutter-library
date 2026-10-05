import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/discovery/catalog/concept_catalog.dart';
import 'package:myrandomlibrary/discovery/catalog/concept_catalog_data.dart';
import 'package:myrandomlibrary/discovery/model/theme_concept.dart';
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';

void main() {
  final catalog = ConceptCatalog.instance;

  Set<String> conceptsIn(String text, {bool longestOnly = true}) =>
      catalog.phrases
          .scan(TextNormalizer.tokenize(text), longestOnly: longestOnly)
          .expand((h) => h.conceptIds)
          .toSet();

  group('catalog integrity', () {
    test('bundled catalog has no integrity problems', () {
      expect(catalog.validate(), isEmpty);
    });

    test('every relatedConceptId resolves to a concept', () {
      final ids = kThemeConcepts.map((c) => c.id).toSet();
      for (final c in kThemeConcepts) {
        for (final r in c.relatedConceptIds) {
          expect(ids, contains(r), reason: '${c.id} → $r');
        }
      }
    });

    test('every concept has EN and ES keywords, names and an emoji', () {
      for (final c in kThemeConcepts) {
        expect(c.keywords, isNotEmpty, reason: c.id);
        expect(c.keywordsEs, isNotEmpty, reason: c.id);
        expect(c.displayName, isNotEmpty, reason: c.id);
        expect(c.displayNameEs, isNotEmpty, reason: c.id);
        expect(c.emoji, isNotEmpty, reason: c.id);
      }
    });

    test('concept ids are unique', () {
      final ids = kThemeConcepts.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('suggestions resolve to concepts', () {
      expect(catalog.suggestions.length, kSuggestedConceptIds.length);
    });

    test('validate reports broken catalogs', () {
      final bad = ConceptCatalog(
        [
          const ThemeConcept(
            id: 'a',
            displayName: 'A',
            displayNameEs: 'A',
            emoji: '🅰️',
            category: 'x',
            keywords: ['alpha'],
            keywordsEs: [],
            relatedConceptIds: ['missing'],
          ),
        ],
        suggestedIds: ['nope'],
      );
      final problems = bad.validate();
      expect(problems.any((p) => p.contains('no ES keywords')), isTrue);
      expect(problems.any((p) => p.contains('unknown concept')), isTrue);
      expect(problems.any((p) => p.contains('Unknown suggestion')), isTrue);
    });
  });

  group('phrase index', () {
    test('matches keywords in both languages', () {
      expect(conceptsIn('witches'), contains('witches'));
      expect(conceptsIn('brujas'), contains('witches'));
      expect(conceptsIn('Brujería'), contains('witches'));
      expect(conceptsIn('navidad'), contains('christmas'));
      expect(conceptsIn('Otoño'), contains('autumn'));
    });

    test('matches display names and aliases', () {
      expect(conceptsIn('Halloween'), contains('halloween'));
      expect(conceptsIn('romcom'), contains('romantic_comedy'));
      expect(conceptsIn('rom-com'), contains('romantic_comedy'));
      expect(conceptsIn('Romantasy'), contains('fantasy_romance'));
    });

    test('longest phrase wins in greedy mode', () {
      expect(conceptsIn('dark academia'), {'dark_academia'});
      expect(conceptsIn('fantasy romance'), {'fantasy_romance'});
      expect(conceptsIn('dark fantasy'), {'dark_fantasy'});
    });

    test('non-greedy mode reports overlapping phrases', () {
      final found = conceptsIn('dark fantasy', longestOnly: false);
      expect(found, containsAll(['dark_fantasy', 'fantasy', 'dark']));
    });

    test('matches on token boundaries only', () {
      expect(conceptsIn('warrior'), isNot(contains('war')));
      expect(conceptsIn('police'), isNot(contains('winter')));
      expect(conceptsIn('witchcraft'), isNot(contains('dark')));
    });

    test('multi-word phrases tolerate plural forms', () {
      expect(conceptsIn('hombres lobo'), contains('werewolves'));
      expect(conceptsIn('dragon riders'), contains('dragons'));
    });

    test('phrases are not matched across gaps', () {
      expect(conceptsIn('dark and fantasy'), isNot(contains('dark_fantasy')));
    });

    test('shared keywords map to every concept that lists them', () {
      expect(conceptsIn('detective'), containsAll(['mystery', 'detective']));
    });

    test('related is one hop and resolves concepts', () {
      final related = catalog.related('halloween').map((c) => c.id).toSet();
      expect(related, containsAll(['witches', 'ghosts', 'autumn']));
      expect(related, isNot(contains('fantasy')));
      expect(catalog.related('unknown'), isEmpty);
    });

    test('negative keywords are indexed separately', () {
      final hits = catalog.negativePhrases.scan(
        TextNormalizer.tokenize('gore'),
      );
      expect(hits.expand((h) => h.conceptIds), contains('cozy'));
      expect(conceptsIn('gore'), isNot(contains('cozy')));
    });
  });

  test('localizedName picks the locale variant', () {
    final witches = catalog.byId('witches')!;
    expect(witches.localizedName('es'), 'Brujas');
    expect(witches.localizedName('en'), 'Witches');
  });
}
