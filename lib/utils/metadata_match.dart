import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';

/// Checks that a search result from a metadata API is the book we asked for,
/// so a cover or description from a different book is never stored.
class MetadataMatch {
  const MetadataMatch._();

  static final RegExp _isbn10 = RegExp(r'^[0-9]{9}[0-9X]$');
  static final RegExp _isbn13 = RegExp(r'^97[89][0-9]{10}$');

  /// ISBN digits (and a final `X`) with hyphens and spaces removed, or null
  /// when [value] isn't an ISBN-10/13. Kindle ASINs such as `B07XYZ1234`
  /// return null; a print-book ASIN equals its ISBN-10 and is accepted.
  static String? cleanIsbn(String? value) {
    if (value == null) return null;
    final clean = value.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (_isbn10.hasMatch(clean) || _isbn13.hasMatch(clean)) return clean;
    return null;
  }

  /// [value] as an ISBN-13 (an ISBN-10 is converted), or null when it isn't
  /// an ISBN, so both forms of the same edition compare equal.
  static String? isbn13(String? value) {
    final clean = cleanIsbn(value);
    if (clean == null || clean.length == 13) return clean;
    final core = '978${clean.substring(0, 9)}';
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(core[i]) * (i.isEven ? 1 : 3);
    }
    return '$core${(10 - sum % 10) % 10}';
  }

  /// Whether [candidateTitle] (plus its [candidateSubtitle]) is the book
  /// titled [expected]. Case, accents and punctuation are ignored; a subtitle,
  /// series note in brackets or text after `:` on either side is tolerated.
  static bool titleMatches(
    String? expected,
    String? candidateTitle, {
    String? candidateSubtitle,
  }) {
    final expectedFull = _tokens(expected);
    final candidateFull = _tokens(
      [candidateTitle, candidateSubtitle].whereType<String>().join(' '),
    );
    if (expectedFull.isEmpty || candidateFull.isEmpty) return false;
    final expectedMain = _tokens(mainTitle(expected));
    final candidateMain = _tokens(mainTitle(candidateTitle));

    if (_sameSet(expectedMain, candidateMain)) return true;
    // A short expected title must not match a longer, different one
    // ("It" is not "It Ends with Us").
    final notMuchShorter = expectedFull.length * 2 >= candidateMain.length;
    if (notMuchShorter && candidateFull.containsAll(expectedFull)) return true;
    if (notMuchShorter &&
        candidateFull.containsAll(expectedMain) &&
        expectedMain.length * 2 >= expectedFull.length) {
      return true;
    }
    return candidateMain.isNotEmpty &&
        expectedFull.containsAll(candidateMain) &&
        candidateMain.length * 2 >= expectedMain.length;
  }

  /// Whether [candidateTitle] is [expected] itself, ignoring subtitles and
  /// series notes, rather than a related title such as a sequel.
  static bool titleIsExact(String? expected, String? candidateTitle) =>
      _sameSet(
        _tokens(mainTitle(expected)),
        _tokens(mainTitle(candidateTitle)),
      );

  /// The [matches] whose whole title is [expected], else those whose main
  /// title is, else all of them ("Dune" is preferred over "Dune Messiah",
  /// and "Dune Messiah" over "Dune" when looking for "Dune: Messiah").
  static List<T> preferExactTitle<T>(
    List<T> matches,
    String? expected,
    String? Function(T match) titleOf,
  ) {
    final whole =
        matches
            .where((m) => _sameSet(_tokens(expected), _tokens(titleOf(m))))
            .toList();
    if (whole.isNotEmpty) return whole;
    final exact =
        matches.where((m) => titleIsExact(expected, titleOf(m))).toList();
    return exact.isEmpty ? matches : exact;
  }

  /// Whether one of [candidateAuthors] shares a name with one of the authors
  /// in [expected] (comma, `;`, `&` or `y`/`and` separated). True when either
  /// side has no author, since the title check then has to decide alone.
  static bool authorMatches(String? expected, List<String>? candidateAuthors) {
    final expectedNames = _authorNames(expected);
    final candidateNames =
        (candidateAuthors ?? const <String>[])
            .map(_nameTokens)
            .where((tokens) => tokens.isNotEmpty)
            .toList();
    if (expectedNames.isEmpty || candidateNames.isEmpty) return true;
    for (final name in expectedNames) {
      for (final candidate in candidateNames) {
        if (name.intersection(candidate).isNotEmpty) return true;
      }
    }
    return false;
  }

  /// Title and author both match.
  static bool isSameBook({
    required String? expectedTitle,
    String? expectedAuthor,
    required String? candidateTitle,
    String? candidateSubtitle,
    List<String>? candidateAuthors,
  }) =>
      titleMatches(
        expectedTitle,
        candidateTitle,
        candidateSubtitle: candidateSubtitle,
      ) &&
      authorMatches(expectedAuthor, candidateAuthors);

  /// [title] without a subtitle (text after `:`, ` - `…) or bracketed note.
  static String? mainTitle(String? title) {
    if (title == null) return null;
    final withoutBrackets = title.replaceAll(RegExp(r'[(\[{].*?[)\]}]'), ' ');
    return withoutBrackets.split(RegExp(r'[:.|]| - | – | — ')).first;
  }

  static Set<String> _tokens(String? text) =>
      TextNormalizer.normalize(
        text,
      ).split(' ').where((token) => token.isNotEmpty).toSet();

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.isNotEmpty && a.length == b.length && a.containsAll(b);

  static List<Set<String>> _authorNames(String? authors) {
    if (authors == null) return const [];
    return authors
        .split(RegExp(r'[,;&]| y | and ', caseSensitive: false))
        .map(_nameTokens)
        .where((tokens) => tokens.isNotEmpty)
        .toList();
  }

  /// Name parts longer than an initial, e.g. `{rowling}` for "J. K. Rowling".
  static Set<String> _nameTokens(String name) =>
      _tokens(name).where((token) => token.length > 2).toSet();
}
