import 'dart:async';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/reminders/domain/reminder.dart';

/// Wraps [FlutterLocalNotificationsPlugin] for Peptilog injection reminders.
///
/// Call [initialize] once at app startup, after
/// [WidgetsFlutterBinding.ensureInitialized].
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  static final _tapController = StreamController<String>.broadcast();

  /// Emits a GoRouter route path whenever a notification is tapped.
  static Stream<String> get tapRoute => _tapController.stream;

  static const _channelId = 'peptilog_reminders';
  static const _channelName = 'Injection Reminders';
  static const _channelDesc = 'Daily peptide injection reminders';

  /// Initialises the plugin and returns the route payload if the app was
  /// cold-launched by a notification tap (terminated state). Returns `null`
  /// if the app was launched normally.
  static Future<String?> initialize() async {
    tz_data.initializeTimeZones();

    // Detect the device's local timezone and configure the tz package.
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      // Fall back to UTC if detection fails — better than crashing.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _tapController.add(response.payload ?? '/log/new');
      },
    );

    // Check if the app was launched from a terminated state by a notification.
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      return launchDetails!.notificationResponse?.payload ?? '/log/new';
    }
    return null;
  }

  /// Requests OS notification permission.
  /// Returns `true` if permission is granted (or was already granted).
  static Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (Platform.isAndroid) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Schedules one weekly notification per selected day in [reminder].
  ///
  /// Cancels any pre-existing notifications for the same [reminder] first.
  /// If [reminder.isActive] is false, only cancellation is performed.
  static Future<void> scheduleReminder(
    Reminder reminder,
    String peptideName,
  ) async {
    await cancelReminder(reminder.id);
    if (!reminder.isActive) return;

    final days = parseDays(reminder.daysOfWeek);
    if (days.isEmpty) return;

    final parts = reminder.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts.length > 1 ? int.parse(parts[1]) : 0;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    for (final day in days) {
      await _plugin.zonedSchedule(
        notifId(reminder.id, day),
        'Time to inject $peptideName',
        'Tap to log your injection',
        _nextInstanceOf(day, hour, minute),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '/log/new',
      );
    }
  }

  /// Cancels all notifications (one per weekday) associated with [reminderId].
  static Future<void> cancelReminder(int reminderId) async {
    for (int day = 1; day <= 7; day++) {
      await _plugin.cancel(notifId(reminderId, day));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses a comma-separated weekday string (e.g. "1,3,5") into a list
  /// of weekday ints (1=Mon … 7=Sun, matching [DateTime.weekday]).
  static List<int> parseDays(String daysOfWeek) {
    if (daysOfWeek.trim().isEmpty) return [];
    return daysOfWeek
        .split(',')
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  /// Builds a unique Android/iOS notification int ID from the reminder's
  /// Isar [id] and the target ISO [weekday] (1-7).
  static int notifId(int id, int weekday) => (id.abs() % 100000) * 10 + weekday;

  /// Returns the next [tz.TZDateTime] for the given ISO [weekday] (1=Mon),
  /// [hour], and [minute] in the device's local timezone.
  static tz.TZDateTime _nextInstanceOf(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var dt = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // Advance day-by-day until we land on the correct weekday in the future.
    while (dt.weekday != weekday || !dt.isAfter(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }
}
