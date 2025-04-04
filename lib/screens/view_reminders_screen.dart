import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import 'edit_reminder_screen.dart';

class ViewRemindersScreen extends StatefulWidget {
  const ViewRemindersScreen({super.key});

  @override
  ViewRemindersScreenState createState() => ViewRemindersScreenState();
}

class ViewRemindersScreenState extends State<ViewRemindersScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService =
      NotificationService(); // Initialize notification service

  @override
  void initState() {
    super.initState();
  }

  void scheduleNotification(
    String reminderId,
    Map<String, dynamic> reminderData,
  ) {
    if (reminderData['timestamp'] is Timestamp) {
      DateTime? scheduledTime =
          (reminderData['timestamp'] as Timestamp).toDate();
      int notificationId = generateUniqueId(reminderId); // Use stable ID

      _notificationService.scheduleNotification(
        notificationId,
        reminderData['title'] ?? 'Reminder',
        reminderData['description'] ?? 'You have a reminder!',
        scheduledTime,
      );
    }
  }

  int generateUniqueId(String reminderId) {
    return reminderId.hashCode;
  }

  void _editReminder(
    String reminderId,
    Map<String, dynamic> reminderData,
  ) async {
    DateTime? reminderDateTime;
    if (reminderData['timestamp'] is Timestamp) {
      reminderDateTime = (reminderData['timestamp'] as Timestamp).toDate();
    }

    final updatedReminder = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditReminderScreen(
              reminderId: reminderId,
              reminderData: {...reminderData, 'timestamp': reminderDateTime},
            ),
      ),
    );

    if (updatedReminder != null) {
      await _db.collection("reminders").doc(reminderId).update(updatedReminder);

      // Cancel the old notification
      final NotificationService notificationService = NotificationService();
      await notificationService.cancelNotification(reminderId.hashCode);

      scheduleNotification(
        reminderId,
        updatedReminder,
      ); // Schedule notification after update
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "No Date";
    if (timestamp is Timestamp) {
      return DateFormat('dd-MM-yyyy HH:mm').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('dd-MM-yyyy HH:mm').format(timestamp);
    }
    return "Invalid Date";
  }

  void _confirmDeleteReminder(String reminderId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use a separate context
        return AlertDialog(
          title: Text("Delete Reminder"),
          content: Text("Are you sure you want to delete this reminder?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(), // Use dialogContext
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog before async operation
                _deleteReminder(reminderId);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReminder(String reminderId) async {
    try {
      await _db.collection("reminders").doc(reminderId).delete();
      _notificationService.cancelNotification(reminderId.hashCode); // Cancel notification
    } catch (e) {
      debugPrint("Error deleting reminder: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("View Reminders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("reminders").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var reminders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              var reminder = reminders[index];
              var reminderData = reminder.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminderData['title'] ?? 'No Title',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        reminderData['description'] ?? 'No Description',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimestamp(reminderData['timestamp']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[500],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed:
                                    () => _editReminder(
                                      reminder.id,
                                      reminderData,
                                    ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed:
                                    () => _confirmDeleteReminder(reminder.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
