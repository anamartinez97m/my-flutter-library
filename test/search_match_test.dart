import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/utils/search_match.dart';

void main() {
  test('ignores dots and spaces in initials', () {
    for (final q in ['JK', 'jk', 'J.K.', 'j k', 'jk row', 'Rowling', 'K. R']) {
      expect(matchesSearch('J. K. Rowling', q), isTrue, reason: q);
    }
  });

  test('ignores accents', () {
    expect(matchesSearch('Gabriel García Márquez', 'garcia marquez'), isTrue);
  });

  test('rejects non-matches', () {
    expect(matchesSearch('J. K. Rowling', 'jr'), isFalse);
    expect(matchesSearch('J. K. Rowling', 'tolkien'), isFalse);
  });

  test('keeps punctuation-only queries working', () {
    expect(matchesSearch('Le Guin, Ursula K.', ','), isTrue);
    expect(matchesSearch('Ursula Le Guin', '.'), isFalse);
  });
}
