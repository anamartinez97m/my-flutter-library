class ReadDate {
  final int? readDateId;
  final int bookId;
  final String? dateStarted;
  final String? dateFinished;
  final int? bundleBookIndex; // null for regular books, 0-based index for bundle books
  final int? readingProgress; // Progress at the time of finishing

  ReadDate({
    this.readDateId,
    required this.bookId,
    this.dateStarted,
    this.dateFinished,
    this.bundleBookIndex,
    this.readingProgress,
  });

  factory ReadDate.fromMap(Map<String, dynamic> map) {
    return ReadDate(
      readDateId: map['read_date_id'] as int?,
      bookId: map['book_id'] as int,
      dateStarted: map['date_started'] as String?,
      dateFinished: map['date_finished'] as String?,
      bundleBookIndex: map['bundle_book_index'] as int?,
      readingProgress: map['reading_progress'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'read_date_id': readDateId,
      'book_id': bookId,
      'date_started': dateStarted,
      'date_finished': dateFinished,
      'bundle_book_index': bundleBookIndex,
      'reading_progress': readingProgress,
    };
  }

  @override
  String toString() {
    return 'ReadDate(readDateId: $readDateId, bookId: $bookId, dateStarted: $dateStarted, dateFinished: $dateFinished, bundleBookIndex: $bundleBookIndex)';
  }
}
