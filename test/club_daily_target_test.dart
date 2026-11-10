import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/utils/club_daily_target.dart';

void main() {
  final today = DateTime(2026, 11, 10, 18, 30);

  test('no target date gives no daily goal', () {
    expect(
      ClubDailyTarget.compute(
        targetDate: null,
        readingProgress: 10,
        progressType: 'pages',
        pages: 300,
        now: today,
      ),
      isNull,
    );
  });

  test('pages progress: remaining pages split over days left incl. today', () {
    final t =
        ClubDailyTarget.compute(
          targetDate: '2026-12-04',
          readingProgress: 50,
          progressType: 'pages',
          pages: 300,
          now: today,
        )!;
    expect(t.daysLeft, 25);
    expect(t.pagesPerDay, 10);
    expect(t.percentPerDay, closeTo(3.4, 1e-9));
  });

  test('percentage progress with page count', () {
    final t =
        ClubDailyTarget.compute(
          targetDate: '2026-12-04',
          readingProgress: 25,
          progressType: 'percentage',
          pages: 400,
          now: today,
        )!;
    expect(t.pagesPerDay, 12);
    expect(t.percentPerDay, closeTo(3.0, 1e-9));
  });

  test('without page count only the percentage is given', () {
    final t =
        ClubDailyTarget.compute(
          targetDate: '2026-11-14',
          readingProgress: null,
          progressType: null,
          pages: null,
          now: today,
        )!;
    expect(t.daysLeft, 5);
    expect(t.pagesPerDay, isNull);
    expect(t.percentPerDay, closeTo(20, 1e-9));
  });

  test('target today means everything left is for today', () {
    final t =
        ClubDailyTarget.compute(
          targetDate: '2026-11-10',
          readingProgress: 280,
          progressType: 'pages',
          pages: 300,
          now: today,
        )!;
    expect(t.daysLeft, 1);
    expect(t.pagesPerDay, 20);
  });

  test('past target is overdue, finished book is finished', () {
    expect(
      ClubDailyTarget.compute(
        targetDate: '2026-11-09',
        readingProgress: 10,
        progressType: 'pages',
        pages: 300,
        now: today,
      )!.overdue,
      isTrue,
    );
    expect(
      ClubDailyTarget.compute(
        targetDate: '2026-11-09',
        readingProgress: 300,
        progressType: 'pages',
        pages: 300,
        now: today,
      )!.finished,
      isTrue,
    );
    expect(
      ClubDailyTarget.compute(
        targetDate: '2026-12-04',
        readingProgress: null,
        progressType: null,
        pages: 300,
        isRead: true,
        now: today,
      )!.finished,
      isTrue,
    );
  });
}
