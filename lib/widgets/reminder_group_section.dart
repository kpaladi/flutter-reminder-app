import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

import '../models/reminder_model.dart';
import 'reminder_card.dart';
import '../utils/reminder_utils.dart'; // Assuming isReminderInPast is defined here

class ReminderGroupSection extends StatelessWidget {
  final String groupTitle;
  final List<Reminder> reminders;
  final void Function(Reminder reminder) onEdit;
  final void Function(Reminder reminder) onDelete;

  const ReminderGroupSection({
    super.key,
    required this.groupTitle,
    required this.reminders,
    required this.onEdit,
    required this.onDelete,
  });

  void _showDeleteConfirmation(BuildContext context, Reminder reminder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Reminder"),
        content: const Text("Are you sure you want to delete this reminder?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete(reminder);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeReminders = reminders
        .where((r) => !isReminderInPast(r))
        .toList()
      ..sort((a, b) => a.scheduledTime!.compareTo(b.scheduledTime!));

    final pastReminders = reminders
        .where((r) => isReminderInPast(r))
        .toList()
      ..sort((a, b) => a.scheduledTime!.compareTo(b.scheduledTime!));

    return StickyHeader(
      header: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: theme.primaryColorDark.withAlpha(255),
        child: Text(
          groupTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      content: Column(
        children: [
          if (activeReminders.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
                ),
                ...activeReminders.map((reminder) => ReminderCard(
                  reminder: reminder,
                  onEdit: () => onEdit(reminder),
                  onDelete: () => _showDeleteConfirmation(context, reminder),
                )),
              ],
            ),
          if (pastReminders.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
                ),
                ...pastReminders.map((reminder) => ReminderCard(
                  reminder: reminder,
                  onEdit: () => onEdit(reminder),
                  onDelete: () => _showDeleteConfirmation(context, reminder),
                )),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
