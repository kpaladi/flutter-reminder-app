import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/notification_service.dart';
import 'edit_reminder_screen.dart';
import 'package:csv/csv.dart';

class ViewRemindersScreen extends StatefulWidget {
  const ViewRemindersScreen({super.key});

  @override
  ViewRemindersScreenState createState() => ViewRemindersScreenState();
}

class ViewRemindersScreenState extends State<ViewRemindersScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
  }

  void scheduleNotification(
      String reminderId,
      Map<String, dynamic> reminderData,
      ) {
    if (reminderData['timestamp'] is Timestamp) {
      DateTime scheduledTime = (reminderData['timestamp'] as Timestamp).toDate();
      int notificationId = generateUniqueId(reminderId);

      _notificationService.scheduleNotification(
        notificationId,
        reminderData['title'] ?? 'Reminder',
        reminderData['description'] ?? 'You have a reminder!',
        scheduledTime,
      );
    }
  }

  int generateUniqueId(String reminderId) => reminderId.hashCode;

  void _editReminder(String reminderId, Map<String, dynamic> reminderData) async {
    DateTime? reminderDateTime;
    if (reminderData['timestamp'] is Timestamp) {
      reminderDateTime = (reminderData['timestamp'] as Timestamp).toDate();
    }

    final updatedReminder = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReminderScreen(
          reminderId: reminderId,
          reminderData: {...reminderData, 'timestamp': reminderDateTime},
        ),
      ),
    );

    if (updatedReminder != null) {
      await _db.collection("reminders").doc(reminderId).update(updatedReminder);
      await _notificationService.cancelNotification(reminderId.hashCode);
      scheduleNotification(reminderId, updatedReminder);
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Delete Reminder"),
          content: Text("Are you sure you want to delete this reminder?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
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
      await _notificationService.cancelNotification(reminderId.hashCode);
    } catch (e) {
      debugPrint("Error deleting reminder: $e");
    }
  }

  Future<void> _exportReminders(List<QueryDocumentSnapshot> reminders) async {
    try {
      // Convert reminders to CSV rows
      List<List<dynamic>> csvData = [
        ['Title', 'Description', 'Timestamp']
      ];

      for (var doc in reminders) {
        var data = doc.data() as Map<String, dynamic>;
        String title = data['title'] ?? '';
        String description = data['description'] ?? '';
        String timestamp = '';

        if (data['timestamp'] is Timestamp) {
          timestamp = (data['timestamp'] as Timestamp)
              .toDate()
              .toString(); // or format if needed
        }

        csvData.add([title, description, timestamp]);
      }

      String csv = const ListToCsvConverter().convert(csvData);

      // Get safe app-specific external directory
      final dir = await getExternalStorageDirectory();

      if (dir == null) {
        throw Exception("Storage directory not available");
      }

      // Write to file
      final file = File('${dir.path}/reminders_export.csv');
      await file.writeAsString(csv);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${file.path}')),
      );
    } catch (e) {
      debugPrint("Export failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed')),
      );
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
                                onPressed: () => _editReminder(reminder.id, reminderData),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteReminder(reminder.id),
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
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("reminders").snapshots(),
        builder: (context, snapshot) {
          return FloatingActionButton(
            onPressed: snapshot.hasData
                ? () => _exportReminders(snapshot.data!.docs)
                : null,
            tooltip: 'Export Reminders',
            child: Icon(Icons.download),
          );
        },
      ),
    );
  }
}
