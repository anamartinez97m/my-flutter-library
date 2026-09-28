/// A curated theme/mood/topic the discovery engine can recognise in queries
/// and book metadata. Concepts are pure data: the matcher consumes them
/// generically and never references a concept by id.
class ThemeConcept {
  final String id;
  final String displayName;
  final String displayNameEs;
  final String emoji;
  final String category;

  /// Strong direct signals (English).
  final List<String> keywords;

  /// Strong direct signals (Spanish).
  final List<String> keywordsEs;

  /// Alternative names for the concept itself (e.g. `romcom`).
  final List<String> aliases;
  final List<String> relatedConceptIds;

  /// Terms that make a book a poor fit for this concept even when it matches.
  final List<String> negativeKeywords;

  const ThemeConcept({
    required this.id,
    required this.displayName,
    required this.displayNameEs,
    required this.emoji,
    required this.category,
    required this.keywords,
    required this.keywordsEs,
    this.aliases = const [],
    this.relatedConceptIds = const [],
    this.negativeKeywords = const [],
  });

  String localizedName(String languageCode) =>
      languageCode == 'es' ? displayNameEs : displayName;

  /// Every phrase that identifies this concept, in both languages.
  Iterable<String> get allTerms sync* {
    yield displayName;
    yield displayNameEs;
    yield* aliases;
    yield* keywords;
    yield* keywordsEs;
  }
}
