import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import './work_data_service.dart';

// ─── Background handler (top-level, vm:entry-point) ──────────────────────────
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  _handleNotificationAction(response);
}

void _handleNotificationAction(NotificationResponse response) {
  final actionId = response.actionId;
  if (actionId == 'YES' || actionId == 'NO') {
    _recordWorkDayFromNotification(actionId == 'YES');
  }
}

/// Records a work day from a notification action.
/// Uses a date-only key to prevent duplicate entries.
Future<void> _recordWorkDayFromNotification(bool worked) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final service = WorkDataService();
    final settings = await service.loadSettings();

    final now = DateTime.now();
    final todayKey = 'notif_recorded_${now.year}_${now.month}_${now.day}';
    final todayWorkedKey = 'notif_worked_${now.year}_${now.month}_${now.day}';

    // Check if already recorded with the SAME status — skip duplicate
    if (prefs.getBool(todayKey) == true) {
      final prevWorked = prefs.getBool(todayWorkedKey);
      if (prevWorked == worked) {
        return; // Exact duplicate — skip
      }
      // Different status (YES after NO or NO after YES) — allow overwrite
    }

    await service.recordWorkDay(now, worked, settings.dailyWage);
    await prefs.setBool(todayKey, true);
    await prefs.setBool(todayWorkedKey, worked);
  } catch (_) {}
}

// ─── NotificationService ─────────────────────────────────────────────────────

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyNotificationId = 1001;
  static const String _channelId = 'workpay_daily_v4';
  static const String _channelName = 'სამუშაო დღის შეხსენება';
  static const String _channelDesc = 'ყოველდღიური შეხსენება — იმუშავე დღეს?';

  // Method channel for native full-screen intent scheduling
  static const MethodChannel _channel = MethodChannel(
    'com.example.workpaytracker/fullscreen',
  );

  bool _initialized = false;

  /// Initialize the plugin. Call once from main().
  Future<void> initialize({
    void Function(NotificationResponse)? onForegroundAction,
  }) async {
    if (_initialized) return;

    tz.initializeTimeZones();
    _setLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationAction(response);
        onForegroundAction?.call(response);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _initialized = true;
  }

  void _setLocalTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      final offsetHours = offset.inHours;
      final etcSign = offsetHours >= 0 ? '-' : '+';
      final tzName = 'Etc/GMT$etcSign${offsetHours.abs()}';
      try {
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// Request Android notification permission (Android 13+).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Request exact alarm permission (Android 12+).
  Future<void> requestExactAlarmPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Check if USE_FULL_SCREEN_INTENT permission is granted (Android 14+).
  Future<bool> checkFullScreenIntentPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return false;
    try {
      final canUse = await androidPlugin.canScheduleExactNotifications();
      return canUse ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Schedule (or reschedule) the daily notification at [hour]:[minute].
  /// Uses maximum importance + fullScreenIntent pointing to WorkConfirmActivity.
  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    await _plugin.cancel(_dailyNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Build the Android notification details with full-screen intent
    // The fullScreenIntent: true causes Android to launch WorkConfirmActivity
    // via the PendingIntent set in the notification channel
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      autoCancel: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      channelShowBadge: true,
      ongoing: false,
      styleInformation: const BigTextStyleInformation(
        'დააჭირე დიახ ან არა, რომ სამუშაო დღე დაფიქსირდეს.',
        contentTitle: 'ხელფასის მენეჯერი',
        summaryText: 'სამუშაო დღის შეხსენება',
        htmlFormatBigText: false,
        htmlFormatContentTitle: false,
      ),
      // Fallback action buttons when full-screen is blocked
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'YES',
          '✓  დიახ, ვიმუშავე',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'NO',
          '✗  არა, არ მიმუშავია',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      _dailyNotificationId,
      'ხელფასის მენეჯერი',
      'იმუშავე დღეს?',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_hour', hour);
    await prefs.setInt('notif_minute', minute);
  }

  /// Cancel the daily notification.
  Future<void> cancelDailyNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(_dailyNotificationId);
  }

  /// Restore scheduled notification after app restart.
  Future<void> restoreScheduledNotification() async {
    if (kIsWeb) return;
    try {
      final service = WorkDataService();
      final settings = await service.loadSettings();
      if (!settings.notificationsEnabled) return;

      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('notif_hour') ?? settings.reminderHour;
      final minute = prefs.getInt('notif_minute') ?? settings.reminderMinute;
      await scheduleDailyNotification(hour: hour, minute: minute);
    } catch (_) {}
  }
}
