import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../model/book_metadata.dart';

/// Service for fetching book metadata from Open Library API
/// API Documentation: https://openlibrary.org/dev/docs/api/books
class OpenLibraryService {
  static const String _baseUrl = 'https://openlibrary.org';
  static const String _coversUrl = 'https://covers.openlibrary.org/b';
  static const Duration _timeout = Duration(seconds: 10);
  
  // Rate limiting: Open Library recommends max 100 requests/minute
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 600);

  /// Fetch book metadata by ISBN
  Future<BookMetadata?> fetchByIsbn(String isbn) async {
    try {
      await _throttleRequest();
      
      // Clean ISBN
      final cleanIsbn = isbn.replaceAll(RegExp(r'[^0-9X]'), '');
      
      if (cleanIsbn.isEmpty) {
        debugPrint('[OpenLibrary] Invalid ISBN: $isbn');
        return null;
      }

      final url = Uri.parse('$_baseUrl/api/books?bibkeys=ISBN:$cleanIsbn&format=json&jscmd=data');
      debugPrint('[OpenLibrary] Fetching by ISBN: $cleanIsbn');
      
      final response = await http.get(url).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final bookKey = 'ISBN:$cleanIsbn';
        
        if (data.containsKey(bookKey)) {
          final bookData = data[bookKey] as Map<String, dynamic>;
          final metadata = _parseOpenLibraryResponse(bookData, cleanIsbn);
          debugPrint('[OpenLibrary] Successfully fetched by ISBN: ${metadata.title}');
          return metadata;
        } else {
          debugPrint('[OpenLibrary] No results found for ISBN: $cleanIsbn');
        }
      } else {
        debugPrint('[OpenLibrary] API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OpenLibrary] Error fetching by ISBN: $e');
    }
    
    return null;
  }

  /// Fetch book metadata by title (Open Library search is less reliable than ISBN)
  Future<BookMetadata?> fetchByTitle(String title, {String? author}) async {
    try {
      await _throttleRequest();
      
      if (title.trim().isEmpty) {
        debugPrint('[OpenLibrary] Invalid title');
        return null;
      }

      // Build query
      String query = title.trim();
      if (author != null && author.trim().isNotEmpty) {
        query += ' $author';
      }

      final url = Uri.parse('$_baseUrl/search.json?q=${Uri.encodeComponent(query)}&limit=1');
      debugPrint('[OpenLibrary] Searching by title: $query');
      
      final response = await http.get(url).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final docs = data['docs'] as List<dynamic>?;
        
        if (docs != null && docs.isNotEmpty) {
          final bookData = docs[0] as Map<String, dynamic>;
          final metadata = _parseOpenLibrarySearchResponse(bookData);
          debugPrint('[OpenLibrary] Successfully fetched by title: ${metadata.title}');
          return metadata;
        } else {
          debugPrint('[OpenLibrary] No results found for: $query');
        }
      } else {
        debugPrint('[OpenLibrary] API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[OpenLibrary] Error fetching by title: $e');
    }
    
    return null;
  }

  /// Fetch description from Open Library work page
  /// This is a separate call because descriptions are not in the books API
  Future<String?> fetchDescription(String workKey) async {
    try {
      await _throttleRequest();
      
      final url = Uri.parse('$_baseUrl$workKey.json');
      debugPrint('[OpenLibrary] Fetching description for: $workKey');
      
      final response = await http.get(url).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Description can be a string or an object with 'value' key
        final description = data['description'];
        if (description is String) {
          return description;
        } else if (description is Map<String, dynamic>) {
          return description['value'] as String?;
        }
      }
    } catch (e) {
      debugPrint('[OpenLibrary] Error fetching description: $e');
    }
    
    return null;
  }

  /// Parse Open Library Books API response
  BookMetadata _parseOpenLibraryResponse(Map<String, dynamic> bookData, String isbn) {
    // Extract authors
    final authorsData = bookData['authors'] as List<dynamic>?;
    List<String>? authors;
    if (authorsData != null) {
      authors = authorsData.map((a) {
        if (a is Map<String, dynamic>) {
          return a['name'] as String? ?? '';
        } else if (a is String) {
          return a;
        }
        return '';
      }).where((name) => name.isNotEmpty).toList();
    }

    // Extract publication year
    final publishDate = bookData['publish_date'];
    int? publishedYear;
    if (publishDate != null) {
      final dateStr = publishDate.toString();
      final yearMatch = RegExp(r'\d{4}').firstMatch(dateStr);
      if (yearMatch != null) {
        publishedYear = int.tryParse(yearMatch.group(0)!);
      }
    }

    // Build cover URLs using ISBN
    final coverUrls = _buildCoverUrls(isbn);

    // Extract identifiers
    final identifiers = bookData['identifiers'] as Map<String, dynamic>?;
    String? isbn10;
    String? isbn13;
    
    if (identifiers != null) {
      final isbn10List = identifiers['isbn_10'] as List<dynamic>?;
      final isbn13List = identifiers['isbn_13'] as List<dynamic>?;
      
      if (isbn10List != null && isbn10List.isNotEmpty) {
        isbn10 = isbn10List[0].toString();
      }
      if (isbn13List != null && isbn13List.isNotEmpty) {
        isbn13 = isbn13List[0].toString();
      }
    }

    // Extract publisher safely
    String? publisher;
    final publishersData = bookData['publishers'];
    if (publishersData is List && publishersData.isNotEmpty) {
      final firstPublisher = publishersData[0];
      if (firstPublisher is Map<String, dynamic>) {
        publisher = firstPublisher['name'] as String?;
      } else if (firstPublisher is String) {
        publisher = firstPublisher;
      } else {
        publisher = firstPublisher.toString();
      }
    } else if (publishersData is String) {
      publisher = publishersData;
    }

    return BookMetadata(
      title: bookData['title'] as String?,
      authors: authors,
      description: null, // Descriptions require separate API call
      isbn10: isbn10,
      isbn13: isbn13,
      publishedYear: publishedYear,
      pageCount: bookData['number_of_pages'] as int?,
      publisher: publisher,
      smallThumbnailUrl: coverUrls['small'],
      thumbnailUrl: coverUrls['medium'],
      coverUrl: coverUrls['medium'],
      mediumCoverUrl: coverUrls['medium'],
      largeCoverUrl: coverUrls['large'],
      source: 'open_library',
      fetchedAt: DateTime.now(),
    );
  }

  /// Parse Open Library Search API response
  BookMetadata _parseOpenLibrarySearchResponse(Map<String, dynamic> bookData) {
    // Extract authors
    final authorNames = (bookData['author_name'] as List<dynamic>?)?.cast<String>();

    // Extract publication year
    final firstPublishYear = bookData['first_publish_year'] as int?;

    // Extract ISBNs
    final isbnList = bookData['isbn'] as List<dynamic>?;
    String? isbn10;
    String? isbn13;
    
    if (isbnList != null && isbnList.isNotEmpty) {
      for (var isbn in isbnList) {
        final isbnStr = isbn.toString();
        if (isbnStr.length == 10) {
          isbn10 ??= isbnStr;
        } else if (isbnStr.length == 13) {
          isbn13 ??= isbnStr;
        }
      }
    }

    // Get cover ID for building URLs
    final coverId = bookData['cover_i'] as int?;
    Map<String, String?>? coverUrls;
    if (coverId != null) {
      coverUrls = _buildCoverUrlsById(coverId);
    }

    // Extract publisher safely
    String? publisher;
    final publisherData = bookData['publisher'];
    if (publisherData is List && publisherData.isNotEmpty) {
      publisher = publisherData[0].toString();
    } else if (publisherData is String) {
      publisher = publisherData;
    }

    return BookMetadata(
      title: bookData['title'] as String?,
      authors: authorNames,
      description: null, // Not available in search results
      isbn10: isbn10,
      isbn13: isbn13,
      publishedYear: firstPublishYear,
      pageCount: bookData['number_of_pages_median'] as int?,
      publisher: publisher,
      smallThumbnailUrl: coverUrls?['small'],
      thumbnailUrl: coverUrls?['medium'],
      coverUrl: coverUrls?['medium'],
      mediumCoverUrl: coverUrls?['medium'],
      largeCoverUrl: coverUrls?['large'],
      source: 'open_library',
      fetchedAt: DateTime.now(),
    );
  }

  /// Build cover URLs using ISBN
  Map<String, String?> _buildCoverUrls(String isbn) {
    return {
      'small': '$_coversUrl/isbn/$isbn-S.jpg',
      'medium': '$_coversUrl/isbn/$isbn-M.jpg',
      'large': '$_coversUrl/isbn/$isbn-L.jpg',
    };
  }

  /// Build cover URLs using cover ID
  Map<String, String?> _buildCoverUrlsById(int coverId) {
    return {
      'small': '$_coversUrl/id/$coverId-S.jpg',
      'medium': '$_coversUrl/id/$coverId-M.jpg',
      'large': '$_coversUrl/id/$coverId-L.jpg',
    };
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
}
