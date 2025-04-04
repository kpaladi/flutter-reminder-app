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

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('ic_notification');

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    final bool initSuccess =
        (await flutterLocalNotificationsPlugin.initialize(
          settings,
          onDidReceiveNotificationResponse: onNotificationResponse ??
                  (NotificationResponse response) {
                debugPrint("🔔 Notification clicked: ${response.payload}");
                if (response.actionId != null &&
                    response.actionId!.startsWith('snooze_action')) {
                  handleSnooze(response.payload);
                }
              },
        )) ??
            false;

    debugPrint("✅ Notifications initialized: $initSuccess");

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel_darahaas',
      'Reminders',
      description: 'Channel for reminder notifications',
      importance: Importance.high,
    );

    final androidPlugin =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
    >();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      debugPrint("✅ Notification channel created");
    } else {
      debugPrint("⚠️ Android plugin not found, skipping channel creation");
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    debugPrint("✅ Time zones initialized");
  } catch (e) {
    debugPrint("❌ Error initializing notifications: $e");
  }
}
