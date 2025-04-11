

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reminder_model.dart';

Future<Reminder?> fetchReminderById(String reminderId) async {
  final doc = await FirebaseFirestore.instance.collection('reminders').doc(reminderId).get();
  if (!doc.exists) return null;
  return Reminder.fromFirestore(doc);
}
