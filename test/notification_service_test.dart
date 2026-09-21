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
}
