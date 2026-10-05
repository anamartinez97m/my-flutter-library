import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';

bool _equivalent(String a, String b) =>
    TextNormalizer.forms(a).intersection(TextNormalizer.forms(b)).isNotEmpty;

void main() {
  group('normalize', () {
    test('lowercases', () {
      expect(TextNormalizer.normalize('HalLoWeEn'), 'halloween');
    });

    test('folds diacritics', () {
      expect(TextNormalizer.normalize('Brujería'), 'brujeria');
      expect(TextNormalizer.normalize('Otoño Mágico'), 'otono magico');
      expect(TextNormalizer.normalize('Çüéñ'), 'cuen');
    });

    test('turns punctuation and hyphens into spaces', () {
      expect(TextNormalizer.normalize('rom-com!'), 'rom com');
      expect(
        TextNormalizer.normalize('enemies-to-lovers, (again)...'),
        'enemies to lovers again',
      );
    });

    test('removes apostrophes', () {
      expect(TextNormalizer.normalize("Valentine's Day"), 'valentines day');
      expect(TextNormalizer.normalize('Valentine’s'), 'valentines');
    });

    test('collapses whitespace and handles null/empty', () {
      expect(TextNormalizer.normalize('  a   b \n c '), 'a b c');
      expect(TextNormalizer.normalize(null), '');
      expect(TextNormalizer.normalize(''), '');
      expect(TextNormalizer.tokenize(null), isEmpty);
      expect(TextNormalizer.tokenize('  '), isEmpty);
    });
  });

  group('tokenize', () {
    test('splits on word boundaries', () {
      expect(TextNormalizer.tokenize('Dark Academia, secret-society'), [
        'dark',
        'academia',
        'secret',
        'society',
      ]);
    });

    test('word boundaries: war is not warrior, ice is not police', () {
      expect(TextNormalizer.tokenize('The warrior'), isNot(contains('war')));
      expect(TextNormalizer.tokenize('police officer'), isNot(contains('ice')));
    });
  });

  group('segments', () {
    test('splits on sentence punctuation', () {
      expect(TextNormalizer.segments('Dark. Fantasy! Yes; no'), [
        'Dark',
        'Fantasy',
        'Yes',
        'no',
      ]);
      expect(TextNormalizer.segments(null), isEmpty);
    });
  });

  group('forms (singular/plural)', () {
    test('english plurals', () {
      expect(_equivalent('witch', 'witches'), isTrue);
      expect(_equivalent('werewolf', 'werewolves'), isTrue);
      expect(_equivalent('vampire', 'vampires'), isTrue);
      expect(_equivalent('story', 'stories'), isTrue);
      expect(_equivalent('fairy', 'fairies'), isTrue);
      expect(_equivalent('spell', 'spells'), isTrue);
      expect(_equivalent('knife', 'knives'), isTrue);
    });

    test('spanish plurals', () {
      expect(_equivalent('bruja', 'brujas'), isTrue);
      expect(_equivalent('vampiro', 'vampiros'), isTrue);
      expect(_equivalent('ladron', 'ladrones'), isTrue);
      expect(_equivalent('amor', 'amores'), isTrue);
    });

    test('guards short words and double s', () {
      expect(TextNormalizer.forms('gas'), {'gas'});
      expect(TextNormalizer.forms('kiss'), {'kiss'});
      expect(_equivalent('war', 'warrior'), isFalse);
    });
  });
}
