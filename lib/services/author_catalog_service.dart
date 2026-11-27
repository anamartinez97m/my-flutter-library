import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:myrandomlibrary/discovery/text/text_normalizer.dart';
import 'package:myrandomlibrary/model/author_catalog_item.dart';
import 'package:myrandomlibrary/services/google_books_service.dart';
import 'package:myrandomlibrary/services/open_library_service.dart';
import 'package:myrandomlibrary/utils/author_catalog.dart';
import 'package:myrandomlibrary/utils/metadata_match.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of loading an author's catalog.
class AuthorCatalogResult {
  final List<CatalogWork> works;

  /// Sources that answered. A missing one failed or timed out.
  final Set<String> sources;
  final DateTime fetchedAt;
  final bool fromCache;

  const AuthorCatalogResult({
    required this.works,
    required this.sources,
    required this.fetchedAt,
    this.fromCache = false,
  });
}

/// Loads every book an author has published from Open Library and Google
/// Books, merged and cleaned, with a per-author cache and user corrections.
class AuthorCatalogService {
  static const _cachePrefix = 'author_catalog_cache_v1|';
  static const _overridesPrefix = 'author_catalog_overrides_v1|';
  static const _languagePrefix = 'author_catalog_language_v1|';
  static const cacheLifetime = Duration(days: 7);

  static const _openLibraryPageSize = 100;
  static const _openLibraryMaxPages = 5;
  static const _googlePageSize = 40;
  static const _googleMaxPages = 5;

  final http.Client _client;

  AuthorCatalogService({http.Client? client})
    : _client = client ?? http.Client();

  static String _authorKey(String author) => TextNormalizer.normalize(author);

  /// The catalog of [author] in [language] (a language name such as
  /// "Spanish"; null for any language), from the cache when it is fresh.
  Future<AuthorCatalogResult> load(
    String author, {
    String? language,
    bool refresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey =
        '$_cachePrefix${_authorKey(author)}|${language?.toLowerCase() ?? ''}';
    if (!refresh) {
      final cached = _readCache(prefs.getString(cacheKey));
      if (cached != null &&
          DateTime.now().difference(cached.fetchedAt) < cacheLifetime) {
        return cached;
      }
    }

    final results = await Future.wait([
      _openLibrary(author, language),
      _googleBooks(author, language),
    ]);
    final sources = <String>{};
    var works = <CatalogWork>[];
    for (final (source, sourceWorks) in [
      (CatalogSource.openLibrary, results[0]),
      (CatalogSource.googleBooks, results[1]),
    ]) {
      if (sourceWorks == null) continue;
      sources.add(source);
      works = AuthorCatalog.merge(works, sourceWorks);
    }

    final result = AuthorCatalogResult(
      works: works,
      sources: sources,
      fetchedAt: DateTime.now(),
    );
    if (sources.length == 2) {
      await prefs.setString(
        cacheKey,
        jsonEncode({
          'fetchedAt': result.fetchedAt.toIso8601String(),
          'sources': sources.toList(),
          'works': works.map((w) => w.toJson()).toList(),
        }),
      );
    }
    return result;
  }

  AuthorCatalogResult? _readCache(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AuthorCatalogResult(
        works:
            (json['works'] as List<dynamic>)
                .map((w) => CatalogWork.fromJson(w as Map<String, dynamic>))
                .toList(),
        sources: {...(json['sources'] as List<dynamic>).cast<String>()},
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        fromCache: true,
      );
    } catch (e) {
      debugPrint('[AuthorCatalog] Ignoring unreadable cache: $e');
      return null;
    }
  }

