import 'package:myrandomlibrary/discovery/catalog/concept_catalog.dart';
import 'package:myrandomlibrary/discovery/index/searchable_book.dart';
import 'package:myrandomlibrary/model/book.dart';

/// Cache of [SearchableBook]s for the current library. Rebuilt only when the
/// list of books changes.
class BookIndex {
  final ConceptCatalog catalog;
  List<Book> _source = const [];
  List<SearchableBook> _entries = const [];

  BookIndex({ConceptCatalog? catalog})
    : catalog = catalog ?? ConceptCatalog.instance;

  List<SearchableBook> get entries => _entries;

  /// Indexes [books], skipping bundle children and placeholders. Returns
  /// whether a rebuild happened.
  bool update(List<Book> books) {
    if (_sameBooks(books)) return false;
    _source = List.unmodifiable(books);
    _entries = List.unmodifiable(
      books
          .where((b) => b.bundleParentId == null && !b.isPlaceholder)
          .map((b) => SearchableBook.from(b, catalog)),
    );
    return true;
  }

  bool _sameBooks(List<Book> books) {
    if (books.length != _source.length) return false;
    for (var i = 0; i < books.length; i++) {
      if (!identical(books[i], _source[i])) return false;
    }
    return true;
  }
}
