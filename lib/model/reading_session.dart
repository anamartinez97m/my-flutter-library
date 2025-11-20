/// Model for tracking active reading sessions with chronometer
class ReadingSession {
  final int? sessionId;
  final int bookId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds; // Total reading time in seconds
  final bool isActive;

  ReadingSession({
    this.sessionId,
    required this.bookId,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'book_id': bookId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'is_active': isActive ? 1 : 0,
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
    );
  }

  ReadingSession copyWith({
    int? sessionId,
    int? bookId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    bool? isActive,
  }) {
    return ReadingSession(
      sessionId: sessionId ?? this.sessionId,
      bookId: bookId ?? this.bookId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isActive: isActive ?? this.isActive,
    );
  }
}
