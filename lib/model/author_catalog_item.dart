import 'package:myrandomlibrary/model/book_metadata.dart';

/// Lightweight model representing a book in the author catalog view.
/// Merges API data with local library information.
class AuthorCatalogItem {
  final String? title;
  final List<String>? authors;
  final int? publishedYear;
  final String? isbn;
  final BookMetadata metadata;

  // Local library info (null if not in library)
  final bool isInLibrary;
  final int? localBookId;
  final String? localBookStatus;
  final String? localSaga;
  final String? localNSaga;
  final int? localPublicationYear;

  AuthorCatalogItem({
    this.title,
    this.authors,
    this.publishedYear,
    this.isbn,
    required this.metadata,
    this.isInLibrary = false,
    this.localBookId,
    this.localBookStatus,
    this.localSaga,
    this.localNSaga,
    this.localPublicationYear,
  });

  /// Display year: prefer local DB year for owned books, otherwise API year
  int? get displayYear => isInLibrary ? (localPublicationYear ?? publishedYear) : publishedYear;

  /// Whether the book has been read
  bool get isRead => localBookStatus?.toLowerCase() == 'yes';
}
