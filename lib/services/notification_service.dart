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
    DateTime? releaseDate,
  }) async {
    if (!_initialized) await initialize();

    // Convert to TZDateTime with local timezone
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    
    // Calculate days remaining until release
    String notificationBody;
    if (releaseDate != null) {
      final daysRemaining = releaseDate.difference(scheduledDate).inDays;
      if (daysRemaining == 0) {
        notificationBody = '$bookTitle is being released today!';
      } else if (daysRemaining == 1) {
        notificationBody = '$bookTitle will be released tomorrow!';
      } else if (daysRemaining > 1) {
        notificationBody = '$bookTitle will be released in $daysRemaining days!';
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
    debugPrint('📅 Is in future: ${tzScheduledDate.isAfter(tz.TZDateTime.now(tz.local))}');
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
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      final thisNotification = pendingNotifications.where((n) => n.id == bookId);
      if (thisNotification.isNotEmpty) {
        debugPrint('✅ Verified: Notification is in pending list');
      } else {
        debugPrint('⚠️ Warning: Notification not found in pending list');
      }
      debugPrint('📅 Total pending notifications: ${pendingNotifications.length}');
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
