class TandemChapter {
  final int? tandemChapterId;
  final int tandemId;
  final int bookId;
  final int startChapter;
  final int endChapter;
  final int orderIndex;
  final bool isRead;

  TandemChapter({
    this.tandemChapterId,
    required this.tandemId,
    required this.bookId,
    required this.startChapter,
    required this.endChapter,
    required this.orderIndex,
    this.isRead = false,
  });

  /// Display label: "Chapter 3" or "Chapters 3-5"
  String get displayLabel => startChapter == endChapter
      ? 'Chapter $startChapter'
      : 'Chapters $startChapter-$endChapter';

  /// Number of chapters in this entry
  int get chapterCount => endChapter - startChapter + 1;

  factory TandemChapter.fromMap(Map<String, dynamic> map) {
    return TandemChapter(
      tandemChapterId: map['tandem_chapter_id'] as int?,
      tandemId: map['tandem_id'] as int,
      bookId: map['book_id'] as int,
      startChapter: map['start_chapter'] as int,
      endChapter: map['end_chapter'] as int,
      orderIndex: map['order_index'] as int,
      isRead: map['is_read'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tandem_chapter_id': tandemChapterId,
      'tandem_id': tandemId,
      'book_id': bookId,
      'start_chapter': startChapter,
      'end_chapter': endChapter,
      'order_index': orderIndex,
      'is_read': isRead ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'TandemChapter(tandemChapterId: $tandemChapterId, tandemId: $tandemId, bookId: $bookId, startChapter: $startChapter, endChapter: $endChapter, orderIndex: $orderIndex, isRead: $isRead)';
  }
}
