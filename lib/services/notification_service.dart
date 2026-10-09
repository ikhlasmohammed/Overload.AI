import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications - every notification the
/// app shows goes through here, same wrapper pattern as AuthService,
/// WorkoutLogService, etc.
///
/// SCOPE: immediate notifications only (.show()), used by the Rest Timer
/// the moment its countdown reaches zero. Scheduling a notification for an
/// arbitrary future date/time (needed for the Schedule Workout form's
/// "Set Reminder" toggle) is a different API - zonedSchedule() - which
/// additionally needs the timezone package plus extra Android manifest
/// permissions for exact alarms. That's a deliberate, separate follow-up
/// once this simpler path is confirmed working on a real device.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _restTimerChannelId = 'rest_timer_channel';

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Fires immediately - called the moment the Rest Timer countdown hits
  /// zero (see ActiveSessionNotifier.showRestTimer()).
  Future<void> showRestOverNotification() async {
    const androidDetails = AndroidNotificationDetails(
      _restTimerChannelId,
      'Rest Timer',
      channelDescription: "Alerts when your rest period between sets ends",
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: 0,
      title: 'Rest complete',
      body: "Time's up, back to it!",
      notificationDetails: details,
    );
    // Belt-and-suspenders: fire an immediate haptic buzz directly too. A
    // notification channel's own vibration can be inconsistent while the
    // app is open and in the foreground on some Android skins, and
    // HapticFeedback needs no extra package or permission.
    HapticFeedback.vibrate();
  }
}
