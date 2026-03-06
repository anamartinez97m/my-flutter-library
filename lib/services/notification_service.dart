import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myrandomlibrary/db/database_helper.dart';
import 'package:myrandomlibrary/repositories/book_repository.dart';
import 'package:myrandomlibrary/repositories/reading_session_repository.dart';
import 'package:myrandomlibrary/screens/book_detail.dart';

/// Top-level function required for background notification action handling.
/// Must be a top-level or static function.
@pragma('vm:entry-point')
void _onBackgroundNotificationAction(NotificationResponse response) {
  debugPrint(
    '📖 Background notification action: ${response.actionId}, payload: ${response.payload}',
  );

  if (response.payload != null &&
      response.payload!.startsWith('reading_reminder_')) {
    final match = RegExp(
      r'reading_reminder_(\d+)',
    ).firstMatch(response.payload!);
    if (match == null) return;

    final bookId = int.tryParse(match.group(1)!);
    if (bookId == null) return;

    if (response.actionId == 'yes') {
      // Use async without await since this is a void callback
      () async {
        try {
          final db = await DatabaseHelper.instance.database;
          final sessionRepository = ReadingSessionRepository(db);
          await sessionRepository.createDidReadSession(bookId, true);
          debugPrint('📖 Background: marked book $bookId as read today');
          // Cancel the notification after updating the DB
          final notificationId = 100000 + bookId;
          await FlutterLocalNotificationsPlugin().cancel(notificationId);
        } catch (e) {
          debugPrint('❌ Background error handling reading reminder action: $e');
        }
      }();
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification ID range for reading reminders: 100000 + bookId
  static const int _readingReminderBaseId = 100000;

  // SharedPreferences keys
  static const String prefReadingReminderEnabled = 'reading_reminder_enabled';
  static const String prefReadingReminderHour = 'reading_reminder_hour';
  static const String prefReadingReminderMinute = 'reading_reminder_minute';
  static const String prefReadingReminderAllBooks =
      'reading_reminder_all_books';

  /// Global navigator key used to navigate from notification taps
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Set the local timezone to the device's timezone
    // This is crucial for scheduled notifications to fire at the correct time
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('✅ Timezone set to: $timeZoneName');
    } catch (e) {
      // Fallback to UTC if timezone name is not recognized
      debugPrint('⚠️ Could not set timezone $timeZoneName, using UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationAction,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
      'Notification tapped: ${response.payload}, actionId: ${response.actionId}',
    );

    // Handle reading reminder Yes/No actions
    if (response.payload != null &&
        response.payload!.startsWith('reading_reminder_')) {
      _handleReadingReminderAction(response.payload!, response.actionId);
      return;
    }

    _navigateToBookFromPayload(response.payload);
  }

  /// Handle Yes/No actions from reading reminder notifications
  Future<void> _handleReadingReminderAction(
    String payload,
    String? actionId,
  ) async {
    final match = RegExp(r'reading_reminder_(\d+)').firstMatch(payload);
    if (match == null) return;

    final bookId = int.tryParse(match.group(1)!);
    if (bookId == null) return;

    if (actionId == 'yes') {
      try {
        final db = await DatabaseHelper.instance.database;
        final sessionRepository = ReadingSessionRepository(db);
        await sessionRepository.createDidReadSession(bookId, true);
        debugPrint('📖 Reading reminder: marked book $bookId as read today');
        // Cancel the notification after updating the DB
        final notificationId = _readingReminderBaseId + bookId;
        await _notifications.cancel(notificationId);
      } catch (e) {
        debugPrint('❌ Error handling reading reminder action: $e');
      }
    } else {
      // Tapped on the notification body → navigate to book detail
      _navigateToBookFromPayload('book_release_$bookId');
    }
  }

  Future<void> _navigateToBookFromPayload(String? payload) async {
    if (payload == null) return;

    // Extract book ID from payload (format: 'book_release_<bookId>')
    final match = RegExp(r'book_release_(\d+)').firstMatch(payload);
    if (match == null) return;

    final bookId = int.tryParse(match.group(1)!);
    if (bookId == null) return;

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final book = await repository.getBookById(bookId);
      if (book == null) {
        debugPrint('⚠️ Book not found for notification tap: $bookId');
        return;
      }

      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.push(
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      } else {
        debugPrint('⚠️ Navigator not available for notification tap');
      }
    } catch (e) {
      debugPrint('❌ Error navigating to book from notification: $e');
    }
  }

  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    // Request permissions for iOS
    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }

    // Request permissions for Android 13+
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  /// Request exact alarm permissions for Android 12+ (API 31+)
  /// This is required for scheduling notifications at exact times
  Future<bool> requestExactAlarmPermission() async {
    try {
      // Check if we're on Android 12+ where exact alarms need permission
      final status = await Permission.scheduleExactAlarm.status;

      if (status.isGranted) {
        debugPrint('✅ Exact alarm permission already granted');
        return true;
      }

      if (status.isDenied) {
        // Request the permission
        final result = await Permission.scheduleExactAlarm.request();
        debugPrint('🔔 Exact alarm permission request result: $result');
        return result.isGranted;
      }

      // If permanently denied, we can't request again
      // User needs to go to settings manually
      if (status.isPermanentlyDenied) {
        debugPrint('⚠️ Exact alarm permission permanently denied');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error requesting exact alarm permission: $e');
      return false;
    }
  }

  Future<void> scheduleBookReleaseNotification({
    required int bookId,
    required String bookTitle,
    required DateTime scheduledDate,
    DateTime? releaseDate,
  }) async {
    if (!_initialized) await initialize();

    // Convert to TZDateTime with local timezone
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // Calculate days remaining until release (compare calendar dates, not datetimes)
    String notificationBody;
    if (releaseDate != null) {
      final releaseDateOnly = DateTime(
        releaseDate.year,
        releaseDate.month,
        releaseDate.day,
      );
      final scheduledDateOnly = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
      );
      final daysRemaining =
          releaseDateOnly.difference(scheduledDateOnly).inDays;
      if (daysRemaining == 0) {
        notificationBody = '$bookTitle is being released today!';
      } else if (daysRemaining == 1) {
        notificationBody = '$bookTitle will be released tomorrow!';
      } else if (daysRemaining > 1) {
        notificationBody =
            '$bookTitle will be released in $daysRemaining days!';
      } else {
        // Release date is in the past (shouldn't happen, but handle it)
        notificationBody = '$bookTitle has been released!';
      }
    } else {
      // Fallback if no release date provided
      notificationBody = '$bookTitle is being released today!';
    }

    // Debug logging
    debugPrint('📅 Scheduling notification for book: $bookTitle (ID: $bookId)');
    debugPrint('📅 Input DateTime: $scheduledDate');
    debugPrint('📅 Release Date: $releaseDate');
    debugPrint('📅 TZDateTime: $tzScheduledDate');
    debugPrint('📅 Current time: ${DateTime.now()}');
    debugPrint('📅 Current TZ time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('📅 Timezone: ${tz.local.name}');
    debugPrint(
      '📅 Is in future: ${tzScheduledDate.isAfter(tz.TZDateTime.now(tz.local))}',
    );
    debugPrint('📅 Notification body: $notificationBody');

    const androidDetails = AndroidNotificationDetails(
      'book_releases',
      'Book Releases',
      channelDescription: 'Notifications for upcoming book releases',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Request exact alarm permission first
    final hasExactAlarmPermission = await requestExactAlarmPermission();
    debugPrint('📅 Exact alarm permission: $hasExactAlarmPermission');

    try {
      // Try with exact timing if permission granted
      if (hasExactAlarmPermission) {
        await _notifications.zonedSchedule(
          bookId, // Use bookId as notification ID
          'Book Release Reminder',
          notificationBody,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'book_release_$bookId',
        );
        debugPrint('✅ Notification scheduled with exact timing');
      } else {
        // Use inexact timing if permission not granted
        await _notifications.zonedSchedule(
          bookId,
          'Book Release Reminder',
          notificationBody,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'book_release_$bookId',
        );
        debugPrint(
          '⚠️ Notification scheduled with inexact timing (permission not granted)',
        );
      }

      // Verify the notification was scheduled
      final pendingNotifications =
          await _notifications.pendingNotificationRequests();
      final thisNotification = pendingNotifications.where(
        (n) => n.id == bookId,
      );
      if (thisNotification.isNotEmpty) {
        debugPrint('✅ Verified: Notification is in pending list');
      } else {
        debugPrint('⚠️ Warning: Notification not found in pending list');
      }
      debugPrint(
        '📅 Total pending notifications: ${pendingNotifications.length}',
      );
    } catch (e) {
      // If exact alarms still fail, fall back to inexact timing
      debugPrint('❌ Error scheduling notification: $e');
      await _notifications.zonedSchedule(
        bookId,
        'Book Release Reminder',
        notificationBody,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'book_release_$bookId',
      );
    }
  }

  Future<void> cancelNotification(int bookId) async {
    if (!_initialized) await initialize();
    await _notifications.cancel(bookId);
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_initialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  // ===== READING REMINDER METHODS =====

  /// Schedule daily reading reminder notifications for started books
  Future<void> scheduleReadingReminders() async {
    if (!_initialized) await initialize();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(prefReadingReminderEnabled) ?? false;

    // Cancel all existing reading reminders first
    await cancelAllReadingReminders();

    if (!enabled) {
      debugPrint('📖 Reading reminders disabled, all canceled');
      return;
    }

    final hour = prefs.getInt(prefReadingReminderHour) ?? 21;
    final minute = prefs.getInt(prefReadingReminderMinute) ?? 0;
    final allBooks = prefs.getBool(prefReadingReminderAllBooks) ?? true;

    try {
      final db = await DatabaseHelper.instance.database;
      final repository = BookRepository(db);
      final startedBooks = await repository.getStartedBooks();

      if (startedBooks.isEmpty) {
        debugPrint('📖 No started books found for reading reminders');
        return;
      }

      final booksToRemind = allBooks ? startedBooks : [startedBooks.first];

      for (final book in booksToRemind) {
        if (book.bookId == null) continue;
        await _scheduleDailyReadingReminder(
          bookId: book.bookId!,
          bookTitle: book.name ?? 'Unknown',
          hour: hour,
          minute: minute,
        );
      }

      debugPrint(
        '📖 Scheduled reading reminders for ${booksToRemind.length} book(s) at $hour:${minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling reading reminders: $e');
    }
  }

  /// Schedule a single daily reading reminder for a specific book
  Future<void> _scheduleDailyReadingReminder({
    required int bookId,
    required String bookTitle,
    required int hour,
    required int minute,
  }) async {
    final notificationId = _readingReminderBaseId + bookId;

    // Calculate next occurrence of the specified time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'reading_reminders',
      'Reading Reminders',
      channelDescription: 'Daily reminders to track your reading progress',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'yes',
          'Yes',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final hasExactAlarmPermission = await requestExactAlarmPermission();

    try {
      await _notifications.zonedSchedule(
        notificationId,
        'Have you read today?: $bookTitle',
        'Tap to open book details',
        scheduledDate,
        notificationDetails,
        androidScheduleMode:
            hasExactAlarmPermission
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reading_reminder_$bookId',
      );
      debugPrint(
        '📖 Scheduled daily reminder for "$bookTitle" (ID: $bookId) at $hour:${minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling reading reminder for book $bookId: $e');
    }
  }

  /// Cancel all reading reminder notifications
  Future<void> cancelAllReadingReminders() async {
    if (!_initialized) await initialize();

    final pendingNotifications =
        await _notifications.pendingNotificationRequests();
    for (final notification in pendingNotifications) {
      if (notification.payload != null &&
          notification.payload!.startsWith('reading_reminder_')) {
        await _notifications.cancel(notification.id);
      }
    }
    debugPrint('📖 Canceled all reading reminder notifications');
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'general',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
