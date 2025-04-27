import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import '../models/reminder_model.dart';

class ReminderRepository extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  ReminderRepository({required this.userId});

  // Reference to the reminders collection for the current user
  CollectionReference get _remindersRef =>
      _firestore.collection('users').doc(userId).collection('reminders');

  // Get all reminders for the current user
  Future<List<Reminder>> getReminders() async {
    final snapshot = await _remindersRef.get();
    return snapshot.docs.map((doc) => Reminder.fromFirestore(doc)).toList();
  }

  // Get all reminders for the current user (alias for getReminders)
  Future<List<Reminder>> getAllReminders() async {
    return getReminders();
  }

  // Get a specific reminder by ID for the current user
  Future<Reminder?> getReminderById(String id) async {
    final doc = await _remindersRef.doc(id).get();
    return doc.exists ? Reminder.fromFirestore(doc) : null;
  }

  // Add a new reminder for the current user
  Future<void> addReminder(Reminder reminder) async {
    await _remindersRef.doc(reminder.reminder_id).set(reminder.toMap());
    // Notify listeners that the data has changed
    notifyListeners();
  }

  // Update an existing reminder for the current user
  Future<void> updateReminder(Reminder reminder) async {
    await _remindersRef.doc(reminder.reminder_id).update(reminder.toMap());
    // Notify listeners that the data has changed
    notifyListeners();
  }

  // Delete a reminder by ID for the current user
  Future<void> deleteReminder(String id) async {
    await _remindersRef.doc(id).delete();
    // Notify listeners that the data has changed
    notifyListeners();
  }

  Future<void> saveReminder(Reminder reminder) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('reminders')
        .doc(reminder.reminder_id);

    await docRef.set(reminder.toMap());
    // Notify listeners that the data has changed
    notifyListeners();
  }

  // Stream reminders for the current user
  Stream<List<Reminder>> streamReminders() {
    return _remindersRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Reminder.fromFirestore(doc)).toList();
    });
  }

  Stream<List<Reminder>> watchAllReminders() {
    return _remindersRef.snapshots().map((snapshot) {
      final reminders = snapshot.docs.map((doc) {
        return Reminder.fromFirestore(doc);
      }).toList();

      debugPrint("📡 Stream update: ${reminders.length} reminder(s) received for user $userId");

      for (var r in reminders) {
        debugPrint("🔔 Reminder: ${r.title} | ${r.scheduledTime} | ${r.repeatType}");
      }

      return reminders;
    });
  }

  String getNewReminderId() {
    return _remindersRef.doc().id;
  }
}
