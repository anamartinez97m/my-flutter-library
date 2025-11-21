/// Model for tracking active reading sessions with chronometer
class ReadingSession {
  final int? sessionId;
  final int bookId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds; // Total reading time in seconds
  final bool isActive;
  final DateTime? clickedAt; // When the chronometer was clicked/started

  ReadingSession({
    this.sessionId,
    required this.bookId,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.isActive = true,
    this.clickedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'book_id': bookId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'is_active': isActive ? 1 : 0,
      'clicked_at': clickedAt?.toIso8601String(),
    };
  }

  factory ReadingSession.fromMap(Map<String, dynamic> map) {
    return ReadingSession(
      sessionId: map['session_id'] as int?,
      bookId: map['book_id'] as int,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      durationSeconds: map['duration_seconds'] as int?,
      isActive: (map['is_active'] as int) == 1,
      clickedAt: map['clicked_at'] != null ? DateTime.parse(map['clicked_at'] as String) : null,
    );
  }

  ReadingSession copyWith({
    int? sessionId,
    int? bookId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    bool? isActive,
    DateTime? clickedAt,
  }) {
    return ReadingSession(
      sessionId: sessionId ?? this.sessionId,
      bookId: bookId ?? this.bookId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isActive: isActive ?? this.isActive,
      clickedAt: clickedAt ?? this.clickedAt,
    );
  }
}
