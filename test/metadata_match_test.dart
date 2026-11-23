import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/utils/manual_metadata.dart';
import 'package:myrandomlibrary/utils/metadata_match.dart';

void main() {
  group('MetadataMatch.cleanIsbn', () {
    test('accepts ISBN-10/13 with hyphens and a lowercase x', () {
      expect(MetadataMatch.cleanIsbn('978-84-08-27966-1'), '9788408279661');
      expect(MetadataMatch.cleanIsbn('0-8044-2957-x'), '080442957X');
    });

    test('rejects Kindle ASINs and junk', () {
      expect(MetadataMatch.cleanIsbn('B07XYZ1234'), isNull);
      expect(MetadataMatch.cleanIsbn('B0C1234567'), isNull);
      expect(MetadataMatch.cleanIsbn('12345'), isNull);
      expect(MetadataMatch.cleanIsbn(null), isNull);
    });
  });

  group('MetadataMatch.titleMatches', () {
    test('ignores case, accents, punctuation and subtitles', () {
      expect(
        MetadataMatch.titleMatches('Alas de sangre', 'ALAS DE SANGRE'),
        isTrue,
      );
      expect(
        MetadataMatch.titleMatches(
          'Alas de sangre (Empíreo 1)',
          'Alas de Sangre',
        ),
        isTrue,
      );
      expect(
        MetadataMatch.titleMatches(
          'Fourth Wing',
          'Fourth Wing',
          candidateSubtitle: 'Discover the instant Sunday Times bestseller',
        ),
        isTrue,
      );
      expect(
        MetadataMatch.titleMatches(
          'El nombre del viento',
          'El nombre del viento: Crónica del asesino de reyes 1',
        ),
        isTrue,
      );
    });

    test('rejects different books', () {
      expect(MetadataMatch.titleMatches('It', 'It Ends with Us'), isFalse);
      expect(MetadataMatch.titleMatches('Fourth Wing', 'Iron Flame'), isFalse);
      expect(
        MetadataMatch.titleMatches(
          'Harry Potter 3',
          'Harry Potter and the Chamber of Secrets',
        ),
        isFalse,
      );
    });
  });

  group('MetadataMatch.authorMatches', () {
    test('matches on a shared surname', () {
      expect(
        MetadataMatch.authorMatches('J. K. Rowling', ['J.K. Rowling']),
        isTrue,
      );
      expect(
        MetadataMatch.authorMatches('Ilona Andrews, Gordon Andrews', [
          'Ilona Andrews',
        ]),
        isTrue,
      );
    });

    test('rejects a different author', () {
      expect(
        MetadataMatch.authorMatches('Rebecca Yarros', ['Colleen Hoover']),
        isFalse,
      );
    });

    test('passes when either side has no author', () {
      expect(MetadataMatch.authorMatches(null, ['Colleen Hoover']), isTrue);
      expect(MetadataMatch.authorMatches('Rebecca Yarros', null), isTrue);
    });
  });

  group('resolveMetadataFields', () {
    test('keeps the fetched source when nothing was edited', () {
      final result = resolveMetadataFields(
        coverText: 'https://a/cover.jpg',
        descriptionText: 'Text ',
        fetchedCoverUrl: 'https://a/cover.jpg',
        fetchedDescription: 'Text',
        fetchedSource: 'google_books',
        fetchedAt: '2026-01-01',
      );
      expect(result.source, 'google_books');
      expect(result.fetchedAt, '2026-01-01');
    });

    test('marks edited values as manual', () {
      final result = resolveMetadataFields(
        coverText: 'https://b/cover.jpg',
        descriptionText: 'Text',
        fetchedCoverUrl: 'https://a/cover.jpg',
        fetchedDescription: 'Text',
        fetchedSource: 'google_books',
      );
      expect(result.coverUrl, 'https://b/cover.jpg');
      expect(result.source, manualMetadataSource);
      expect(result.fetchedAt, isNotNull);
    });

    test('clearing both lets them be fetched again', () {
      final result = resolveMetadataFields(
        coverText: ' ',
        descriptionText: '',
        fetchedCoverUrl: 'https://a/cover.jpg',
        fetchedDescription: 'Text',
        fetchedSource: manualMetadataSource,
        fetchedAt: '2026-01-01',
      );
      expect(result.coverUrl, isNull);
      expect(result.description, isNull);
      expect(result.source, isNull);
      expect(result.fetchedAt, isNull);
    });
  });

  group('MetadataMatch.preferExactTitle', () {
    test('prefers the exact title over a sequel', () {
      expect(MetadataMatch.titleMatches('Dune', 'Dune Messiah'), isTrue);
      expect(
        MetadataMatch.preferExactTitle(
          ['Dune Messiah', 'Dune: Deluxe Edition'],
          'Dune',
          (t) => t,
        ),
        ['Dune: Deluxe Edition'],
      );
    });

    test('keeps all matches when none is exact', () {
      expect(
        MetadataMatch.preferExactTitle(['Dune Messiah'], 'Dune', (t) => t),
        ['Dune Messiah'],
      );
    });
  });
}
