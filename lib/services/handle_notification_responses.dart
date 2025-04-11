import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';
import '../screens/view_reminders_screen.dart';
import 'notification_helper.dart';

Future<void> handleSnooze(String? payload) async {
  if (payload == null || !payload.contains('|')) {
    debugPrint("❌ Invalid snooze payload");
    return;
  }

  final parts = payload.split('|');
  if (parts.length < 4) {
    debugPrint("❌ Payload format incorrect: $payload");
    return;
  }

  final notificationId = int.tryParse(parts[0]);
  final reminderId = parts[1];
  final title = parts[2];
  final description = parts[3];

  if (notificationId == null) {
    debugPrint("❌ Invalid notification ID in payload");
    return;
  }

  final snoozedTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));

  await flutterLocalNotificationsPlugin.zonedSchedule(
    notificationId,
    title,
    description,
    snoozedTime,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_channel_darahaas_v3',
        'Reminders',
        channelDescription: 'Channel for reminders',
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('notification_ringtone'),
        autoCancel: false,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('snooze_action_$notificationId', 'Snooze', showsUserInterface: true),
          AndroidNotificationAction('done_action_$notificationId', 'Done', showsUserInterface: true),
        ],
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
    payload: '$notificationId|$reminderId|$title|$description',
  );

  debugPrint("🔁 Snoozed reminder (ID: $notificationId) for 1 minute later.");
}

Future<void> handleDone(String? payload, {bool fromNotificationTap = false}) async {
  if (payload == null || !payload.contains('|')) return;

  final parts = payload.split('|');
  final notificationId = int.tryParse(parts[0]);
  final reminderId = parts[1];

  if (notificationId != null) {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    debugPrint("✅ Done: cancelled reminder with ID $notificationId");
  }

  if (fromNotificationTap) {
    // Navigate to the reminder inside the app
    navigatorKey.currentState?.pushNamed(
      '/viewReminder',
      arguments: reminderId,
    );
  }
}

void handleNotificationTap(String? payload) {
  if (payload == null) return;

  final parts = payload.split('|');
  if (parts.length < 2) return;

  final reminderId = parts[1];

  // Use navigatorKey from your main app
  navigatorKey.currentState?.push(
    MaterialPageRoute(
//      builder: (_) => ViewRemindersScreen(reminderId: reminderId), ToDo Open Specific reminder
      builder: (_) => ViewRemindersScreen(),
    ),
  );
}





