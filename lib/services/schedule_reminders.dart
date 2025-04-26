import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/services/notification_helper.dart';
import 'package:reminder_app/services/reminder_repository.dart';
import 'notification_service.dart';

Future<void> scheduleAllReminders(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    debugPrint("🔒 User not logged in — redirecting to login.");
    await NotificationService().redirectToLogin(); // You can also navigate to login here if in-app
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🔒 Please login to schedule reminders."),
          duration: Duration(seconds: 2),
        ),
      );
    }
    return;
  }

  final repository = ReminderRepository(userId: user.uid);
  final reminders = await repository.getReminders();

  // Cancel all existing notifications before scheduling new ones
  await flutterLocalNotificationsPlugin.cancelAll();
  debugPrint("✅ Cleared all existing notifications");

  int scheduledCount = 0;

  for (var reminder in reminders) {

    if (reminder.scheduledTime != null) {
      if (reminder.repeatType == null || reminder.repeatType == 'once') {
        // One-time reminder
        await NotificationService().scheduleNotification(reminder);
        debugPrint("📅 One-time: '${reminder.title}' at ${DateFormat('dd-MM-yyyy HH:mm').format(reminder.scheduledTime!)}");
      } else {
        // Repeating reminder
        await NotificationService().scheduleNotification(reminder);
        debugPrint("🔁 Repeats (${reminder.repeatType}): '${reminder.title}' at ${DateFormat('dd-MM-yyyy HH:mm').format(reminder.scheduledTime!)}");
      }
      scheduledCount++;
    } else {
      debugPrint("⚠️ Skipped: '${reminder.title}' has no valid scheduledTime");
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
