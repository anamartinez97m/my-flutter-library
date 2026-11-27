import 'package:myrandomlibrary/model/book.dart';

/// Catalog sources a [CatalogWork] can come from.
abstract final class CatalogSource {
  static const openLibrary = 'open_library';
  static const googleBooks = 'google_books';
}

/// A book by an author found in an online catalog (Open Library and/or
/// Google Books), merged across sources.
class CatalogWork {
  /// Stable id: the normalized main title of the first title seen.
  final String key;

  /// Title shown in the list (the edition title in the chosen language when
  /// the source returns one).
  final String title;

  /// Every title seen for this work (original + translated editions), used to
  /// match books in the library.
  final Set<String> titles;
  final List<String> authors;
  final int? year;

  /// ISBN-13s of every known edition.
  final Set<String> isbns;

  /// ISBN of the edition [title] belongs to, when known.
  final String? editionIsbn;
  final String? coverUrl;
  final int? pages;
  final Set<String> sources;

  const CatalogWork({
    required this.key,
    required this.title,
    required this.titles,
    required this.authors,
    this.year,
    this.isbns = const {},
    this.editionIsbn,
    this.coverUrl,
    this.pages,
    required this.sources,
  });

  /// An ISBN to prefill when adding this book.
  String? get isbn => editionIsbn;

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'titles': titles.toList(),
    'authors': authors,
    'year': year,
    'isbns': isbns.toList(),
    'editionIsbn': editionIsbn,
    'coverUrl': coverUrl,
    'pages': pages,
    'sources': sources.toList(),
  };

  factory CatalogWork.fromJson(Map<String, dynamic> json) => CatalogWork(
    key: json['key'] as String,
    title: json['title'] as String,
    titles: {...(json['titles'] as List<dynamic>).cast<String>()},
    authors: (json['authors'] as List<dynamic>).cast<String>(),
    year: json['year'] as int?,
    isbns: {...(json['isbns'] as List<dynamic>? ?? const []).cast<String>()},
    editionIsbn: json['editionIsbn'] as String?,
    coverUrl: json['coverUrl'] as String?,
    pages: json['pages'] as int?,
    sources: {...(json['sources'] as List<dynamic>).cast<String>()},
  );
}

/// Corrections the user made to the author catalog: manual links between a
/// catalog work and a library book, rejected automatic matches and hidden
/// results.
class CatalogOverrides {
  /// Catalog work key → library book id.
  final Map<String, int> links;

  /// `'<work key>|<book id>'` pairs that must not be matched automatically.
  final Set<String> notMine;

  /// Item keys hidden from the list.
  final Set<String> hidden;

  CatalogOverrides({
    Map<String, int>? links,
    Set<String>? notMine,
    Set<String>? hidden,
  }) : links = links ?? {},
       notMine = notMine ?? {},
       hidden = hidden ?? {};

  static String pair(String workKey, int bookId) => '$workKey|$bookId';

  bool isNotMine(String workKey, int? bookId) =>
      bookId != null && notMine.contains(pair(workKey, bookId));

  Map<String, dynamic> toJson() => {
    'links': links,
    'notMine': notMine.toList(),
    'hidden': hidden.toList(),
  };

  factory CatalogOverrides.fromJson(Map<String, dynamic> json) =>
      CatalogOverrides(
        links: (json['links'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, v as int),
        ),
        notMine: {
          ...(json['notMine'] as List<dynamic>? ?? const []).cast<String>(),
        },
        hidden: {
          ...(json['hidden'] as List<dynamic>? ?? const []).cast<String>(),
        },
      );
}

/// How a catalog entry was tied to a library book.
enum CatalogMatch { none, manual, automatic, libraryOnly }

/// One row of the author catalog: a catalog work, a library book, or both.
class AuthorCatalogItem {
  /// The work key, or `local:<bookId>` for library books no source lists.
  final String key;
  final CatalogWork? work;
  final Book? book;
  final CatalogMatch match;
  final bool hidden;

  const AuthorCatalogItem({
    required this.key,
    this.work,
    this.book,
    required this.match,
    this.hidden = false,
  });

  bool get isInLibrary => book != null;

  bool get isRead {
    final status = book?.statusValue?.toLowerCase();
    return status == 'yes' || status == 'repeated';
  }

  String get title => book?.name ?? work?.title ?? '';

  int? get year => book?.originalPublicationYear ?? work?.year;

  String? get saga {
    final saga = book?.saga?.trim();
    return saga == null || saga.isEmpty ? null : saga;
  }

  String? get sagaText {
    final n = book?.nSaga?.trim();
    if (saga == null) return null;
    return n == null || n.isEmpty ? saga : '$saga #$n';
  }

  String? get coverUrl {
    final own = book?.coverUrl?.trim();
    return own != null && own.isNotEmpty ? own : work?.coverUrl;
  }
}
