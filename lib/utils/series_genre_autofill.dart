import 'package:myrandomlibrary/repositories/book_repository.dart';

/// Suggests the genres of the other books in a saga / saga universe when
/// either field is set or changed in the book form.
class SeriesGenreAutofill {
  SeriesGenreAutofill({String? saga, String? universe})
    : _saga = _key(saga),
      _universe = _key(universe);

  String _saga;
  String _universe;

  static String _key(String? value) => (value ?? '').trim().toLowerCase();

  /// Genres to add to [current]; empty when neither field changed since the
  /// last call.
  Future<List<String>> genresToAdd({
    required BookRepository repository,
    required String saga,
    required String universe,
    required List<String> current,
    int? excludeBookId,
  }) async {
    final sagaKey = _key(saga);
    final universeKey = _key(universe);
    final sagaChanged = sagaKey.isNotEmpty && sagaKey != _saga;
    final universeChanged = universeKey.isNotEmpty && universeKey != _universe;
    _saga = sagaKey;
    _universe = universeKey;
    if (!sagaChanged && !universeChanged) return const [];

    final seriesGenres = await repository.getGenresForSeries(
      saga: sagaChanged ? saga : null,
      universe: universeChanged ? universe : null,
      excludeBookId: excludeBookId,
    );
    return missingGenres(current, seriesGenres);
  }

  static List<String> missingGenres(
    List<String> current,
    List<String> incoming,
  ) {
    final seen = current.map((g) => g.trim().toLowerCase()).toSet();
    return [
      for (final genre in incoming)
        if (genre.trim().isNotEmpty && seen.add(genre.trim().toLowerCase()))
          genre.trim(),
    ];
  }
}
