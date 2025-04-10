import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';
import '../services/delete_reminder.dart';
import '../services/notification_service.dart';
import '../utils/reminder_utils.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/reminder_export_fab.dart';
import '../widgets/remindergroup_sorted_active_past.dart';
import '../widgets/shared_widgets.dart';

class ViewRemindersScreen extends StatelessWidget {
  final _db = FirebaseFirestore.instance;

  ViewRemindersScreen({super.key});

  Reminder _mapDocToReminder(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reminder.fromMap(data, doc.id);
  }

  Future<void> refreshRepeatReminders(context) async {
    final snapshot = await FirebaseFirestore.instance.collection('reminders').get();
    final reminders = snapshot.docs.map((doc) => Reminder.fromMap(doc.data())).toList();

    int refreshedCount = 0;

    for (var reminder in reminders) {
      if (reminder.repeatType != null &&
          reminder.repeatType != 'once') {
        final nextTime = getNextOccurrence(reminder);
        if (nextTime != null) {
          final updatedReminder = reminder.copyWith(scheduledTime: nextTime);
          await NotificationService().scheduleNotification(updatedReminder);
          refreshedCount++;
        }
      }
    }

    // Show snackbar confirmation with count
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Refreshed $refreshedCount repeat reminder(s)."),
        ),
      );
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

    final now = DateTime.now();

    groupedReminders.forEach((key, list) {
      list.sort((a, b) {
        final aTime = a.scheduledTime ?? DateTime(2100);
        final bTime = b.scheduledTime ?? DateTime(2100);
        return aTime.compareTo(bTime);
      });

      // Move expired reminders to the end
      list.sort((a, b) {
        final aExpired = (a.scheduledTime?.isBefore(now) ?? false);
        final bExpired = (b.scheduledTime?.isBefore(now) ?? false);

        if (aExpired == bExpired) return 0;
        return aExpired ? 1 : -1; // expired goes after non-expired
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
          onSelected: (value) {
            if (value == 'refresh') {
              refreshRepeatReminders(context);
            }
          },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'refresh',
            child: Text('Refresh Repeat Reminders'),
          ),
          // Add other options here if needed
        ],
      ),
      ],
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
                .map((entry) => ReminderGroupWithSortedActiveAndPast(
              groupTitle: entry.key,
              reminders: entry.value,
              onEdit: (reminder) {
                Navigator.pushNamed(
                  context,
                  '/add-edit',
                  arguments: reminder,
                );
              },
              onDelete: (reminder) => deleteReminder(context, reminder),
            ))
                .toList(),
          );},
      ),

      floatingActionButton: ReminderExportFAB(db: _db),

    );
  }
}
