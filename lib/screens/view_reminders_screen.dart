import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/reminder_repository.dart';
import '../utils/reminder_utils.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/reminder_export_fab.dart';
import '../widgets/remindergroup_sorted_active_past.dart';
import '../widgets/shared_widgets.dart';

class ViewRemindersScreen extends StatelessWidget {
  const ViewRemindersScreen({super.key});

  Future<void> refreshRepeatReminders(BuildContext context) async {
    final repository = Provider.of<ReminderRepository>(context, listen: false);
    final reminders = await repository.getAllReminders();

    int refreshedCount = 0;

    for (var reminder in reminders) {
      if (reminder.repeatType != null && reminder.repeatType != 'once') {
        final nextTime = getNextOccurrence(reminder);
        if (nextTime != null) {
          final updatedReminder = reminder.copyWith(scheduledTime: nextTime);
          await NotificationService().scheduleNotification(updatedReminder);
          refreshedCount++;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Refreshed $refreshedCount repeat reminder(s).")),
    );
  }

  Map<String, List<Reminder>> _groupReminders(List<Reminder> reminders) {
    Map<String, List<Reminder>> groupedReminders = {
      'One-Time': [],
      'Daily': [],
      'Weekly': [],
      'Monthly': [],
      'Yearly': [],
      'Others': [],
    };

    for (var reminder in reminders) {
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

    return groupedReminders;
  }

  @override
  Widget build(BuildContext context) {
    // Ensuring the ReminderRepository is being listened to correctly
    final repository = Provider.of<ReminderRepository>(context);

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
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Text('Refresh Repeat Reminders'),
                  ),
                ],
          ),
        ],
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: repository.watchAllReminders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: LoadingIndicator());
          }

          final grouped = _groupReminders(snapshot.data!);

          return ListView(
            padding: const EdgeInsets.all(12),
            children:
                grouped.entries
                    .where((entry) => entry.value.isNotEmpty)
                    .map(
                      (entry) => ReminderGroupWithSortedActiveAndPast(
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
                          await NotificationService().cancelNotification(reminder.notificationId);
                          await repository.deleteReminder(reminder.reminderId);
                        },
                      ),
                    )
                    .toList(),
          );
        },
      ),
      floatingActionButton: ReminderExportFAB(repository: repository),
    );
  }
}
