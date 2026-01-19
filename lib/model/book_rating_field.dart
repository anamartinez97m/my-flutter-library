class BookRatingField {
  final int? ratingFieldId;
  final int bookId;
  final String fieldName;
  final double ratingValue;

  BookRatingField({
    this.ratingFieldId,
    required this.bookId,
    required this.fieldName,
    required this.ratingValue,
  });

  factory BookRatingField.fromMap(Map<String, dynamic> map) {
    return BookRatingField(
      ratingFieldId: map['rating_field_id'] as int?,
      bookId: map['book_id'] as int,
      fieldName: map['field_name'] as String,
      ratingValue: map['rating_value'] is double
          ? map['rating_value'] as double
          : double.tryParse(map['rating_value']?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating_field_id': ratingFieldId,
      'book_id': bookId,
      'field_name': fieldName,
      'rating_value': ratingValue,
    };
  }

  @override
  String toString() {
    return 'BookRatingField(ratingFieldId: $ratingFieldId, bookId: $bookId, fieldName: $fieldName, ratingValue: $ratingValue)';
  }
}
