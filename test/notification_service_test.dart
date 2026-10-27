import 'package:flutter_test/flutter_test.dart';
import 'package:myrandomlibrary/services/notification_service.dart';

void main() {
  group('championship reminder date', () {
    test('uses the upcoming first day of the month', () {
      final result = NotificationService.nextChampionshipReminderDate(
        now: DateTime(2026, 9, 21, 12),
        hour: 18,
        minute: 30,
      );

      expect(result, DateTime(2026, 10, 1, 18, 30));
    });

    test('uses today when the first-day reminder time is still ahead', () {
      final result = NotificationService.nextChampionshipReminderDate(
        now: DateTime(2026, 10, 1, 12),
        hour: 18,
        minute: 30,
      );

      expect(result, DateTime(2026, 10, 1, 18, 30));
    });

    test('moves to next month when the reminder time has passed', () {
      final result = NotificationService.nextChampionshipReminderDate(
        now: DateTime(2026, 12, 1, 18, 30),
        hour: 18,
        minute: 30,
      );

      expect(result, DateTime(2027, 1, 1, 18, 30));
    });
  });

  group('reading reminder dates', () {
    test('includes today when not read yet and time is ahead', () {
      final dates = NotificationService.readingReminderDates(
        now: DateTime(2026, 10, 26, 12),
        hour: 21,
        minute: 0,
        readToday: false,
        days: 3,
      );

      expect(dates, [
        DateTime(2026, 10, 26, 21),
        DateTime(2026, 10, 27, 21),
        DateTime(2026, 10, 28, 21),
      ]);
    });

    test('skips today when the book was already read today', () {
      final dates = NotificationService.readingReminderDates(
        now: DateTime(2026, 10, 26, 12),
        hour: 21,
        minute: 0,
        readToday: true,
        days: 3,
      );

      expect(dates, [DateTime(2026, 10, 27, 21), DateTime(2026, 10, 28, 21)]);
    });

    test('skips today when the reminder time has passed', () {
      final dates = NotificationService.readingReminderDates(
        now: DateTime(2026, 10, 26, 21),
        hour: 21,
        minute: 0,
        readToday: false,
        days: 2,
      );

      expect(dates, [DateTime(2026, 10, 27, 21)]);
    });

    test('rolls over month and year boundaries', () {
      final dates = NotificationService.readingReminderDates(
        now: DateTime(2026, 12, 31, 22),
        hour: 21,
        minute: 30,
        readToday: false,
        days: 3,
      );

      expect(dates, [
        DateTime(2027, 1, 1, 21, 30),
        DateTime(2027, 1, 2, 21, 30),
      ]);
    });
  });
}
