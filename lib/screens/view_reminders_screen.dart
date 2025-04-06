import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reminder_model.dart'; // ✅ Using updated Reminder model
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

  void scheduleNotification(String reminderId, Reminder reminder) {
    _notificationService.scheduleNotification(reminder);
  }

  void _editReminder(String reminderId, Reminder reminder) async {
    final scaffoldContext = context; // capture early

    final updatedReminder = await Navigator.push<Reminder>(
      scaffoldContext,
      MaterialPageRoute(
        builder: (context) => EditReminderScreen(
          reminder: reminder,
        ),
      ),
    );

    if (updatedReminder != null) {
      await NotificationService().cancelNotification(reminderId);
      await NotificationService().scheduleNotification(updatedReminder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Reminder updated')),
        );
      }

      setState(() {
        // update UI
      });
    }
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
      await _notificationService.cancelNotification(reminderId);
    } catch (e) {
      debugPrint("Error deleting reminder: $e");
    }
  }

  Future<void> _exportReminders(List<QueryDocumentSnapshot> reminders) async {
    try {
      List<List<dynamic>> csvData = [
        ['Title', 'Description', 'Timestamp']
      ];

      for (var doc in reminders) {
        Reminder reminder = Reminder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        csvData.add([
          reminder.title,
          reminder.description,
          reminder.timestamp != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(reminder.timestamp!)
              : '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);
      final dir = await getExternalStorageDirectory();

      if (dir == null) throw Exception("Storage directory not available");

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

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('dd-MM-yyyy HH:mm').format(timestamp);
  }

  Reminder _mapDocToReminder(QueryDocumentSnapshot doc) {
    return Reminder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("View Reminders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("reminders").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          var reminders = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              var doc = reminders[index];
              Reminder reminder = _mapDocToReminder(doc);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        reminder.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reminder.timestamp != null
                                ? _formatTimestamp(reminder.timestamp!)
                                : "No time set",
                            style: TextStyle(fontSize: 12, color: Colors.red[500]),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editReminder(doc.id, reminder),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteReminder(doc.id),
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
