import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/services/notification_service.dart';
import 'package:reminder_app/services/reminder_repository.dart';
import '../models/reminder_model.dart';

bool hasHeaderRow(List<String> row) {
  // Normalize all entries to lowercase
  final normalized = row.map((e) => e.trim().toLowerCase()).toList();

  // Define expected header keywords
  final expectedHeaders = ['title', 'description', 'scheduled time', 'repeat type'];

  // Count how many expected headers are found in the first row
  int matchCount = expectedHeaders.where((header) => normalized.contains(header)).length;

  // Heuristic: If at least 2 known headers are found, it's likely a header row
  return matchCount >= 2;
}

Future<void> importFromCsv(BuildContext context) async {
  try {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'CSV',
      extensions: ['csv'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    final input = await file.readAsString();
    final rows = const CsvToListConverter().convert(input);

    if (rows.isEmpty || rows[0].length < 4) {
      throw FormatException('Invalid CSV structure');
    }

    var startingDataRow = 0;
    final firstRow = rows.first.map((e) => e.toString()).toList();
    if(hasHeaderRow(firstRow)){
      startingDataRow = 1;
    }

    int addedCount = 0;
    int duplicateCount = 0;

    final user = FirebaseAuth.instance.currentUser;
    ReminderRepository repository;

    if (user == null) {
      debugPrint("user need to logged in for import");
      return;
    } else {
      final userId = user.uid; // Extract the uid (userId) from the User object
      repository = ReminderRepository(userId: userId);
    }


    for (int i = startingDataRow; i < rows.length; i++) {
      final row = rows[i];

      final title = row[0]?.toString().trim() ?? '';
      final description = row[1]?.toString().trim() ?? '';
      final scheduledTimeStr = row[2]?.toString() ?? '';
      final repeatType = row[3]?.toString().trim().toLowerCase() ?? 'once';
      final reminderId = row.length > 4 ? row[4]?.toString() : null;

      if (title.isEmpty || scheduledTimeStr.isEmpty) continue;
      final scheduledTime = DateTime.tryParse(scheduledTimeStr);
      if (scheduledTime == null) continue;

      const supportedRepeatTypes = ['once', 'daily', 'weekly', 'monthly', 'yearly'];
      if (!supportedRepeatTypes.contains(repeatType)) continue;

      // If reminder_id exists: treat as update
      if (reminderId != null && reminderId.isNotEmpty) {
        final existingReminder = await repository.getReminderById(reminderId);

        if (existingReminder != null) {
          final reminder = Reminder(
            reminderId: reminderId,
            title: title,
            description: description,
            scheduledTime: scheduledTime,
            repeatType: repeatType,
            notificationId: existingReminder.notificationId,
          );

          await repository.updateReminder(reminder);

          await NotificationService().scheduleNotification(reminder);
          addedCount++;
          continue;
        }
      }

      // ✅ Check for duplicates (match by content — not by timestamp only)
      try {
        final query = await repository.getReminders();
        if (query.any((existingReminder) =>
        existingReminder.title == title &&
            existingReminder.description == description)) {
          debugPrint("🔍 Duplicate check: found existing reminders");
          duplicateCount++;
          continue;
        }
      } catch (e) {
        debugPrint("🔥 Repository query failed: $e");
      }

      // Create new reminder
      final newReminder = Reminder(
        reminderId: repository.getNewReminderId(),
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        repeatType: repeatType,
        notificationId: Reminder.generateStableId(repository.getNewReminderId()),
      );

      await repository.addReminder(newReminder);
      await NotificationService().scheduleNotification(newReminder);
      addedCount++;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Imported $addedCount reminders, ignored $duplicateCount duplicates",
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint("❌ Import failed: $e");
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Import failed")),
      );
    }
  }
}
