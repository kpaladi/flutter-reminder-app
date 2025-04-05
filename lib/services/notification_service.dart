import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_helper.dart'; // Import the helper file

class NotificationService {
  NotificationService();

  Future<void> _saveScheduledReminders(int id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> scheduledReminders =
        prefs.getStringList('scheduled_reminders') ?? [];
    if (!scheduledReminders.contains(id.toString())) {
      scheduledReminders.add(id.toString());
      await prefs.setStringList('scheduled_reminders', scheduledReminders);
    }
  }

  Future<bool> _isReminderScheduled(int id) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> scheduledReminders =
        prefs.getStringList('scheduled_reminders') ?? [];
    bool isScheduled = scheduledReminders.contains(id.toString());

    return isScheduled;
  }

  Future<void> _scheduleNotificationLogic(
    int id,
    String title,
    String description,
    DateTime scheduledTime,
  ) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      description,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel_darahaas',
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
              'snooze_action_$id',
              'tap to snooze',
              showsUserInterface: true,
            ),
          ],
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      androidScheduleMode: AndroidScheduleMode.exact,
      payload: '$id|$title|$description', // Ensure this matches
    );

    await _saveScheduledReminders(id);
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String description,
    DateTime scheduledTime,
  ) async {
    bool isAlreadyScheduled = await _isReminderScheduled(id);

    if (isAlreadyScheduled) {
      return;
    } else {
      debugPrint("Notification is scheduled for ID: $id for $scheduledTime");
    }

    await _scheduleNotificationLogic(id, title, description, scheduledTime);
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    final prefs = await SharedPreferences.getInstance();
    List<String> scheduledReminders =
        prefs.getStringList('scheduled_reminders') ?? [];
    scheduledReminders.remove(id.toString());
    await prefs.setStringList('scheduled_reminders', scheduledReminders);
    debugPrint("Notification is cancelled for ID: $id");
  }
}
