import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import 'edit_reminder_screen.dart';
import 'package:csv/csv.dart';
import 'package:sticky_headers/sticky_headers.dart';

class ViewRemindersScreen extends StatefulWidget {
  const ViewRemindersScreen({super.key});

  @override
  ViewRemindersScreenState createState() => ViewRemindersScreenState();
}

class ViewRemindersScreenState extends State<ViewRemindersScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  void _editReminder(String reminderId, Reminder reminder) async {
    final updatedReminder = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute(
        builder: (context) => EditReminderScreen(reminder: reminder),
      ),
    );

    if (updatedReminder != null) {
      await _notificationService.cancelNotification(reminderId);
      await _notificationService.scheduleNotification(updatedReminder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Reminder updated')),
        );
      }

      setState(() {});
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('h:mm a').format(date);
  }

  String _buildRepeatSummary(Reminder r) {
    if (r.repeatType == 'only once' || r.repeatType == null || r.repeatType!.isEmpty) {
      final time = _formatTime(r.timestamp!);
      final date = _formatDate(r.timestamp!);
      return "Reminder at $time on $date";
    }

    final interval = r.repeatInterval ?? 1;
    final type = r.repeatType!;
    final every = interval == 1 ? "every $type" : "every $interval ${type}s";
    final start = _formatDate(r.timestamp!);
    final time = _formatTime(r.timestamp!);
    final end = r.repeatEnd != null ? " till ${_formatDate(r.repeatEnd)}" : "";

    return "Reminder $every at $time, from $start$end";
  }


  Reminder _mapDocToReminder(QueryDocumentSnapshot doc) {
    return Reminder.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Widget _buildReminderCard(Reminder reminder) {
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
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[700]),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _buildRepeatSummary(reminder),
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editReminder(reminder.id, reminder),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteReminder(reminder.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("View Reminders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("reminders").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          Map<String, List<Reminder>> groupedReminders = {
            'One-Time': [],
            'Daily': [],
            'Weekly': [],
            'Monthly': [],
            'Yearly': [],
            'Others': [],
          };

          for (var doc in snapshot.data!.docs) {
            Reminder reminder = _mapDocToReminder(doc);
            final type = reminder.repeatType?.toLowerCase();

            if (type == null || type.isEmpty || type == 'only once') {
              groupedReminders['One-Time']!.add(reminder);
            } else if (type == 'day') {
              groupedReminders['Daily']!.add(reminder);
            } else if (type == 'week') {
              groupedReminders['Weekly']!.add(reminder);
            } else if (type == 'month') {
              groupedReminders['Monthly']!.add(reminder);
            } else if (type == 'year') {
              groupedReminders['Yearly']!.add(reminder);
            } else {
              groupedReminders['Others']!.add(reminder);
            }
          }

          // ✅ Sort reminders in each group by timestamp
          groupedReminders.forEach((key, list) {
            list.sort((a, b) => (a.timestamp ?? DateTime(2100)).compareTo(b.timestamp ?? DateTime(2100)));
          });

          return ListView(
            padding: EdgeInsets.all(12),
            children: groupedReminders.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((entry) {
              final reminders = entry.value..sort((a, b) {
                final aTime = a.timestamp ?? DateTime(2100);
                final bTime = b.timestamp ?? DateTime(2100);
                return aTime.compareTo(bTime);
              });

              return StickyHeader(
                header: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  color: Colors.grey.shade300,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                content: Column(
                  children: reminders.map((reminder) => _buildReminderCard(reminder)).toList(),
                ),
              );
            })
                .toList(),
          );
        },
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("reminders").snapshots(),
        builder: (context, snapshot) {
          return FloatingActionButton(
            onPressed: snapshot.hasData ? () => _exportReminders(snapshot.data!.docs) : null,
            tooltip: 'Export Reminders',
            child: Icon(Icons.download),
          );
        },
      ),
    );
  }
}
