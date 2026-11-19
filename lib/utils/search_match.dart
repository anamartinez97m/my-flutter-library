import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';

/// Whether [option] matches the search [query] typed in an autocomplete field.
///
/// Case, accents, punctuation and spaces are ignored, so `JK`, `j.k.` and
/// `jk rowling` all find `J. K. Rowling`.
bool matchesSearch(String option, String query) {
  if (option.toLowerCase().contains(query.toLowerCase())) return true;
  final compactQuery = _compact(query);
  return compactQuery.isNotEmpty && _compact(option).contains(compactQuery);
}

String _compact(String text) =>
    TextNormalizer.normalize(text).replaceAll(' ', '');
