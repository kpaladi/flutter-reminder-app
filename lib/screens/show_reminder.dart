import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/reminder_model.dart';
import '../services/whatsapp_service.dart' as WhatsAppService;
import 'add_edit_reminder_screen.dart';

class ReminderDetailScreen extends StatelessWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  Future<Reminder> _loadReminder() async {
    final doc = await FirebaseFirestore.instance
        .collection('reminders')
        .doc(reminderId)
        .get();
    return Reminder.fromFirestore(doc);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Reminder>(
      future: _loadReminder(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('Failed to load reminder.')));
        }

        final reminder = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text('Reminder Details'),
            actions: [
              IconButton(
                icon: Icon(Icons.share),
                tooltip: 'Share via WhatsApp',
                onPressed: () => WhatsAppService.sendReminder(context: context, reminder: reminder),
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
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(reminder.description),
                const SizedBox(height: 8),
                Text('Repeat Type: ${reminder.repeatType}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
