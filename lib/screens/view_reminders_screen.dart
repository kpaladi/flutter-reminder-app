import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';
import '../services/export_csv.dart';
import '../services/notification_service.dart';
import '../services/import_csv.dart';
import '../utils/dialogs.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/reminder_group_section.dart';
import '../widgets/reminder_export_fab.dart';
import '../widgets/shared_widgets.dart';

class ViewRemindersScreen extends StatelessWidget {
  final _db = FirebaseFirestore.instance;

  ViewRemindersScreen({super.key});

  Future<void> _exportReminders(BuildContext context) async {
    await Future.delayed(Duration.zero); // give UI time to show loading dialog

    try {
      final snapshot = await _db.collection("reminders").get();
      final reminders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['reminder_id'] = doc.id; // Include document ID
        return data;
      }).toList();

      await exportToCsv(context, reminders); // 🔹 Make sure this is imported from export_csv.dart

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminders exported successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export failed: $e")),
      );
    }
  }

  Reminder _mapDocToReminder(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reminder.fromMap(data, doc.id);
  }

  Map<String, List<Reminder>> _groupReminders(List<DocumentSnapshot> docs) {
    Map<String, List<Reminder>> groupedReminders = {
      'One-Time': [],
      'Daily': [],
      'Weekly': [],
      'Monthly': [],
      'Yearly': [],
      'Others': [],
    };

    for (var doc in docs) {
      final reminder = _mapDocToReminder(doc);
      final type = reminder.repeatType?.toLowerCase();

      if (type == null || type.isEmpty || type == 'once') {
        groupedReminders['One-Time']!.add(reminder);
      } else if (type == 'daily') {
        groupedReminders['Daily']!.add(reminder);
      } else if (type == 'weekly') {
        groupedReminders['Weekly']!.add(reminder);
      } else if (type == 'monthly') {
        groupedReminders['Monthly']!.add(reminder);
      } else if (type == 'yearly') {
        groupedReminders['Yearly']!.add(reminder);
      } else {
        groupedReminders['Others']!.add(reminder);
      }
    }

    groupedReminders.forEach((key, list) {
      list.sort((a, b) {
        final aTime = a.scheduledTime ?? DateTime(2100);
        final bTime = b.scheduledTime ?? DateTime(2100);
        return aTime.compareTo(bTime);
      });
    });

    return groupedReminders;
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text("View Reminders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("reminders").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: LoadingIndicator());
          }

          final grouped = _groupReminders(snapshot.data!.docs);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries
                .where((entry) => entry.value.isNotEmpty)
                .map((entry) => ReminderGroupSection(
              groupTitle: entry.key,
              reminders: entry.value,
              onEdit: (reminder) {
                Navigator.pushNamed(
                  context,
                  '/add-edit',
                  arguments: reminder,
                );
              },
              onDelete: (reminder) async {
                await _db.collection("reminders").doc(reminder.reminder_id).delete();
                await NotificationService().cancelNotification(reminder.notification_id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reminder deleted")),
                );
              },
            ))
                .toList(),
          );
        },
      ),

      floatingActionButton: ReminderExportFAB(db: _db),

    );
  }
}
