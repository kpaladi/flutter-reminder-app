import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/reminder_model.dart';
import 'notification_service.dart';

   final _db = FirebaseFirestore.instance;

   Future<void> deleteReminder(BuildContext context, Reminder reminder) async {
    await _db.collection("reminders").doc(reminder.reminder_id).delete();
    await NotificationService().cancelNotification(reminder.notification_id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reminder deleted")),
    );
  }

