import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';
import '../screens/show_reminder.dart';
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

  final snoozedTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));

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
          AndroidNotificationAction('view_action_$notificationId', 'View', showsUserInterface: true),
        ],
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
    payload: '$notificationId|$reminderId|$title|$description',
  );

  debugPrint("🔁 Snoozed reminder (ID: $notificationId) for 10 minutes later.");
}

Future<void> handleView(String? payload, {bool fromNotificationTap = false}) async {
  if (payload == null || !payload.contains('|')) return;

  final parts = payload.split('|');
  if (parts.length < 2) return;
  final reminderId = parts[1];
    // Navigate to the reminder inside the app
    navigatorKey.currentState?.pushNamed(
      '/reminder-detail',
      arguments: reminderId,
    );
}

Future<void> handleNotificationTap(String? payload) async {
  if (payload == null || !payload.contains('|')) return;

  final parts = payload.split('|');
  if (parts.length < 2) return;
  final reminderId = parts[1];

  // Navigate to the reminder inside the app
  navigatorKey.currentState?.pushNamed(
    '/reminder-detail',
    arguments: reminderId,
  );
}