  Future<http.Response?> _get(Uri url) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _client
            .get(url)
            .timeout(Duration(seconds: 20 + attempt * 10));
        if (response.statusCode == 200) return response;
        debugPrint('[AuthorCatalog] ${url.host} → ${response.statusCode}');
        if (response.statusCode != 429 && response.statusCode < 500) {
          return null;
        }
      } catch (e) {
        debugPrint('[AuthorCatalog] ${url.host} failed: $e');
      }
      await Future.delayed(Duration(seconds: 1 + attempt));
    }
    return null;
  }

  bool _keep(String author, String? title, List<String> authors) =>
      title != null &&
      title.trim().isNotEmpty &&
      !AuthorCatalog.isNoise(title) &&
      AuthorCatalog.isByAuthor(author, authors);

  Set<String> _isbns(Iterable<dynamic>? values) => {
    for (final value in values ?? const [])
      if (MetadataMatch.isbn13(value.toString()) != null)
        MetadataMatch.isbn13(value.toString())!,
  };

  /// Works by [author] on Open Library, or null when it can't be reached.
  Future<List<CatalogWork>?> _openLibrary(
    String author,
    String? language,
  ) async {
    final langCode =
        language == null ? null : OpenLibraryService.languageCode(language);
    final works = <CatalogWork>[];
    for (var page = 0; page < _openLibraryMaxPages; page++) {
      final url = Uri.https('openlibrary.org', '/search.json', {
        'author': author.trim(),
        'offset': '${page * _openLibraryPageSize}',
        'limit': '$_openLibraryPageSize',
        'fields':
            'key,title,author_name,first_publish_year,cover_i,isbn,'
            'number_of_pages_median,editions,editions.title,editions.isbn,'
            'editions.cover_i',
        if (langCode != null) 'language': langCode,
      });
      final response = await _get(url);
      if (response == null) return page == 0 ? null : works;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = (data['docs'] as List<dynamic>? ?? const []);
      for (final doc in docs.cast<Map<String, dynamic>>()) {
        final title = doc['title'] as String?;
        final authors =
            (doc['author_name'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList();
        final edition =
            ((doc['editions'] as Map<String, dynamic>?)?['docs']
                    as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .firstOrNull;
        final editionTitle = langCode == null ? null : edition?['title'];
        final shownTitle =
            editionTitle is String && editionTitle.trim().isNotEmpty
                ? editionTitle
                : title;
        if (!_keep(author, title, authors) ||
            AuthorCatalog.isNoise(shownTitle)) {
          continue;
        }
        final coverId =
            (langCode == null ? null : edition?['cover_i']) ?? doc['cover_i'];
        works.add(
          CatalogWork(
            key: AuthorCatalog.titleKey(shownTitle),
            title: shownTitle!,
            titles: {title!, shownTitle},
            authors: authors,
            year: doc['first_publish_year'] as int?,
            isbns: {
              ..._isbns(edition?['isbn'] as List<dynamic>?),
              ..._isbns(doc['isbn'] as List<dynamic>?),
            },
            coverUrl:
                coverId is int
                    ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg'
                    : null,
            pages: doc['number_of_pages_median'] as int?,
            sources: {CatalogSource.openLibrary},
          ),
        );
      }
      final total = data['numFound'] as int? ?? 0;
      if (docs.length < _openLibraryPageSize ||
          (page + 1) * _openLibraryPageSize >= total) {
        break;
      }
    }
    return AuthorCatalog.merge([], works);
  }

  /// Books by [author] on Google Books, or null when it can't be reached.
  Future<List<CatalogWork>?> _googleBooks(
    String author,
    String? language,
  ) async {
    final langCode =
        language == null ? null : GoogleBooksService.languageCode(language);
    const apiKey = GoogleBooksService.googleBooksApiKey;
    final works = <CatalogWork>[];
    for (var page = 0; page < _googleMaxPages; page++) {
      final url = Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': 'inauthor:"${author.trim()}"',
        'startIndex': '${page * _googlePageSize}',
        'maxResults': '$_googlePageSize',
        'printType': 'books',
        if (langCode != null) 'langRestrict': langCode,
        if (apiKey.isNotEmpty) 'key': apiKey,
      });
      final response = await _get(url);
      if (response == null) return page == 0 ? null : works;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['items'] as List<dynamic>? ?? const []);
      for (final item in items.cast<Map<String, dynamic>>()) {
        final info = item['volumeInfo'] as Map<String, dynamic>? ?? const {};
        final title = info['title'] as String?;
        final authors =
            (info['authors'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toList();
        if (!_keep(author, title, authors)) continue;
        final date = info['publishedDate'] as String?;
        final images = info['imageLinks'] as Map<String, dynamic>?;
        final thumbnail = images?['thumbnail'] as String?;
        works.add(
          CatalogWork(
            key: AuthorCatalog.titleKey(title),
            title: title!,
            titles: {title},
            authors: authors,
            year:
                date != null && date.length >= 4
                    ? int.tryParse(date.substring(0, 4))
                    : null,
            isbns: _isbns(
              (info['industryIdentifiers'] as List<dynamic>? ?? const []).map(
                (id) => id is Map ? id['identifier'] : null,
              ),
            ),
            coverUrl: thumbnail?.replaceFirst('http://', 'https://'),
            pages: info['pageCount'] as int?,
            sources: {CatalogSource.googleBooks},
          ),
        );
      }
      if (items.length < _googlePageSize) break;
    }
    return AuthorCatalog.merge([], works);
  }

  Future<CatalogOverrides> loadOverrides(String author) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_overridesPrefix${_authorKey(author)}');
    if (raw == null) return CatalogOverrides();
    try {
      return CatalogOverrides.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return CatalogOverrides();
    }
  }

  Future<void> saveOverrides(String author, CatalogOverrides overrides) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_overridesPrefix${_authorKey(author)}',
      jsonEncode(overrides.toJson()),
    );
  }

  /// The language picked for [author]: null when never picked, `''` for any.
  Future<String?> savedLanguage(String author) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_languagePrefix${_authorKey(author)}');
  }

  Future<void> saveLanguage(String author, String? language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_languagePrefix${_authorKey(author)}',
      language ?? '',
    );
  }
}
