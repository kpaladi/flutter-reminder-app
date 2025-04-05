import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_helper.dart';

Future<void> handleSnooze(String? payload) async {
  List<String>? parts = payload?.split('|'); // Null-aware split

  int? id;
  String? title;
  String? description;

  if (parts != null && parts.length >= 3) {
    id = int.parse(parts[0]);
    title = parts[1];
    description = parts[2];

    if (!title.startsWith('Snooze - ')) {
      //Check for existing prefix.
      title = 'Snooze - $title';
      parts[1] = title;
    }

    payload = parts.join('|'); // Reconstruct payload
  } else {
    //handle null payload, or parts.
    id = null;
    title = null;
    description = null;
    payload = null;
  }

  // Set snooze duration (e.g., 5 minutes later)
  DateTime snoozeTime = DateTime.now().add(Duration(minutes: 1));
  tz.TZDateTime tzSnoozeTime = tz.TZDateTime.from(snoozeTime, tz.local);

  debugPrint("⏳ Snoozing notification ID $id for 5 minutes...");

  // Directly schedule the snoozed notification
  try {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id!,
      title,
      description,
      tzSnoozeTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel_darahaas',
          'Reminders',
          channelDescription: 'Channel for scheduled reminders',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'snooze_action_$id',
              'tap to snooze further',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: payload,
    );

    debugPrint("✅ Snooze notification scheduled for $snoozeTime");
  } catch (e) {
    debugPrint("❌ Error snoozing notification: $e");
  }
}
