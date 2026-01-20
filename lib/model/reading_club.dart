class ReadingClub {
  final int? clubId;
  final int bookId;
  final String clubName;
  final String? targetDate;
  final int readingProgress;
  final String? createdAt;

  ReadingClub({
    this.clubId,
    required this.bookId,
    required this.clubName,
    this.targetDate,
    this.readingProgress = 0,
    this.createdAt,
  });

  factory ReadingClub.fromMap(Map<String, dynamic> map) {
    return ReadingClub(
      clubId: map['club_id'] as int?,
      bookId: map['book_id'] as int,
      clubName: map['club_name'] as String,
      targetDate: map['target_date'] as String?,
      readingProgress: map['reading_progress'] is int
          ? map['reading_progress'] as int
          : int.tryParse(map['reading_progress']?.toString() ?? '0') ?? 0,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'club_id': clubId,
      'book_id': bookId,
      'club_name': clubName,
      'target_date': targetDate,
      'reading_progress': readingProgress,
      'created_at': createdAt,
    };
  }

  @override
  String toString() {
    return 'ReadingClub(clubId: $clubId, bookId: $bookId, clubName: $clubName, targetDate: $targetDate, readingProgress: $readingProgress, createdAt: $createdAt)';
  }
}
