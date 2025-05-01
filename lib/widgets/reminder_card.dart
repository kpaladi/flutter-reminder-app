import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/reminder_model.dart';
import '../services/whatsapp_service.dart' as whatsappservice;
import '../utils/reminder_utils.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final void Function() onEdit;
  final void Function() onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = isReminderInPast(reminder);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isPast ? Colors.grey.shade300 : theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: isPast ? Colors.grey.shade600 : theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reminder.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isPast ? Colors.grey.shade500 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: isPast ? Colors.grey[500] : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    buildRepeatSummary(reminder),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isPast ? Colors.grey.shade500 : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                  tooltip: 'Share via WhatsApp',
                  onPressed: () {
                    whatsappservice.sendReminder(context: context, reminder: reminder);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}