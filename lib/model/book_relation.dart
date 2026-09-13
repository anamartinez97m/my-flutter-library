class BookRelation {
  final int? relationId;
  final int fromBookId;
  final int toBookId;
  final String type; // 'next', 'related', 'optional'

  BookRelation({
    this.relationId,
    required this.fromBookId,
    required this.toBookId,
    required this.type,
  });

  factory BookRelation.fromMap(Map<String, dynamic> map) {
    return BookRelation(
      relationId: map['relation_id'] as int?,
      fromBookId: map['from_book_id'] as int,
      toBookId: map['to_book_id'] as int,
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'relation_id': relationId,
      'from_book_id': fromBookId,
      'to_book_id': toBookId,
      'type': type,
    };
  }

  @override
  String toString() {
    return 'BookRelation(relationId: $relationId, fromBookId: $fromBookId, toBookId: $toBookId, type: $type)';
  }
}
