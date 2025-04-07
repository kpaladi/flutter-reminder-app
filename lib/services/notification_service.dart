import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart'; // ✅ Import updated Reminder model
import 'notification_helper.dart';

class NotificationService {
  NotificationService();

  final String _channelId = 'reminder_channel_darahaas_v3';

  Future<void> _saveScheduledReminder(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> scheduledReminders =
        prefs.getStringList('scheduled_reminders') ?? [];

    if (!scheduledReminders.contains(id)) {
      scheduledReminders.add(id);
      await prefs.setStringList('scheduled_reminders', scheduledReminders);
    }
  }

  Future<void> scheduleNotification(Reminder reminder) async {
    final int notifId = reminder.id.hashCode;

    final repeatType = reminder.repeatType?.toLowerCase();

    DateTimeComponents? matchComponents;
    if (repeatType == 'day') {
      matchComponents = DateTimeComponents.time;
    } else if (repeatType == 'week') {
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    } else if (repeatType == 'month') {
      matchComponents = DateTimeComponents.dayOfMonthAndTime;
    } else if (repeatType == 'year') {
      matchComponents = DateTimeComponents.dateAndTime;
    }

    tz.TZDateTime scheduledTime = tz.TZDateTime.from(
      reminder.timestamp ?? DateTime.now(),
      tz.local,
    );

    // 🧠 Adjust past scheduled times for repeating reminders
    final now = tz.TZDateTime.now(tz.local);
    if (scheduledTime.isBefore(now)) {
      switch (repeatType) {
        case 'day':
          while (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 1));
          }
          break;
        case 'week':
          while (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(days: 7));
          }
          break;
        case 'month':
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
        case 'year':
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
        case 'only once':
          debugPrint("⚠️ Skipping one-time reminder in the past: ${reminder.title}");
          return;
      }
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notifId,
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
          timeoutAfter: 60000,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification_ringtone'),
          showWhen: true,
          autoCancel: false,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'snooze_action_$notifId',
              'Tap to snooze',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      payload: '${reminder.id}|${reminder.title}|${reminder.description}',
    );

    debugPrint("📅 Scheduled reminder ID: ${reminder.id} at $scheduledTime (repeat: $repeatType)");
    await _saveScheduledReminder(reminder.id);
  }



  Future<void> cancelNotification(String reminderId) async {
    final int notificationId = reminderId.hashCode;

    await flutterLocalNotificationsPlugin.cancel(notificationId);

    final prefs = await SharedPreferences.getInstance();
    List<String> scheduledReminders =
        prefs.getStringList('scheduled_reminders') ?? [];

    scheduledReminders.remove(reminderId);
    await prefs.setStringList('scheduled_reminders', scheduledReminders);

    debugPrint("❌ Cancelled notification for $reminderId (notification ID: $notificationId)");
  }

}
