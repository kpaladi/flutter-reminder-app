import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'handle_snooze.dart';
import 'notification_helper.dart';

Future<void> initializeNotifications([
  void Function(NotificationResponse)? onNotificationResponse,
]) async {
  try {
    debugPrint("🚀 Initializing Notifications...");

    // Setup for Android notifications
    const androidSettings = AndroidInitializationSettings('ic_notification');
    final initializationSettings = InitializationSettings(android: androidSettings);

    // Default action when notification is tapped
    final didReceiveResponse = onNotificationResponse ?? (NotificationResponse response) {
      final payload = response.payload;
      debugPrint("🔔 Notification clicked: $payload");

      final actionId = response.actionId;
      if (actionId != null && actionId.startsWith('snooze_action')) {
        handleSnooze(payload);
      }
    };

    final initSuccess = (await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: didReceiveResponse,
    )) ?? false;

    debugPrint("✅ Notifications initialized: $initSuccess");

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'reminder_channel_darahaas_v3',
      'Reminders',
      description: 'Channel for reminder notifications',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_ringtone'),
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      debugPrint("✅ Notification channel created");
    } else {
      debugPrint("⚠️ Android plugin not found, skipping channel creation");
    }

    // Set time zone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    debugPrint("✅ Time zones initialized");

  } catch (e, stackTrace) {
    debugPrint("❌ Error initializing notifications: $e");
    debugPrint("🪵 StackTrace: $stackTrace");
  }
}
