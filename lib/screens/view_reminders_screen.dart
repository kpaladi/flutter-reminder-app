import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reminder_model.dart';
import '../services/import_csv.dart';
import '../services/notification_service.dart';
import '../utils/dialogs.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/reminder_export_fab.dart';
import '../widgets/reminder_group_section.dart';
import '../widgets/shared_widgets.dart';  // Import your shared widgets

class ViewRemindersScreen extends StatelessWidget {
  final _db = FirebaseFirestore.instance;

  ViewRemindersScreen({super.key});

  // Mapping document to Reminder model
  Reminder _mapDocToReminder(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reminder.fromMap(data, doc.id);
  }

  // Grouping reminders based on their repeat type
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

      // Group reminders based on repeatType
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

    // Sort each group by scheduled time
    groupedReminders.forEach((key, list) {
      list.sort((a, b) {
        final aTime = a.scheduledTime ?? DateTime(2100);
        final bTime = b.scheduledTime ?? DateTime(2100);

        switch (key) {
          case 'One-Time':
            return aTime.compareTo(bTime);
          case 'Daily':
            return (aTime.hour * 60 + aTime.minute)
                .compareTo(bTime.hour * 60 + bTime.minute);
          case 'Weekly':
            {
              final aUnit = aTime.weekday;
              final bUnit = bTime.weekday;
              if (aUnit != bUnit) return aUnit.compareTo(bUnit);
              return (aTime.hour * 60 + aTime.minute)
                  .compareTo(bTime.hour * 60 + bTime.minute);
            }
          case 'Monthly':
            {
              final aUnit = aTime.day;
              final bUnit = bTime.day;
              if (aUnit != bUnit) return aUnit.compareTo(bUnit);
              return (aTime.hour * 60 + aTime.minute)
                  .compareTo(bTime.hour * 60 + bTime.minute);
            }
          case 'Yearly':
            {
              if (aTime.month != bTime.month) {
                return aTime.month.compareTo(bTime.month);
              }
              if (aTime.day != bTime.day) {
                return aTime.day.compareTo(bTime.day);
              }
              return (aTime.hour * 60 + aTime.minute)
                  .compareTo(bTime.hour * 60 + bTime.minute);
            }
          default:
            return aTime.compareTo(bTime);
        }
      });
    });

    return groupedReminders;
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text("View Reminders"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'import') {
                // Implement import functionality
                await runWithLoadingDialog(
                  context: context,
                  message: "Importing reminders...",
                  task: () => importFromCsv(context),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(
                value: 'import',
                child: Text('Import from CSV'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("reminders").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: LoadingIndicator()); // Shared loading widget
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
                  '/edit',
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