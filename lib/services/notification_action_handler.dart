// Handles snooze and done actions from notifications

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:reminder_app/services/reminder_service.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart';
import '../utils/reminder_utils.dart' as ReminderUtils;
import 'notification_helper.dart';
import 'notification_service.dart';

Future<void> handleNotificationAction(String actionId, String payload) async {
  final parts = payload.split('|');
  if (parts.length < 3) return;

  final reminderId = parts[0];
  final title = parts[1];
  final description = parts[2];

  final reminderDoc = await FirebaseFirestore.instance.collection('reminders').doc(reminderId).get();
  if (!reminderDoc.exists) return;
  final reminder = Reminder.fromFirestore(reminderDoc);

  if (actionId == 'done') {
    // Cancel current notification
    await flutterLocalNotificationsPlugin.cancel(reminder.notification_id);

    // Schedule next occurrence if it's a repeat reminder
    if (reminder.repeatType != 'once') {
      final nextTime = ReminderUtils.getNextOccurrence(reminder);
      if (nextTime != null) {
        reminder.scheduledTime = nextTime;
      }
      await NotificationService().scheduleNotification(reminder);
    }
  } else if (actionId == 'snooze') {
    // Cancel current notification
    await flutterLocalNotificationsPlugin.cancel(reminder.notification_id);

    final snoozedTime = DateTime.now().add(const Duration(minutes: 10));
    await flutterLocalNotificationsPlugin.zonedSchedule(
      reminder.notification_id,
      'Snoozed: $title',
      description,
      tz.TZDateTime.from(snoozedTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel_darahaas_v3',
          'Reminders',
          channelDescription: 'Channel for scheduled reminders',
          importance: Importance.high,
          priority: Priority.high,
          fullScreenIntent: true,
          timeoutAfter: 60000,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_ringtone'),
          showWhen: true,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('done', 'Done', showsUserInterface: true),
            AndroidNotificationAction('snooze', 'Snooze', showsUserInterface: true),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }
}

@pragma('vm:entry-point')
Future<void> onDidReceiveNotificationResponse(NotificationResponse response) async {

  final parts = (response.payload ?? '').split('|');
  if (parts.length < 1) return;
  final reminderId = parts[0];
  final isSnooze = response.actionId == 'snooze'; // better than relying on payload

  if (response.actionId == 'done') {
    await handleDoneAction(reminderId);
  } else if (response.actionId == 'snooze') {
    await handleSnoozeAction(reminderId);
  } /*else if (!isSnooze) {
    await maybeSendEmail(reminderId);
  }*/
}

Future<void> handleDoneAction(String reminderId) async {
  final reminder = await fetchReminderById(reminderId);

  // Optionally cancel current notification
  await flutterLocalNotificationsPlugin.cancel(reminder!.notification_id);

  if (reminder.repeatType != 'once') {
    final nextDate = ReminderUtils.getNextOccurrence(reminder);
    NotificationService().scheduleNotification(reminder.copyWith(scheduledTime: nextDate));
  }

}

Future<void> handleSnoozeAction(String reminderId) async {
  final reminder = await fetchReminderById(reminderId);
  final snoozedDate = DateTime.now().add(const Duration(minutes: 1));
  NotificationService().scheduleNotification(
    reminder!.copyWith(scheduledTime: snoozedDate),
  );
}


