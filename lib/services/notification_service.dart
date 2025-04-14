import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart'; // ✅ Import updated Reminder model
import 'notification_helper.dart';

class NotificationService {
  NotificationService();

  final String _channelId = 'reminder_channel_darahaas_v3';

  Future<void> scheduleNotification(Reminder reminder) async {
    final repeatType = reminder.repeatType?.toLowerCase();

    DateTimeComponents? matchComponents;
    if (repeatType == 'daily') {
      matchComponents = DateTimeComponents.time;
    } else if (repeatType == 'weekly') {
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    } else if (repeatType == 'monthly') {
      matchComponents = DateTimeComponents.dayOfMonthAndTime;
    } else if (repeatType == 'yearly') {
      matchComponents = DateTimeComponents.dateAndTime;
    }

    tz.TZDateTime scheduledTime = tz.TZDateTime.from(
      reminder.scheduledTime ?? DateTime.now(),
      tz.local,
    );

    // 🧠 Adjust past scheduled times for repeating reminders
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledTime.isBefore(now)) {
      switch (repeatType) {
        case 'daily':
          while (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 1));
          }
          break;
        case 'weekly':
          while (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 7));
          }
          break;
        case 'monthly':
          while (scheduledTime.isBefore(now)) {
            scheduledTime = tz.TZDateTime(
              scheduledTime.location,
              scheduledTime.year,
              scheduledTime.month + 1,
              scheduledTime.day,
              scheduledTime.hour,
              scheduledTime.minute,
            );
          }
          break;
        case 'yearly':
          while (scheduledTime.isBefore(now)) {
            scheduledTime = tz.TZDateTime(
              scheduledTime.location,
              scheduledTime.year + 1,
              scheduledTime.month,
              scheduledTime.day,
              scheduledTime.hour,
              scheduledTime.minute,
            );
          }
          break;
        case 'once':
          debugPrint(
            "⚠️ Skipping one-time reminder in the past: ${reminder.title}",
          );
          return;
        default:
          {
            debugPrint(
              "⚠️ Skipping Unknown $repeatType reminder in the past: ${reminder.title}",
            );
            return;
          }
      }
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      reminder.notification_id,
      reminder.title,
      reminder.description,
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Reminders',
          channelDescription: 'Channel for scheduled reminders',
          importance: Importance.high,
          priority: Priority.high,
          fullScreenIntent: true,
          sound: RawResourceAndroidNotificationSound('notification_ringtone'),
          autoCancel: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'snooze_action_${reminder.notification_id}',
              'Snooze',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'view_action_${reminder.notification_id}',
              'View',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      payload:
          '${reminder.notification_id}|${reminder.reminder_id}|${reminder.title}|${reminder.description}',
    );

    debugPrint(
      "📅 Scheduled reminder ID: ${reminder.reminder_id} at $scheduledTime (repeat: $repeatType)",
    );
  }

  Future<void> cancelNotification(int notification_id) async {
    await flutterLocalNotificationsPlugin.cancel(notification_id);
    debugPrint("❌ Cancelled notification for $notification_id");
  }
}
