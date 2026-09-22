class PlaceholderRelation {
  final int? relationId;
  final int placeholderId;
  final int bookId;
  final bool placeholderIsSource;
  final String type;
  final String? createdAt;

  const PlaceholderRelation({
    this.relationId,
    required this.placeholderId,
    required this.bookId,
    required this.placeholderIsSource,
    required this.type,
    this.createdAt,
  });

  factory PlaceholderRelation.fromMap(Map<String, dynamic> map) {
    return PlaceholderRelation(
      relationId: map['relation_id'] as int?,
      placeholderId: map['placeholder_id'] as int,
      bookId: map['book_id'] as int,
      placeholderIsSource:
          map['placeholder_is_source'] == 1 ||
          map['placeholder_is_source'] == true,
      type: (map['relation_type'] as String?) ?? 'next',
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'relation_id': relationId,
    'placeholder_id': placeholderId,
    'book_id': bookId,
    'placeholder_is_source': placeholderIsSource ? 1 : 0,
    'relation_type': type,
    'created_at': createdAt,
  };
}
