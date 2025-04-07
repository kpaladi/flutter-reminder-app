import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/models/reminder_model.dart';
import 'package:reminder_app/services/notification_helper.dart';
import 'notification_service.dart';

Future<void> scheduleAllReminders(BuildContext context) async {
  final snapshot = await FirebaseFirestore.instance.collection("reminders").get();

  // Cancel all existing notifications before scheduling new ones
  await flutterLocalNotificationsPlugin.cancelAll();
  debugPrint("✅ Cleared all existing notifications");

  int scheduledCount = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();

    if (data['timestamp'] != null) {
      final reminder = Reminder.fromMap(data, doc.id);

      // If there's no repeat type or it is "only once", schedule as one-time
      if (reminder.repeatType == null || reminder.repeatType == 'only once') {
        await NotificationService().scheduleNotification(reminder);
        debugPrint("📅 One-time: '${reminder.title}' at ${DateFormat('dd-MM-yyyy HH:mm').format(reminder.timestamp!)}");
        scheduledCount++;
      } else {
        // Handle repeating reminders
        final now = DateTime.now();
        final start = reminder.timestamp!;
        final end = reminder.repeatEnd ?? now.add(Duration(days: 30)); // fallback: 30 days from now
        final interval = reminder.repeatInterval ?? 1;
        final repeatType = reminder.repeatType!;

        Duration? step;
        switch (repeatType) {
          case 'day':
            step = Duration(days: interval);
            break;
          case 'week':
            step = Duration(days: 7 * interval);
            break;
          case 'month':
            step = null; // handled differently below
            break;
          default:
            debugPrint("⚠️ Unknown repeat type: $repeatType");
            continue;
        }

        DateTime occurrence = start;

        while (occurrence.isBefore(end) || occurrence.isAtSameMomentAs(end)) {
          final instance = reminder.copyWith(timestamp: occurrence);
          await NotificationService().scheduleNotification(instance);
          debugPrint("🔁 Repeated: '${reminder.title}' at ${DateFormat('dd-MM-yyyy HH:mm').format(occurrence)}");
          scheduledCount++;

          if (repeatType == 'month') {
            occurrence = DateTime(occurrence.year, occurrence.month + interval, occurrence.day, occurrence.hour, occurrence.minute);
          } else {
            occurrence = occurrence.add(step!);
          }
        }
      }
    } else {
      debugPrint("⚠️ Skipped Reminder: '${data['title']}' has no valid timestamp");
    }
  }

  debugPrint("✅ Total Reminders Scheduled: $scheduledCount");

  // UI feedback with a SnackBar
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ $scheduledCount reminders scheduled!"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

