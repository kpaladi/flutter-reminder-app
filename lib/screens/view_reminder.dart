import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/reminder_repository.dart';
import '../services/whatsapp_service.dart' as whatsappservice;
import '../theme/app_colors.dart';
import '../utils/reminder_utils.dart';
import 'add_edit_reminder_screen.dart';

class ReminderDetailScreen extends StatelessWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  Future<Reminder> _loadReminder(ReminderRepository repository) async {
    final reminder = await repository.getReminderById(reminderId);
    if (reminder == null) {
      throw Exception('Reminder not found');
    }
    return reminder;
  }

  void _confirmDelete(BuildContext context, Reminder reminder, ReminderRepository repository) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              await NotificationService().cancelNotification(reminder.notificationId);
              await _deleteReminder(context, reminder, repository);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReminder(
      BuildContext context, Reminder reminder, ReminderRepository repository) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await repository.deleteReminder(reminder.reminderId);
    await NotificationService().cancelNotification(reminder.notificationId);

    messenger.showSnackBar(const SnackBar(content: Text('Reminder deleted')));
    navigator.pop(); // Close detail screen
  }

  @override
  Widget build(BuildContext context) {
    final repository = Provider.of<ReminderRepository>(context, listen: false);

    return FutureBuilder<Reminder>(
      future: _loadReminder(repository),
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
        var nextOccurrence = getNextOccurrence(reminder);
        var currentOccurrence = reminder.scheduledTime;

        return Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            title: const Text('Reminder'),
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.black),
                tooltip: 'Share via WhatsApp',
                onPressed: () {
                  whatsappservice.sendReminder(context: context, reminder: reminder);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF000000)),
                tooltip: 'Edit',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AddEditReminderScreen(reminder: reminder,),
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
                        _infoRow(Icons.title, reminder.title, context, Colors.teal, isTitle: true),
                        const SizedBox(height: 12),
                        _infoRow(Icons.description, reminder.description, context, Colors.deepPurple),
                        const SizedBox(height: 12),
                        _infoRow(Icons.repeat, 'Repeat Type: ${reminder.repeatType ?? 'None'}',
                            context, Colors.orange),
                        const SizedBox(height: 12),
                        if (nextOccurrence != null)
                          _infoRow(Icons.schedule,
                              'Next reminder: ${DateFormat('EEE, MMM d y • hh:mm a').format(nextOccurrence)}',
                              context, Colors.blue)
                        else
                          _infoRow(Icons.schedule,
                              'Was scheduled for: ${DateFormat('EEE, MMM d y • hh:mm a').format(currentOccurrence!)}',
                              context, Colors.blue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: Text(
                        'Delete',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 8,
                      ),
                      onPressed: () => _confirmDelete(context, reminder, repository),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: Text(
                        'Close',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 8,
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

  Widget _infoRow(IconData icon, String text, BuildContext context, Color iconColor, {bool isTitle = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: isTitle
                ? Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: iconColor,  // Use the iconColor directly here
              fontWeight: FontWeight.bold,
            )
                : Theme.of(context).textTheme.bodyLarge,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
