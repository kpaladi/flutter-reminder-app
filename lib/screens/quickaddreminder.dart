import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';

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

  DateTime? parseDateTime(String input) {
    final now = DateTime.now();
    String cleaned = input
        .replaceAll(RegExp(r'(\d+)(st|nd|rd|th)'), r'\1') // 15th -> 15
        .replaceAll(RegExp(r'\bat\b'), '') // remove filler like 'at'
        .replaceAll(RegExp(r'\bon\b'), '')
        .replaceAll(',', '')
        .toLowerCase()
        .trim();

    final monthMap = {
      'january': 'Jan',
      'february': 'Feb',
      'march': 'Mar',
      'april': 'Apr',
      'may': 'May',
      'june': 'Jun',
      'july': 'Jul',
      'august': 'Aug',
      'september': 'Sep',
      'october': 'Oct',
      'november': 'Nov',
      'december': 'Dec',
    };

    // Replace full month names with abbreviated ones
    monthMap.forEach((full, short) {
      cleaned = cleaned.replaceAll(RegExp(r'\b$full\b'), short);
    });

    final formats = [
      'd MMM yyyy HH:mm',
      'd MMM yyyy h:mm a',
      'd MMM yyyy h a',
      'd MMM HH:mm',
      'd MMM h:mm a',
      'd MMM h a',
      'MMM d yyyy HH:mm',
      'MMM d yyyy h:mm a',
      'MMM d HH:mm',
      'MMM d h:mm a',
      'MMM d h a',
      'd MMM', // fallback date only
      'MMM d', // fallback date only
    ];

    for (final format in formats) {
      try {
        final formatter = DateFormat(format);
        final parsed = formatter.parse(cleaned);
        // If parsed without year, assume current year
        if (!format.contains('yyyy')) {
          return DateTime(now.year, parsed.month, parsed.day, parsed.hour, parsed.minute);
        }
        return parsed;
      } catch (_) {}
    }

    return null;
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
