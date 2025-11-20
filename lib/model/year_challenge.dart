/// Model for yearly reading challenges
class YearChallenge {
  final int? challengeId;
  final int year;
  final int targetBooks;
  final int? targetPages;
  final DateTime createdAt;
  final String? notes;

  YearChallenge({
    this.challengeId,
    required this.year,
    required this.targetBooks,
    this.targetPages,
    DateTime? createdAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'challenge_id': challengeId,
      'year': year,
      'target_books': targetBooks,
      'target_pages': targetPages,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory YearChallenge.fromMap(Map<String, dynamic> map) {
    return YearChallenge(
      challengeId: map['challenge_id'] as int?,
      year: map['year'] as int,
      targetBooks: map['target_books'] as int,
      targetPages: map['target_pages'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      notes: map['notes'] as String?,
    );
  }

  YearChallenge copyWith({
    int? challengeId,
    int? year,
    int? targetBooks,
    int? targetPages,
    DateTime? createdAt,
    String? notes,
  }) {
    return YearChallenge(
      challengeId: challengeId ?? this.challengeId,
      year: year ?? this.year,
      targetBooks: targetBooks ?? this.targetBooks,
      targetPages: targetPages ?? this.targetPages,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}
