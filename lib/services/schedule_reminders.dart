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

      if (reminder.repeatType == null || reminder.repeatType == 'only once') {
        // One-time reminder
        await NotificationService().scheduleNotification(reminder);
        debugPrint("📅 One-time: '${reminder.title}' at ${DateFormat('dd-MM-yyyy HH:mm').format(reminder.timestamp!)}");
        scheduledCount++;
      } else {
        // Repeating reminder — schedule only one instance for now
        final instance = reminder.copyWith(timestamp: reminder.timestamp);
        await NotificationService().scheduleNotification(instance);
        debugPrint("🔁 Repeats (${reminder.repeatType}): '${reminder.title}' at ${DateFormat('dd-MM-yyyy HH:mm').format(reminder.timestamp!)}");
        scheduledCount++;
      }
    } else {
      debugPrint("⚠️ Skipped Reminder: '${data['title']}' has no valid timestamp");
    }
  }

  debugPrint("✅ Total Reminders Scheduled: $scheduledCount");

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ $scheduledCount reminders scheduled!"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
