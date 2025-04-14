import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'handle_notification_responses.dart'; // Make sure this has handleDone, handleSnooze, handleNotificationTap
import 'notification_helper.dart'; // Should define flutterLocalNotificationsPlugin

Future<void> initializeNotifications([
  void Function(NotificationResponse)? onNotificationResponse,
]) async {
  try {
    debugPrint("🚀 Initializing Notifications...");

    // Android notification settings
    const androidSettings = AndroidInitializationSettings('ic_notification');
    final initializationSettings = InitializationSettings(android: androidSettings);

    // Default action handler
    final didReceiveResponse = onNotificationResponse ??
            (NotificationResponse response) async {
          final payload = response.payload;
          final actionId = response.actionId;
          debugPrint("🔔 Notification clicked: $payload | Action: $actionId");

          if (actionId != null) {
            if (actionId.startsWith('view_action_')) {
              await handleView(payload, fromNotificationTap: true);
            } else if (actionId.startsWith('snooze_action_')) {
              await handleSnooze(payload);
            }
          } else if (payload != null) {
            handleNotificationTap(payload);
          }
        };

    final initSuccess = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: didReceiveResponse,
    );

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
