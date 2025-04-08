import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reminder_model.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/reminder_export_fab.dart';
import '../widgets/reminder_group_section.dart';


class ViewRemindersScreen extends StatelessWidget {
  final _db = FirebaseFirestore.instance;

  ViewRemindersScreen({super.key});

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

    // Sort each group
    groupedReminders.forEach((key, list) {
      list.sort((a, b) {
        final aTime = a.timestamp ?? DateTime(2100);
        final bTime = b.timestamp ?? DateTime(2100);

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
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(title: const Text("View Reminders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("reminders").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

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
                await _db.collection("reminders").doc(reminder.id).delete();
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