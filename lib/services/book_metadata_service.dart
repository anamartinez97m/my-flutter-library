import 'package:flutter/foundation.dart';
import '../model/book_metadata.dart';
import 'google_books_service.dart';
import 'open_library_service.dart';

/// Hybrid book metadata service that combines Google Books and Open Library APIs
/// 
/// Strategy:
/// 1. Primary source: Google Books API (query by ISBN first, then title+author)
/// 2. Fallback source: Open Library API (only if Google Books fails or data is incomplete)
/// 3. Merge results: Prefer Google Books data, fill missing fields with Open Library
/// 4. Cache results locally to avoid repeated API calls
class BookMetadataService {
  final GoogleBooksService _googleBooksService = GoogleBooksService();
  final OpenLibraryService _openLibraryService = OpenLibraryService();

  /// Fetch complete book metadata using hybrid strategy
  /// 
  /// Parameters:
  /// - [isbn]: Book ISBN (preferred for accurate results)
  /// - [title]: Book title (required if ISBN not available)
  /// - [author]: Book author (optional, improves search accuracy)
  /// - [language]: Book language (optional, filters Google Books results by language)
  /// 
  /// Returns merged metadata from both sources, or null if no data found
  Future<BookMetadata?> fetchMetadata({
    String? isbn,
    String? title,
    String? author,
    String? language,
  }) async {
    debugPrint('[MetadataService] Starting fetch - ISBN: $isbn, Title: $title, Author: $author, Language: $language');

    // Validate input
    if ((isbn == null || isbn.trim().isEmpty) && 
        (title == null || title.trim().isEmpty)) {
      debugPrint('[MetadataService] Error: ISBN or title required');
      return null;
    }

    BookMetadata? googleMetadata;
    BookMetadata? openLibraryMetadata;

    // STEP 1: Try Google Books API (Primary Source)
    try {
      if (isbn != null && isbn.trim().isNotEmpty) {
        // Prefer ISBN search for accuracy
        googleMetadata = await _googleBooksService.fetchByIsbn(
          isbn,
          language: language,
        );
      }
      
      // Fallback to title+author search if ISBN failed or not provided
      if (googleMetadata == null && title != null && title.trim().isNotEmpty) {
        googleMetadata = await _googleBooksService.fetchByTitleAndAuthor(
          title,
          author: author,
          language: language,
        );
      }
    } catch (e) {
      debugPrint('[MetadataService] Google Books error: $e');
    }

    // STEP 2: Check if we need Open Library fallback
    final needsOpenLibrary = _shouldFetchFromOpenLibrary(googleMetadata);
    
    if (needsOpenLibrary) {
      debugPrint('[MetadataService] Fetching from Open Library (missing data)');
      
      try {
        if (isbn != null && isbn.trim().isNotEmpty) {
          openLibraryMetadata = await _openLibraryService.fetchByIsbn(isbn);
        } else if (title != null && title.trim().isNotEmpty) {
          openLibraryMetadata = await _openLibraryService.fetchByTitle(
            title,
            author: author,
          );
        }
      } catch (e) {
        debugPrint('[MetadataService] Open Library error: $e');
      }
    }

    // STEP 3: Merge results
    final mergedMetadata = _mergeMetadata(googleMetadata, openLibraryMetadata);
    
    if (mergedMetadata != null) {
      debugPrint('[MetadataService] Success - Source: ${mergedMetadata.source}, '
          'HasDescription: ${mergedMetadata.hasDescription}, '
          'HasCover: ${mergedMetadata.hasCover}');
    } else {
      debugPrint('[MetadataService] No metadata found');
    }

    return mergedMetadata;
  }

  /// Determine if we should fetch from Open Library
  /// 
  /// Fetch from Open Library if:
  /// - Google Books returned no results, OR
  /// - Description is missing or empty, OR
  /// - Cover image is missing
  bool _shouldFetchFromOpenLibrary(BookMetadata? googleMetadata) {
    if (googleMetadata == null) {
      return true; // No Google Books data at all
    }

    if (!googleMetadata.hasDescription) {
      debugPrint('[MetadataService] Missing description from Google Books');
      return true;
    }

    if (!googleMetadata.hasCover) {
      debugPrint('[MetadataService] Missing cover from Google Books');
      return true;
    }

    return false; // Google Books data is complete
  }

