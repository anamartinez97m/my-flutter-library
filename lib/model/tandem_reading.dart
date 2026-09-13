class TandemReading {
  final int? tandemId;
  final int bookAId;
  final int bookBId;
  final String? title;
  final String? createdAt;

  TandemReading({
    this.tandemId,
    required this.bookAId,
    required this.bookBId,
    this.title,
    this.createdAt,
  });

  factory TandemReading.fromMap(Map<String, dynamic> map) {
    return TandemReading(
      tandemId: map['tandem_id'] as int?,
      bookAId: map['book_a_id'] as int,
      bookBId: map['book_b_id'] as int,
      title: map['title'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tandem_id': tandemId,
      'book_a_id': bookAId,
      'book_b_id': bookBId,
      'title': title,
      'created_at': createdAt,
    };
  }

  @override
  String toString() {
    return 'TandemReading(tandemId: $tandemId, bookAId: $bookAId, bookBId: $bookBId, title: $title, createdAt: $createdAt)';
  }
}
