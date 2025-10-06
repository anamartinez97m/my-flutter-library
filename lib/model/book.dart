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
    };
  }
}
