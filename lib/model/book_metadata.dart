/// Model for book metadata retrieved from external APIs
/// Supports data from Google Books API and Open Library API
class BookMetadata {
  final String? description;
  final String? coverUrl;
  final String? thumbnailUrl;
  final String? smallThumbnailUrl;
  final String? mediumCoverUrl;
  final String? largeCoverUrl;
  final String? isbn10;
  final String? isbn13;
  final String? title;
  final List<String>? authors;
  final int? publishedYear;
  final int? pageCount;
  final String? publisher;
  final String? language;
  final String? source; // 'google_books', 'open_library', 'merged'
  final DateTime? fetchedAt;

  BookMetadata({
    this.description,
    this.coverUrl,
    this.thumbnailUrl,
    this.smallThumbnailUrl,
    this.mediumCoverUrl,
    this.largeCoverUrl,
    this.isbn10,
    this.isbn13,
    this.title,
    this.authors,
    this.publishedYear,
    this.pageCount,
    this.publisher,
    this.language,
    this.source,
    this.fetchedAt,
  });

  /// Get the best available cover URL (prefers larger sizes)
  String? get bestCoverUrl {
    return largeCoverUrl ?? 
           mediumCoverUrl ?? 
           coverUrl ?? 
           thumbnailUrl ?? 
           smallThumbnailUrl;
  }

  /// Check if metadata has valid description
  bool get hasDescription => 
      description != null && description!.trim().isNotEmpty;

  /// Check if metadata has valid cover image
  bool get hasCover => bestCoverUrl != null;

  /// Check if metadata is complete (has both description and cover)
  bool get isComplete => hasDescription && hasCover;

  /// Create from JSON (for caching)
  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    return BookMetadata(
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      smallThumbnailUrl: json['smallThumbnailUrl'] as String?,
      mediumCoverUrl: json['mediumCoverUrl'] as String?,
      largeCoverUrl: json['largeCoverUrl'] as String?,
      isbn10: json['isbn10'] as String?,
      isbn13: json['isbn13'] as String?,
      title: json['title'] as String?,
      authors: (json['authors'] as List<dynamic>?)?.cast<String>(),
      publishedYear: json['publishedYear'] as int?,
      pageCount: json['pageCount'] as int?,
      publisher: json['publisher'] as String?,
      language: json['language'] as String?,
      source: json['source'] as String?,
      fetchedAt: json['fetchedAt'] != null 
          ? DateTime.parse(json['fetchedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'coverUrl': coverUrl,
      'thumbnailUrl': thumbnailUrl,
      'smallThumbnailUrl': smallThumbnailUrl,
      'mediumCoverUrl': mediumCoverUrl,
      'largeCoverUrl': largeCoverUrl,
      'isbn10': isbn10,
      'isbn13': isbn13,
      'title': title,
      'authors': authors,
      'publishedYear': publishedYear,
      'pageCount': pageCount,
      'publisher': publisher,
      'language': language,
      'source': source,
      'fetchedAt': fetchedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  BookMetadata copyWith({
    String? description,
    String? coverUrl,
    String? thumbnailUrl,
    String? smallThumbnailUrl,
    String? mediumCoverUrl,
    String? largeCoverUrl,
    String? isbn10,
    String? isbn13,
    String? title,
    List<String>? authors,
    int? publishedYear,
    int? pageCount,
    String? publisher,
    String? language,
    String? source,
    DateTime? fetchedAt,
  }) {
    return BookMetadata(
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      smallThumbnailUrl: smallThumbnailUrl ?? this.smallThumbnailUrl,
      mediumCoverUrl: mediumCoverUrl ?? this.mediumCoverUrl,
      largeCoverUrl: largeCoverUrl ?? this.largeCoverUrl,
      isbn10: isbn10 ?? this.isbn10,
      isbn13: isbn13 ?? this.isbn13,
      title: title ?? this.title,
      authors: authors ?? this.authors,
      publishedYear: publishedYear ?? this.publishedYear,
      pageCount: pageCount ?? this.pageCount,
      publisher: publisher ?? this.publisher,
      language: language ?? this.language,
      source: source ?? this.source,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  String toString() {
    return 'BookMetadata(title: $title, authors: $authors, hasDescription: $hasDescription, hasCover: $hasCover, source: $source)';
  }
}
