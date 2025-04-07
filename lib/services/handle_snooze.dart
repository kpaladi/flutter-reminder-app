import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_helper.dart';

Future<void> handleSnooze(String? payload) async {
  if (payload == null || !payload.contains('|')) {
    debugPrint("❌ Invalid or missing payload for snooze.");
    return;
  }

  try {
    final parts = payload.split('|');
    if (parts.length < 3) {
      debugPrint("❌ Malformed payload: $payload");
      return;
    }

    final id = parts[0];
    String title = parts[1];
    final description = parts[2];

    // Prefix title to indicate it's a snoozed reminder
    if (!title.startsWith('Snooze - ')) {
      title = 'Snooze - $title';
    }

    final snoozeTime = DateTime.now().add(const Duration(minutes: 1));
    final tzSnoozeTime = tz.TZDateTime.from(snoozeTime, tz.local);
    final notifId = id.hashCode;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notifId,
      title,
      description,
      tzSnoozeTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel_darahaas_v3',
          'Reminders',
          channelDescription: 'Channel for scheduled reminders',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: false,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_ringtone'),
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'snooze_action_$notifId',
              'Tap to snooze again',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: '$id|$title|$description',
    );

    debugPrint("✅ Snoozed reminder for 1 min: $title ($notifId) at $snoozeTime");

  } catch (e) {
    debugPrint("❌ Error while handling snooze: $e");
  }
}

