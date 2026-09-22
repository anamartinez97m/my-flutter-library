class UniversePlaceholder {
  final int? placeholderId;
  final String sagaUniverse;
  final String title;
  final String? author;
  final String? saga;
  final String? nSaga;
  final int? orderWithinUniverse;
  final String? coverUrl;
  final String? notes;
  final String? createdAt;

  const UniversePlaceholder({
    this.placeholderId,
    required this.sagaUniverse,
    required this.title,
    this.author,
    this.saga,
    this.nSaga,
    this.orderWithinUniverse,
    this.coverUrl,
    this.notes,
    this.createdAt,
  });

  factory UniversePlaceholder.fromMap(Map<String, dynamic> map) {
    return UniversePlaceholder(
      placeholderId: map['placeholder_id'] as int?,
      sagaUniverse: map['saga_universe'] as String,
      title: map['title'] as String,
      author: map['author'] as String?,
      saga: map['saga'] as String?,
      nSaga: map['n_saga'] as String?,
      orderWithinUniverse: map['order_within_universe'] as int?,
      coverUrl: map['cover_url'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'placeholder_id': placeholderId,
    'saga_universe': sagaUniverse,
    'title': title,
    'author': author,
    'saga': saga,
    'n_saga': nSaga,
    'order_within_universe': orderWithinUniverse,
    'cover_url': coverUrl,
    'notes': notes,
    'created_at': createdAt,
  };
}
