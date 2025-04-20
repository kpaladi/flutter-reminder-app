import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/whatsapp_service.dart' as whatsappservice;
import '../utils/reminder_utils.dart';
import 'add_edit_reminder_screen.dart';

class ReminderDetailScreen extends StatelessWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  Future<Reminder> _loadReminder() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('reminders')
            .doc(reminderId)
            .get();
    return Reminder.fromFirestore(doc);
  }

  void _confirmDelete(BuildContext context, Reminder reminder) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Reminder'),
            content: const Text(
              'Are you sure you want to delete this reminder?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              TextButton(
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop(); // close the dialog
                  await _deleteReminder(context, reminder); // pass it here
                },
              ),
            ],
          ),
    );
  }

  Future<void> _deleteReminder(BuildContext context, Reminder reminder) async {
    await FirebaseFirestore.instance
        .collection('reminders')
        .doc(reminder.reminder_id)
        .delete();

    await NotificationService().cancelNotification(reminder.notification_id);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));

    Navigator.pop(context); // Close detail screen
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Reminder>(
      future: _loadReminder(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Failed to load reminder.')),
          );
        }

        final reminder = snapshot.data!;
        var nextOccurence = getNextOccurrence(reminder);
        var currentOccurence = reminder.scheduledTime;

        return Scaffold(
          appBar: AppBar(
            title: Text('Reminder Details'),
            actions: [
              IconButton(
                icon: Icon(Icons.share),
                tooltip: 'Share via WhatsApp',
                onPressed:
                    () => whatsappservice.sendReminder(
                      context: context,
                      reminder: reminder,
                    ),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditReminderScreen(reminder: reminder),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.teal.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.title, color: Colors.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reminder.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  color: Colors.teal.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.description, color: Colors.deepPurple),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reminder.description,
                                style: Theme.of(context).textTheme.bodyLarge,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.repeat, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'Repeat Type: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: reminder.repeatType ?? 'None',
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (nextOccurence != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.schedule, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Next reminder: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: DateFormat(
                                          'EEE, MMM d y • hh:mm a',
                                        ).format(nextOccurence),
                                        style: TextStyle(
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                        if (nextOccurence == null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.schedule, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Was scheduled for: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: DateFormat(
                                          'EEE, MMM d y • hh:mm a',
                                        ).format(currentOccurence!),
                                        style: TextStyle(
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.delete, color: Colors.white),
                      label: Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _confirmDelete(context, reminder),
                    ),
                    OutlinedButton.icon(
                      icon: Icon(Icons.close),
                      label: Text('Close'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