  /// Merge metadata from Google Books and Open Library
  /// 
  /// Strategy:
  /// - Prefer Google Books data when available
  /// - Fill missing fields with Open Library data
  /// - Never overwrite existing valid data
  BookMetadata? _mergeMetadata(
    BookMetadata? googleMetadata,
    BookMetadata? openLibraryMetadata,
  ) {
    // If both are null, return null
    if (googleMetadata == null && openLibraryMetadata == null) {
      return null;
    }

    // If only one source has data, return it
    if (googleMetadata == null) {
      return openLibraryMetadata!.copyWith(source: 'open_library');
    }
    if (openLibraryMetadata == null) {
      return googleMetadata.copyWith(source: 'google_books');
    }

    // Both sources have data - merge them
    debugPrint('[MetadataService] Merging data from both sources');

    return BookMetadata(
      // Prefer Google Books for text data
      title: googleMetadata.title ?? openLibraryMetadata.title,
      authors: googleMetadata.authors ?? openLibraryMetadata.authors,
      description: _selectBestDescription(
        googleMetadata.description,
        openLibraryMetadata.description,
      ),
      publisher: googleMetadata.publisher ?? openLibraryMetadata.publisher,
      language: googleMetadata.language ?? openLibraryMetadata.language,
      
      // Prefer Google Books for numeric data
      publishedYear: googleMetadata.publishedYear ?? openLibraryMetadata.publishedYear,
      pageCount: googleMetadata.pageCount ?? openLibraryMetadata.pageCount,
      
      // Prefer Google Books for identifiers
      isbn10: googleMetadata.isbn10 ?? openLibraryMetadata.isbn10,
      isbn13: googleMetadata.isbn13 ?? openLibraryMetadata.isbn13,
      
      // Merge cover images (prefer Google Books, but keep all available sizes)
      smallThumbnailUrl: googleMetadata.smallThumbnailUrl ?? 
                         openLibraryMetadata.smallThumbnailUrl,
      thumbnailUrl: googleMetadata.thumbnailUrl ?? 
                    openLibraryMetadata.thumbnailUrl,
      coverUrl: googleMetadata.coverUrl ?? 
                openLibraryMetadata.coverUrl,
      mediumCoverUrl: googleMetadata.mediumCoverUrl ?? 
                      openLibraryMetadata.mediumCoverUrl,
      largeCoverUrl: googleMetadata.largeCoverUrl ?? 
                     openLibraryMetadata.largeCoverUrl,
      
      source: 'merged',
      fetchedAt: DateTime.now(),
    );
  }

  /// Select the best description from available options
  /// Prefer longer, more detailed descriptions
  String? _selectBestDescription(String? desc1, String? desc2) {
    if (desc1 == null || desc1.trim().isEmpty) return desc2;
    if (desc2 == null || desc2.trim().isEmpty) return desc1;
    
    // Prefer the longer description (usually more detailed)
    return desc1.length >= desc2.length ? desc1 : desc2;
  }

  /// Fetch only cover image (useful for updating existing books)
  Future<String?> fetchCoverOnly({
    String? isbn,
    String? title,
    String? author,
    String? language,
  }) async {
    final metadata = await fetchMetadata(
      isbn: isbn,
      title: title,
      author: author,
      language: language,
    );
    
    return metadata?.bestCoverUrl;
  }

  /// Fetch only description (useful for updating existing books)
  Future<String?> fetchDescriptionOnly({
    String? isbn,
    String? title,
    String? author,
    String? language,
  }) async {
    final metadata = await fetchMetadata(
      isbn: isbn,
      title: title,
      author: author,
      language: language,
    );
    
    return metadata?.description;
  }
}
