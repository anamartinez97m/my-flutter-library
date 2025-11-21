import 'dart:convert';
import 'custom_challenge.dart';

/// Model for yearly reading challenges
class YearChallenge {
  final int? challengeId;
  final int year;
  final int targetBooks;
  final int? targetPages;
  final DateTime createdAt;
  final String? notes;
  final List<CustomChallenge>? customChallenges;

  YearChallenge({
    this.challengeId,
    required this.year,
    required this.targetBooks,
    this.targetPages,
    DateTime? createdAt,
    this.notes,
    this.customChallenges,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'challenge_id': challengeId,
      'year': year,
      'target_books': targetBooks,
      'target_pages': targetPages,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'custom_challenges': customChallenges != null
          ? jsonEncode(customChallenges!.map((c) => c.toJson()).toList())
          : null,
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
      customChallenges: map['custom_challenges'] != null
          ? (jsonDecode(map['custom_challenges']) as List)
              .map((c) => CustomChallenge.fromJson(c))
              .toList()
          : null,
    );
  }

  YearChallenge copyWith({
    int? challengeId,
    int? year,
    int? targetBooks,
    int? targetPages,
    DateTime? createdAt,
    String? notes,
    List<CustomChallenge>? customChallenges,
  }) {
    return YearChallenge(
      challengeId: challengeId ?? this.challengeId,
      year: year ?? this.year,
      targetBooks: targetBooks ?? this.targetBooks,
      targetPages: targetPages ?? this.targetPages,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      customChallenges: customChallenges ?? this.customChallenges,
    );
  }
}
