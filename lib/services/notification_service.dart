import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

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
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to specific screen based on payload
    debugPrint('Notification tapped: ${response.payload}');
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
  }) async {
    if (!_initialized) await initialize();

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

    try {
      // Try with exact timing if permission granted
      if (hasExactAlarmPermission) {
        await _notifications.zonedSchedule(
          bookId, // Use bookId as notification ID
          'Book Release Reminder',
          '$bookTitle is being released today!',
          tz.TZDateTime.from(scheduledDate, tz.local),
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
          '$bookTitle is being released today!',
          tz.TZDateTime.from(scheduledDate, tz.local),
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
    } catch (e) {
      // If exact alarms still fail, fall back to inexact timing
      debugPrint('⚠️ Exact alarms failed, using inexact timing: $e');
      await _notifications.zonedSchedule(
        bookId,
        'Book Release Reminder',
        '$bookTitle is being released today!',
        tz.TZDateTime.from(scheduledDate, tz.local),
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
