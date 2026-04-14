import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/book_metadata.dart';

/// Service for fetching book metadata from Google Books API
/// API Documentation: https://developers.google.com/books/docs/v1/using
class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const Duration _timeout = Duration(seconds: 10);

  // Rate limiting: Google Books allows ~1000 requests/day for free tier
  // We implement basic throttling to avoid hitting limits
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 100);

  /// Fetch book metadata by ISBN
  /// Preferred method as ISBN provides most accurate results
  /// [language] - Optional language code to filter results (e.g., 'en', 'es')
  Future<BookMetadata?> fetchByIsbn(String isbn, {String? language}) async {
    try {
      await _throttleRequest();

      // Clean ISBN (remove hyphens, spaces)
      final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9X]'), '');

      if (cleanIsbn.isEmpty) {
        debugPrint('[GoogleBooks] Invalid ISBN: $isbn');
        return null;
      }

      // Build URL with optional language restriction
      String urlString = '$_baseUrl?q=isbn:$cleanIsbn';
      if (language != null && language.isNotEmpty) {
        final langCode = _mapLanguageCode(language);
        if (langCode != null) {
          urlString += '&langRestrict=$langCode';
          debugPrint('[GoogleBooks] Using language restriction: $langCode');
        }
      }
      final url = Uri.parse(urlString);
      debugPrint('[GoogleBooks] Fetching by ISBN: $cleanIsbn');

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          final bookData = items[0] as Map<String, dynamic>;
          final metadata = _parseGoogleBooksResponse(bookData);
          debugPrint(
            '[GoogleBooks] Successfully fetched by ISBN: ${metadata.title}',
          );
          return metadata;
        } else {
          debugPrint('[GoogleBooks] No results found for ISBN: $cleanIsbn');
        }
      } else {
        debugPrint('[GoogleBooks] API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[GoogleBooks] Error fetching by ISBN: $e');
    }

    return null;
  }

  /// Fetch book metadata by title and author
  /// Fallback method when ISBN is not available
  /// [language] - Optional language code to filter results (e.g., 'en', 'es')
  Future<BookMetadata?> fetchByTitleAndAuthor(
    String title, {
    String? author,
    String? language,
  }) async {
    try {
      await _throttleRequest();

      if (title.trim().isEmpty) {
        debugPrint('[GoogleBooks] Invalid title');
        return null;
      }

      // Build query string
      String query = 'intitle:${_sanitizeQuery(title)}';
      if (author != null && author.trim().isNotEmpty) {
        query += '+inauthor:${_sanitizeQuery(author)}';
      }

      // Build URL with optional language restriction
      String urlString = '$_baseUrl?q=$query&maxResults=1';
      if (language != null && language.isNotEmpty) {
        final langCode = _mapLanguageCode(language);
        if (langCode != null) {
          urlString += '&langRestrict=$langCode';
          debugPrint('[GoogleBooks] Using language restriction: $langCode');
        }
      }
      final url = Uri.parse(urlString);
      debugPrint('[GoogleBooks] Fetching by title/author: $query');

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          final bookData = items[0] as Map<String, dynamic>;
          final metadata = _parseGoogleBooksResponse(bookData);
          debugPrint(
            '[GoogleBooks] Successfully fetched by title/author: ${metadata.title}',
          );
          return metadata;
        } else {
          debugPrint('[GoogleBooks] No results found for: $query');
        }
      } else {
        debugPrint('[GoogleBooks] API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[GoogleBooks] Error fetching by title/author: $e');
    }

    return null;
  }

  /// Fetch all books by an author with pagination
  /// Returns a record with the list of BookMetadata and totalItems from the API
  Future<({List<BookMetadata> books, int totalItems})> fetchByAuthor(
    String author, {
    int startIndex = 0,
    String? language,
  }) async {
    try {
      await _throttleRequest();

      if (author.trim().isEmpty) {
        debugPrint('[GoogleBooks] Invalid author name');
        return (books: <BookMetadata>[], totalItems: 0);
      }

      final query = 'inauthor:${_sanitizeQuery(author)}';
      String urlString =
          '$_baseUrl?q=$query&maxResults=40&startIndex=$startIndex&printType=books&orderBy=relevance';
      if (language != null && language.isNotEmpty) {
        final langCode = _mapLanguageCode(language);
        if (langCode != null) {
          urlString += '&langRestrict=$langCode';
          debugPrint(
            '[GoogleBooks] Using language restriction: $langCode (from "$language")',
          );
        } else {
          debugPrint(
            '[GoogleBooks] WARNING: Could not map language "$language" to API code, no langRestrict applied',
          );
        }
      }
      final url = Uri.parse(urlString);
      debugPrint('[GoogleBooks] Full URL: $urlString');
      debugPrint(
        '[GoogleBooks] Fetching books by author: $author (startIndex: $startIndex, language: $language)',
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final totalItems = data['totalItems'] as int? ?? 0;
        final items = data['items'] as List<dynamic>?;

        if (items != null && items.isNotEmpty) {
          debugPrint(
            '[GoogleBooks] Raw API returned ${items.length} items (totalItems reported: $totalItems)',
          );
          final books =
              items.map((item) {
                final bookData = item as Map<String, dynamic>;
                final volInfo =
                    bookData['volumeInfo'] as Map<String, dynamic>? ?? {};
                final itemTitle = volInfo['title'] as String? ?? 'NO TITLE';
                final itemAuthors =
                    (volInfo['authors'] as List<dynamic>?)?.join(', ') ??
                    'NO AUTHORS';
                final itemLang = volInfo['language'] as String? ?? 'NO LANG';
                final itemDate =
                    volInfo['publishedDate'] as String? ?? 'NO DATE';
                final itemISBNs =
                    volInfo['industryIdentifiers'] as List<dynamic>?;
                final isbnStr =
                    itemISBNs
                        ?.map((id) => '${id['type']}:${id['identifier']}')
                        .join(', ') ??
                    'NO ISBN';
                debugPrint(
                  '[GoogleBooks] Item: "$itemTitle" | Authors: $itemAuthors | Lang: $itemLang | Date: $itemDate | ISBNs: $isbnStr',
                );
                return _parseGoogleBooksResponse(bookData);
              }).toList();
          debugPrint(
            '[GoogleBooks] Parsed ${books.length} books from API page (startIndex: $startIndex)',
          );
          return (books: books, totalItems: totalItems);
        } else {
          debugPrint('[GoogleBooks] No results for author: $author');
        }
      } else {
        debugPrint('[GoogleBooks] API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[GoogleBooks] Error fetching by author: $e');
    }

    return (books: <BookMetadata>[], totalItems: 0);
  }

  /// Parse Google Books API response into BookMetadata
  BookMetadata _parseGoogleBooksResponse(Map<String, dynamic> bookData) {
    final volumeInfo = bookData['volumeInfo'] as Map<String, dynamic>? ?? {};
    final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
    final industryIdentifiers =
        volumeInfo['industryIdentifiers'] as List<dynamic>?;

    // Extract ISBNs
    String? isbn10;
    String? isbn13;
    if (industryIdentifiers != null) {
      for (var identifier in industryIdentifiers) {
        final type = identifier['type'] as String?;
        final value = identifier['identifier'] as String?;
        if (type == 'ISBN_10') isbn10 = value;
        if (type == 'ISBN_13') isbn13 = value;
      }
    }

    // Extract cover images (Google Books provides multiple sizes)
    // Replace http:// with https:// for security
    String? secureUrl(String? url) {
      if (url == null) return null;
      return url.replaceFirst('http://', 'https://');
    }

    // Get description
    final description = volumeInfo['description'] as String?;

    // Extract publication year
    final publishedDate = volumeInfo['publishedDate'] as String?;
    int? publishedYear;
    if (publishedDate != null && publishedDate.length >= 4) {
      publishedYear = int.tryParse(publishedDate.substring(0, 4));
    }

    return BookMetadata(
      title: volumeInfo['title'] as String?,
      authors: (volumeInfo['authors'] as List<dynamic>?)?.cast<String>(),
      description: description,
      isbn10: isbn10,
      isbn13: isbn13,
      publishedYear: publishedYear,
      pageCount: volumeInfo['pageCount'] as int?,
      publisher: volumeInfo['publisher'] as String?,
      language: volumeInfo['language'] as String?,
      smallThumbnailUrl: secureUrl(imageLinks?['smallThumbnail'] as String?),
      thumbnailUrl: secureUrl(imageLinks?['thumbnail'] as String?),
      coverUrl: secureUrl(imageLinks?['small'] as String?),
      mediumCoverUrl: secureUrl(imageLinks?['medium'] as String?),
      largeCoverUrl: secureUrl(imageLinks?['large'] as String?),
      source: 'google_books',
      fetchedAt: DateTime.now(),
    );
  }

  /// Sanitize query string for URL encoding
  String _sanitizeQuery(String query) {
    return Uri.encodeComponent(query.trim());
  }

  /// Throttle requests to respect rate limits
  Future<void> _throttleRequest() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  /// Map book language codes to Google Books API language codes
  /// Returns null if language is not supported or unknown
  String? _mapLanguageCode(String language) {
    final normalized = language.toLowerCase().trim();

    // Common language mappings
    const languageMap = {
      // English variants
      'english': 'en',
      'inglés': 'en',
      'ingles': 'en',
      'en': 'en',

      // Spanish variants
      'spanish': 'es',
      'español': 'es',
      'espanol': 'es',
      'es': 'es',

      // French variants
      'french': 'fr',
      'français': 'fr',
      'francais': 'fr',
      'fr': 'fr',

      // German variants
      'german': 'de',
      'deutsch': 'de',
      'alemán': 'de',
      'aleman': 'de',
      'de': 'de',

      // Italian variants
      'italian': 'it',
      'italiano': 'it',
      'it': 'it',

      // Portuguese variants
      'portuguese': 'pt',
      'português': 'pt',
      'portugues': 'pt',
      'pt': 'pt',

      // Japanese variants
      'japanese': 'ja',
      'japonés': 'ja',
      'japones': 'ja',
      'ja': 'ja',

      // Chinese variants
      'chinese': 'zh',
      'chino': 'zh',
      'zh': 'zh',

      // Russian variants
      'russian': 'ru',
      'ruso': 'ru',
      'ru': 'ru',

      // Korean variants
      'korean': 'ko',
      'coreano': 'ko',
      'ko': 'ko',
    };

    return languageMap[normalized];
  }
}
