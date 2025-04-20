import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../utils/date_parser.dart';

class QuickAddReminderWidget extends StatefulWidget {
  final void Function(Reminder reminder) onReminderCreated;

  const QuickAddReminderWidget({super.key, required this.onReminderCreated});

  @override
  State<QuickAddReminderWidget> createState() => _QuickAddReminderWidgetState();
}

class _QuickAddReminderWidgetState extends State<QuickAddReminderWidget> {
  final TextEditingController _inputController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  List<String> _smartSplit(String input) {
    final regex = RegExp(r'(?<!\\),');
    return input
        .split(regex)
        .map((s) => s.replaceAll(r'\,', ',').trim())
        .toList();
  }

  Future<void> _handleQuickAdd() async {
    setState(() => _error = null);

    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    const supportedRepeatTypes = [
      'once',
      'daily',
      'weekly',
      'monthly',
      'yearly',
    ];

    final parts = _smartSplit(input);
    if (parts.length < 4) {
      setState(
        () =>
            _error = 'Please enter at least: title, description, date, repeat',
      );
      return;
    }

    final title = parts[0];
    final description = parts[1];
    final String dateStr = parts[2]; // <-- keep as string
    final repeat = parts[3].toLowerCase();

    if (!supportedRepeatTypes.contains(repeat)) {
      setState(
        () =>
            _error =
                'Repeat type must be one of: ${supportedRepeatTypes.join(', ')}',
      );
      return;
    }

    final parsedDate = parseDateTime(dateStr); // ✅ parse correctly
    if (parsedDate == null) {
      setState(() => _error = 'Could not parse date. Try: "20th April 20:00"');
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('reminders').doc();
    final newReminder = Reminder(
      reminder_id: docRef.id,
      title: title,
      description: description,
      scheduledTime: parsedDate,
      // ✅ use parsed date
      repeatType: repeat,
      notification_id: Reminder.generateStableId(docRef.id),
    );

    await docRef.set(newReminder.toMap());
    await NotificationService().scheduleNotification(newReminder);

    widget.onReminderCreated(newReminder);
    _inputController.clear();
    if (!mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Quick Add Reminder',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _inputController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'e.g. Movie Night, Watch Lala land\\, with friends, 20th April 20:00, once',
                border: OutlineInputBorder(),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.bolt),
              label: const Text('Quick Add'),
              onPressed: _handleQuickAdd,
            ),
          ],
        ),
      ),
    );
  }
}
