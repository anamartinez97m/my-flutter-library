class Book {
  final int? bookId;
  final int? statusId = 0;
  final String? statusValue;
  final String? name;
  final int? editorialId = 0;
  final String? editorialValue;
  final String? saga;
  final String? nSaga;
  final int? formatSagaId = 0;
  final String? formatSagaValue;
  final String? isbn;
  final int? pages;
  final int? originalPublicationYear;
  final String? loaned;
  final int? languageId = 0;
  final String? languageValue;
  final int? placeId = 0;
  final String? placeValue;
  final int? formatId = 0;
  final String? formatValue;
  final String? createdAt;
  final String? author;
  final String? genre;
  final String? dateReadInitial;
  final String? dateReadFinal;
  final int? readCount;
  final double? myRating;
  final String? myReview;
  final bool? isBundle;
  final int? bundleCount;
  final String? bundleNumbers;
  final String? bundleStartDates;
  final String? bundleEndDates;
  final String? bundlePages;

  Book({
    required this.bookId,
    required this.name,
    required this.saga,
    required this.nSaga,
    required this.formatSagaValue,
    required this.isbn,
    required this.pages,
    required this.originalPublicationYear,
    required this.loaned,
    required this.statusValue,
    required this.editorialValue,
    required this.languageValue,
    required this.placeValue,
    required this.formatValue,
    required this.createdAt,
    this.author,
    this.genre,
    this.dateReadInitial,
    this.dateReadFinal,
    this.readCount,
    this.myRating,
    this.myReview,
    this.isBundle,
    this.bundleCount,
    this.bundleNumbers,
    this.bundleStartDates,
    this.bundleEndDates,
    this.bundlePages,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      bookId: map['book_id'] as int?,
      name: map['name'] as String?,
      saga: map['saga'] as String?,
      nSaga: map['n_saga'] as String?,
      formatSagaValue: map['formatSagaValue'] as String?,
      isbn: map['isbn'] as String?,
      pages:
          map['pages'] is int
              ? map['pages'] as int
              : int.tryParse(map['pages']?.toString() ?? ''),
      originalPublicationYear:
          map['original_publication_year'] is int
              ? map['original_publication_year'] as int
              : int.tryParse(
                map['original_publication_year']?.toString() ?? '',
              ),
      loaned: map['loaned'],
      statusValue: map['statusValue'] as String?,
      editorialValue: map['editorialValue'] as String?,
      languageValue: map['languageValue'] as String?,
      placeValue: map['placeValue'] as String?,
      formatValue: map['formatValue'] as String?,
      createdAt: map['created_at'] as String?,
      author: map['author'] as String?,
      genre: map['genre'] as String?,
      dateReadInitial: map['date_read_initial'] as String?,
      dateReadFinal: map['date_read_final'] as String?,
      readCount: map['read_count'] is int
          ? map['read_count'] as int
          : int.tryParse(map['read_count']?.toString() ?? ''),
      myRating: map['my_rating'] is double
          ? map['my_rating'] as double
          : double.tryParse(map['my_rating']?.toString() ?? ''),
      myReview: map['my_review'] as String?,
      isBundle: map['is_bundle'] == 1 || map['is_bundle'] == true,
      bundleCount: map['bundle_count'] is int
          ? map['bundle_count'] as int
          : int.tryParse(map['bundle_count']?.toString() ?? ''),
      bundleNumbers: map['bundle_numbers'] as String?,
      bundleStartDates: map['bundle_start_dates'] as String?,
      bundleEndDates: map['bundle_end_dates'] as String?,
      bundlePages: map['bundle_pages'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'name': name,
      'saga': saga,
      'nSaga': nSaga,
      'formatSagaValue': formatSagaValue,
      'isbn': isbn,
      'pages': pages,
      'originalPublicationYear': originalPublicationYear,
      'loaned': loaned,
      'statusValue': statusValue,
      'editorialValue': editorialValue,
      'languageValue': languageValue,
      'placeValue': placeValue,
      'formatValue': formatValue,
      'createdAt': createdAt,
      'author': author,
      'genre': genre,
      'dateReadInitial': dateReadInitial,
      'dateReadFinal': dateReadFinal,
      'readCount': readCount,
      'myRating': myRating,
      'myReview': myReview,
      'isBundle': isBundle,
      'bundleCount': bundleCount,
      'bundleNumbers': bundleNumbers,
      'bundleStartDates': bundleStartDates,
      'bundleEndDates': bundleEndDates,
      'bundlePages': bundlePages,
    };
  }

  @override
  String toString() {
    return 'Book(bookId: $bookId, name: $name, author: $author, genre: $genre, saga: $saga, nSaga: $nSaga, formatSagaValue: $formatSagaValue, isbn: $isbn, pages: $pages, originalPublicationYear: $originalPublicationYear, loaned: $loaned, statusValue: $statusValue, editorialValue: $editorialValue, languageValue: $languageValue, placeValue: $placeValue, formatValue: $formatValue, createdAt: $createdAt, dateReadInitial: $dateReadInitial, dateReadFinal: $dateReadFinal, readCount: $readCount, myRating: $myRating, myReview: $myReview, isBundle: $isBundle, bundleCount: $bundleCount, bundleNumbers: $bundleNumbers, bundleStartDates: $bundleStartDates, bundleEndDates: $bundleEndDates, bundlePages: $bundlePages)';
  }
}
