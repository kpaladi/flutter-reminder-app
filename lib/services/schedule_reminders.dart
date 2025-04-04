import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/services/notification_helper.dart';
import 'notification_service.dart';

Future<void> scheduleAllReminders(BuildContext context) async {
  QuerySnapshot reminderDocs =
      await FirebaseFirestore.instance.collection("reminders").get();

  // Cancel all existing notifications before scheduling new ones
  await flutterLocalNotificationsPlugin.cancelAll();
  debugPrint("✅ Cleared all existing notifications");

  int scheduledCount = 0;

  for (var doc in reminderDocs.docs) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    if (data['timestamp'] != null) {
      DateTime reminderTime = (data['timestamp'] as Timestamp).toDate();

      // Schedule notification
      await NotificationService().scheduleNotification(
        doc.id.hashCode,
        data['title'],
        data['description'],
        reminderTime,
      );

      debugPrint(
        "📅 Scheduled Reminder: '${data['title']}' at ${DateFormat('dd-MM-yyyy HH:mm').format(reminderTime)}",
      );
      scheduledCount++;
    } else {
      debugPrint("⚠️ Skipped Reminder: '${data['title']}' has no valid timestamp");
    }
  }

  debugPrint("✅ Total Reminders Scheduled: $scheduledCount");

  // UI feedback with a Snack bar
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ $scheduledCount reminders scheduled!"),
        duration: Duration(seconds: 2),
      ),
    );
  }
}