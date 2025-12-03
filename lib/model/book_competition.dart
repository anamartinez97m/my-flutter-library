class BookCompetition {
  final int? competitionId;
  final int year;
  final String competitionType; // 'monthly', 'quarterly', 'semifinal', 'final'
  final int? month; // 1-12 for monthly competitions
  final int? quarter; // 1-4 for quarterly competitions
  final int? roundNumber; // 1, 2 for semifinals; 3 for final
  final int bookId;
  final String bookName;
  final int? opponentBookId;
  final String? opponentBookName;
  final int winnerBookId;
  final String? createdAt;

  BookCompetition({
    this.competitionId,
    required this.year,
    required this.competitionType,
    this.month,
    this.quarter,
    this.roundNumber,
    required this.bookId,
    required this.bookName,
    this.opponentBookId,
    this.opponentBookName,
    required this.winnerBookId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'competition_id': competitionId,
      'year': year,
      'competition_type': competitionType,
      'month': month,
      'quarter': quarter,
      'round_number': roundNumber,
      'book_id': bookId,
      'book_name': bookName,
      'opponent_book_id': opponentBookId,
      'opponent_book_name': opponentBookName,
      'winner_book_id': winnerBookId,
      'created_at': createdAt,
    };
  }

  factory BookCompetition.fromMap(Map<String, dynamic> map) {
    return BookCompetition(
      competitionId: map['competition_id'] as int?,
      year: map['year'] as int,
      competitionType: map['competition_type'] as String,
      month: map['month'] as int?,
      quarter: map['quarter'] as int?,
      roundNumber: map['round_number'] as int?,
      bookId: map['book_id'] as int,
      bookName: map['book_name'] as String,
      opponentBookId: map['opponent_book_id'] as int?,
      opponentBookName: map['opponent_book_name'] as String?,
      winnerBookId: map['winner_book_id'] as int,
      createdAt: map['created_at'] as String?,
    );
  }

  BookCompetition copyWith({
    int? competitionId,
    int? year,
    String? competitionType,
    int? month,
    int? quarter,
    int? roundNumber,
    int? bookId,
    String? bookName,
    int? opponentBookId,
    String? opponentBookName,
    int? winnerBookId,
    String? createdAt,
  }) {
    return BookCompetition(
      competitionId: competitionId ?? this.competitionId,
      year: year ?? this.year,
      competitionType: competitionType ?? this.competitionType,
      month: month ?? this.month,
      quarter: quarter ?? this.quarter,
      roundNumber: roundNumber ?? this.roundNumber,
      bookId: bookId ?? this.bookId,
      bookName: bookName ?? this.bookName,
      opponentBookId: opponentBookId ?? this.opponentBookId,
      opponentBookName: opponentBookName ?? this.opponentBookName,
      winnerBookId: winnerBookId ?? this.winnerBookId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CompetitionResult {
  final int year;
  final List<MonthlyWinner> monthlyWinners;
  final List<QuarterlyWinner> quarterlyWinners;
  final List<SemifinalWinner> semifinalWinners;
  final BookCompetition? yearlyWinner;

  CompetitionResult({
    required this.year,
    required this.monthlyWinners,
    required this.quarterlyWinners,
    required this.semifinalWinners,
    this.yearlyWinner,
  });
}

class MonthlyWinner {
  final int month;
  final BookCompetition winner;

  MonthlyWinner({
    required this.month,
    required this.winner,
  });
}

class QuarterlyWinner {
  final int quarter;
  final BookCompetition winner;

  QuarterlyWinner({
    required this.quarter,
    required this.winner,
  });
}

class SemifinalWinner {
  final int roundNumber;
  final BookCompetition winner;

  SemifinalWinner({
    required this.roundNumber,
    required this.winner,
  });
}
