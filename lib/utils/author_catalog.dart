import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';
import 'package:myrandomlibrary/model/author_catalog_item.dart';
import 'package:myrandomlibrary/model/book.dart';
import 'package:myrandomlibrary/utils/metadata_match.dart';
import 'package:myrandomlibrary/utils/search_match.dart';

/// Pure logic behind the author "Full catalog": cleaning API results, merging
/// sources, matching them against the library, filtering and grouping.
class AuthorCatalog {
  const AuthorCatalog._();

  /// Key used to recognise the same title across sources and languages.
  static String titleKey(String? title) =>
      _normalized(MetadataMatch.mainTitle(title));

  /// Normalized text; non-Latin text the normalizer would empty is kept
  /// lowercased instead.
  static String _normalized(String? text) {
    final normalized = TextNormalizer.normalize(text);
    if (normalized.isNotEmpty) return normalized;
    return (text ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Whether [a] and [b] are the same title: equal, or equal once one of
  /// them drops its subtitle ("Dune: House Atreides" is not "Dune: House
  /// Harkonnen", but "The Martian: A Novel" is "The Martian").
  static bool sameTitle(String a, String b) {
    final fullA = _normalized(a), fullB = _normalized(b);
    if (fullA.isEmpty || fullB.isEmpty) return false;
    if (fullA == fullB) return true;
    final mainA = titleKey(a), mainB = titleKey(b);
    return mainA == mainB && (mainA == fullA || mainB == fullB);
  }

  static final List<RegExp> _noisePatterns = [
    RegExp(r'\bsumm?ary\b'),
    RegExp(r'\bstudy guide\b'),
    RegExp(r'\bsparknotes\b'),
    RegExp(r'\bcliffs? ?notes\b'),
    RegExp(r'\bbox(ed)? ?set\b'),
    RegExp(r'\b(book|books|gift|collection|collectors) set\b'),
    RegExp(r'\b\d+ (book|books|volume|volumes) (set|collection|bundle)\b'),
    RegExp(r'\bbooks? \d+ ?(\d+|to \d+)\b'),
    RegExp(r'\bbundles?\b'),
    RegExp(r'\bcollection \d+ books?\b'),
    RegExp(r'\w part (one|two|three|four|1|2|3|4)$'),
    RegExp(r'\bconversation starters\b'),
    RegExp(r'\bworkbook\b'),
    RegExp(r'\bcolou?ring book\b'),
    RegExp(r'\bunofficial\b'),
    RegExp(r'\bresumen\b'),
    RegExp(r'\bestuche\b'),
    RegExp(r'\bguia (de )?(estudio|de lectura)\b'),
  ];

  /// Whether [title] looks like a box set, summary, study guide or similar
  /// rather than a book the author wrote.
  static bool isNoise(String? title) {
    if (title == null || title.trim().isEmpty) return true;
    final normalized = TextNormalizer.normalize(title);
    return _noisePatterns.any((p) => p.hasMatch(normalized));
  }

  static String _compact(String name) => _normalized(name).replaceAll(' ', '');

  static Set<String> _nameTokens(String name) =>
      TextNormalizer.normalize(
        name,
      ).split(' ').where((t) => t.length > 1).toSet();

  /// Whether [candidate] is the same person as [author] ("J.K. Rowling" and
  /// "J. K. Rowling" are; "Andrew Weir" and "Andy Weir" are not).
  static bool sameAuthor(String author, String candidate) {
    if (_compact(author).isEmpty) return false;
    if (_compact(author) == _compact(candidate)) return true;
    final a = _nameTokens(author);
    final b = _nameTokens(candidate);
    return a.length >= 2 && a.length == b.length && a.containsAll(b);
  }

  /// Whether a result with [authors] is really a book by [author]: the author
  /// must be listed, and in anthologies (more than three authors) listed first.
  static bool isByAuthor(String author, List<String> authors) {
    final index = authors.indexWhere((a) => sameAuthor(author, a));
    if (index < 0) return false;
    return authors.length <= 3 || index == 0;
  }

  /// Merges [incoming] works into [works]: two works are the same when they
  /// share a title key or an ISBN.
  static List<CatalogWork> merge(
    List<CatalogWork> works,
    Iterable<CatalogWork> incoming,
  ) {
    final result = [...works];
    for (final work in incoming) {
      bool same(CatalogWork w) =>
          w.titles.any((a) => work.titles.any((b) => sameTitle(a, b))) ||
          w.isbns.any(work.isbns.contains);
      final matches = result.where(same).toList();
      if (matches.isEmpty) {
        result.add(work);
        continue;
      }
      result.removeWhere((w) => matches.skip(1).contains(w));
      result[result.indexOf(matches.first)] = matches
          .skip(1)
          .followedBy([work])
          .fold(matches.first, _combine);
    }
    return result;
  }

  static CatalogWork _combine(CatalogWork existing, CatalogWork work) {
    final years = [existing.year, work.year].whereType<int>();
    return CatalogWork(
      key: existing.key,
      title: existing.title,
      titles: {...existing.titles, ...work.titles},
      authors: existing.authors,
      year: years.isEmpty ? null : years.reduce((a, b) => a < b ? a : b),
      isbns: {...existing.isbns, ...work.isbns},
      editionIsbn: existing.editionIsbn ?? work.editionIsbn,
      coverUrl: existing.coverUrl ?? work.coverUrl,
      pages: existing.pages ?? work.pages,
      sources: {...existing.sources, ...work.sources},
    );
  }

  /// Whether the library [book] wrote by [author].
  static bool bookIsByAuthor(Book book, String author) =>
      (book.author ?? '').split(',').any((a) => sameAuthor(author, a.trim()));

  /// Library books that represent a title of [author]: repeated copies,
  /// bundle containers and placeholders are left out.
  static List<Book> libraryBooks(List<Book> books, String author) =>
      books
          .where(
            (b) =>
                b.bookId != null &&
                !b.isPlaceholder &&
                b.isBundle != true &&
                b.statusValue?.toLowerCase() != 'repeated' &&
                bookIsByAuthor(b, author),
          )
          .toList();

  static bool _exactTitle(Book book, CatalogWork work) {
    final name = book.name;
    return name != null && work.titles.any((t) => sameTitle(name, t));
  }

  static bool _fuzzyTitle(Book book, CatalogWork work) {
    final local = titleKey(book.name);
    if (local.isEmpty) return false;
    for (final title in work.titles) {
      if (MetadataMatch.titleMatches(book.name, title)) return true;
      final remote = titleKey(title);
      if (remote.isEmpty) continue;
      // Translations that only add a letter or two ("Artemis" / "Artemisa").
      final shorter = local.length <= remote.length ? local : remote;
      final longer = local.length <= remote.length ? remote : local;
      if (shorter.length >= 5 &&
          longer.startsWith(shorter) &&
          longer.length - shorter.length <= 2 &&
          !longer.substring(shorter.length).contains(' ')) {
        return true;
      }
      // Translations that keep most words ("Project Hail Mary" /
      // "Proyecto Hail Mary").
      final localWords = local.split(' ').where((w) => w.length > 2).toSet();
      final remoteWords = remote.split(' ').where((w) => w.length > 2).toSet();
      if (localWords.length >= 2 && remoteWords.length >= 2) {
        final common = localWords.intersection(remoteWords).length;
        final larger =
            localWords.length > remoteWords.length
                ? localWords.length
                : remoteWords.length;
        if (common >= 2 && common / larger >= 0.5) return true;
      }
    }
    return false;
  }

  /// Ties [works] to the [library] books of the author. Manual links win,
  /// then ISBN, exact title and similar title matches; each library book is
  /// used once. Library books no source lists are added as their own rows.
  static List<AuthorCatalogItem> build({
    required List<CatalogWork> works,
    required List<Book> library,
    required CatalogOverrides overrides,
  }) {
    final byId = {for (final b in library) b.bookId!: b};
    final matched = <String, (Book, CatalogMatch)>{};
    final used = <int>{};

    for (final work in works) {
      final book = byId[overrides.links[work.key]];
      if (book != null && used.add(book.bookId!)) {
        matched[work.key] = (book, CatalogMatch.manual);
      }
    }

    void pass(bool Function(Book book, CatalogWork work) test) {
      for (final work in works) {
        if (matched.containsKey(work.key)) continue;
        for (final book in library) {
          if (used.contains(book.bookId) ||
              overrides.isNotMine(work.key, book.bookId) ||
              !test(book, work)) {
            continue;
          }
          used.add(book.bookId!);
          matched[work.key] = (book, CatalogMatch.automatic);
          break;
        }
      }
    }

    pass((book, work) {
      final isbn = MetadataMatch.isbn13(book.isbn);
      return isbn != null && work.isbns.contains(isbn);
    });
    pass(_exactTitle);
    pass(_fuzzyTitle);

    final items = [
      for (final work in works)
        AuthorCatalogItem(
          key: work.key,
          work: work,
          book: matched[work.key]?.$1,
          match: matched[work.key]?.$2 ?? CatalogMatch.none,
          hidden: overrides.hidden.contains(work.key),
        ),
      for (final book in library)
        if (!used.contains(book.bookId))
          AuthorCatalogItem(
            key: 'local:${book.bookId}',
            book: book,
            match: CatalogMatch.libraryOnly,
            hidden: overrides.hidden.contains('local:${book.bookId}'),
          ),
    ];
    return items;
  }

  /// Items passing [filter] whose title contains [query].
  static List<AuthorCatalogItem> filter(
    List<AuthorCatalogItem> items, {
    required CatalogFilter filter,
    String query = '',
    bool showHidden = false,
  }) {
    final trimmed = query.trim();
    return items.where((item) {
      if (item.hidden && !showHidden) return false;
      if (trimmed.isNotEmpty &&
          !matchesSearch(item.title, trimmed) &&
          !(item.work?.titles.any((t) => matchesSearch(t, trimmed)) ?? false)) {
        return false;
      }
      return switch (filter) {
        CatalogFilter.all => true,
        CatalogFilter.missing => !item.isInLibrary,
        CatalogFilter.owned => item.isInLibrary,
        CatalogFilter.unread => item.isInLibrary && !item.isRead,
      };
    }).toList();
  }

  /// Groups [items]: one section per library saga (in saga order), then the
  /// rest sorted by [sort], with unknown years last when sorting by year.
  static List<CatalogSection> group(
    List<AuthorCatalogItem> items,
    CatalogSort sort,
  ) {
    final sagas = <String, List<AuthorCatalogItem>>{};
    final others = <AuthorCatalogItem>[];
    for (final item in items) {
      final saga = item.saga;
      if (saga == null) {
        others.add(item);
      } else {
        sagas.putIfAbsent(saga, () => []).add(item);
      }
    }

    double sagaNumber(AuthorCatalogItem item) =>
        double.tryParse(item.book?.nSaga?.replaceAll(',', '.') ?? '') ??
        double.infinity;
    int yearOrMax(AuthorCatalogItem item) => item.year ?? 99999;

    final sagaSections = [
      for (final entry in sagas.entries)
        CatalogSection(
          kind: CatalogSectionKind.saga,
          title: entry.key,
          items:
              entry.value..sort((a, b) {
                final n = sagaNumber(a).compareTo(sagaNumber(b));
                return n != 0 ? n : yearOrMax(a).compareTo(yearOrMax(b));
              }),
        ),
    ]..sort((a, b) {
      int first(CatalogSection s) =>
          s.items.map(yearOrMax).reduce((x, y) => x < y ? x : y);
      final byYear = first(a).compareTo(first(b));
      return byYear != 0 ? byYear : a.title!.compareTo(b.title!);
    });

    int byTitle(AuthorCatalogItem a, AuthorCatalogItem b) =>
        TextNormalizer.normalize(
          a.title,
        ).compareTo(TextNormalizer.normalize(b.title));

    final dated =
        sort == CatalogSort.title
            ? others
            : others.where((i) => i.year != null).toList();
    final undated =
        sort == CatalogSort.title
            ? <AuthorCatalogItem>[]
            : others.where((i) => i.year == null).toList();
    dated.sort(switch (sort) {
      CatalogSort.oldest => (a, b) {
        final c = a.year!.compareTo(b.year!);
        return c != 0 ? c : byTitle(a, b);
      },
      CatalogSort.newest => (a, b) {
        final c = b.year!.compareTo(a.year!);
        return c != 0 ? c : byTitle(a, b);
      },
      CatalogSort.title => byTitle,
    });
    undated.sort(byTitle);

    return [
      ...sagaSections,
      if (dated.isNotEmpty)
        CatalogSection(kind: CatalogSectionKind.others, items: dated),
      if (undated.isNotEmpty)
        CatalogSection(kind: CatalogSectionKind.unknownYear, items: undated),
    ];
  }
}

enum CatalogFilter { all, missing, owned, unread }

enum CatalogSort { oldest, newest, title }

enum CatalogSectionKind { saga, others, unknownYear }

class CatalogSection {
  final CatalogSectionKind kind;

  /// Saga name for [CatalogSectionKind.saga].
  final String? title;
  final List<AuthorCatalogItem> items;

  const CatalogSection({required this.kind, this.title, required this.items});
}
