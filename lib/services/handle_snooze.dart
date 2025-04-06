import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart';
import 'notification_helper.dart';

Future<void> handleSnooze(String? payload) async {
  Reminder? reminder;

  if (payload != null) {
    try {
      final parts = payload.split('|');
      if (parts.length >= 3) {
        final id = parts[0];
        String title = parts[1];
        final description = parts[2];

        // Add prefix if not already snoozed
        if (!title.startsWith('Snooze - ')) {
          title = 'Snooze - $title';
        }

        reminder = Reminder(
          id: id,
          title: title,
          description: description,
          timestamp: DateTime.now().add(const Duration(minutes: 1)),
        );

        payload = '${reminder.id}|${reminder.title}|${reminder.description}';
      }
    } catch (e) {
      debugPrint("❌ Failed to parse payload into Reminder: $e");
      return;
    }
  }

  if (reminder == null || reminder.timestamp == null) {
    debugPrint("❌ Reminder is null or timestamp missing, aborting snooze.");
    return;
  }

  final int notifId = int.tryParse(reminder.id) ?? DateTime.now().millisecondsSinceEpoch;
  final tz.TZDateTime snoozeTime = tz.TZDateTime.from(reminder.timestamp!, tz.local);

  debugPrint("⏳ Snoozing notification ID $notifId for 1 minute...");

  try {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notifId,
      reminder.title,
      reminder.description,
      snoozeTime,
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
      androidScheduleMode: AndroidScheduleMode.exact,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: payload,
    );

    debugPrint("✅ Snoozed notification scheduled for ${reminder.timestamp}");
  } catch (e) {
    debugPrint("❌ Error scheduling snoozed notification: $e");
  }
}
