/// Normalizes free text so queries, book metadata and catalog keywords can be
/// compared on equal terms: lowercase, diacritics folded, punctuation removed,
/// tokens split on word boundaries and plural variants expanded.
class TextNormalizer {
  const TextNormalizer._();

  static const Map<String, String> _diacritics = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'æ': 'ae',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ø': 'o',
    'œ': 'oe',
    'ß': 'ss',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
  };

  static final RegExp _apostrophes = RegExp('[\'’‘`´]');
  static final RegExp _nonAlphanumeric = RegExp(r'[^a-z0-9]+');
  static final RegExp _sentenceBreak = RegExp(r'[.!?;:\n\r•|/()\[\]{}"“”«»]+');

  /// Lowercases, folds diacritics, drops apostrophes and turns every other
  /// non-alphanumeric character (including hyphens) into a single space.
  static String normalize(String? input) {
    if (input == null || input.isEmpty) return '';
    final lower = input.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_diacritics[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(_apostrophes, '')
        .replaceAll(_nonAlphanumeric, ' ')
        .trim();
  }

  /// Normalized tokens of [input], in order.
  static List<String> tokenize(String? input) {
    final normalized = normalize(input);
    if (normalized.isEmpty) return const [];
    return normalized.split(' ');
  }

  /// Splits [input] into sentence-like segments so phrases are never matched
  /// across a sentence or list boundary.
  static List<String> segments(String? input) {
    if (input == null || input.isEmpty) return const [];
    return input
        .split(_sentenceBreak)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Surface form plus singular candidates for an already-normalized token.
  ///
  /// Two tokens are considered equivalent when their form sets intersect, so
  /// `witch`/`witches`, `werewolf`/`werewolves`, `story`/`stories`,
  /// `bruja`/`brujas` and `ladron`/`ladrones` all match each other.
  static Set<String> forms(String token) {
    final result = <String>{token};
    final length = token.length;
    if (length <= 3) return result;
    if (token.endsWith('ss')) return result;
    if (token.endsWith('s')) {
      result.add(token.substring(0, length - 1));
    }
    if (length > 4 && token.endsWith('es')) {
      result.add(token.substring(0, length - 2));
    }
    if (length > 4 && token.endsWith('ies')) {
      result.add('${token.substring(0, length - 3)}y');
    }
    if (length > 4 && token.endsWith('ves')) {
      final stem = token.substring(0, length - 3);
      result.add('${stem}f');
      result.add('${stem}fe');
    }
    return result;
  }
}
