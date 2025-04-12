import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reminder_app/services/notification_service.dart';
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
        final existingDoc = await FirebaseFirestore.instance
            .collection('reminders')
            .doc(reminderId)
            .get();

        if (existingDoc.exists) {
          final existingData = existingDoc.data();
          final existingNotificationId = existingData?['notification_id'];

          final reminder = Reminder(
            reminder_id: reminderId,
            title: title,
            description: description,
            scheduledTime: scheduledTime,
            repeatType: repeatType,
            notification_id: existingNotificationId ??
                Reminder.generateStableId(reminderId),
          );

          await FirebaseFirestore.instance
              .collection('reminders')
              .doc(reminderId)
              .set(reminder.toMap());

          await NotificationService().scheduleNotification(reminder);
          addedCount++;
          continue;
        }
      }

      // ✅ Check for duplicates (match by content — not by timestamp only)
      try {
        final query = await FirebaseFirestore.instance
            .collection('reminders')
            .where('title', isEqualTo: title)
            .where('description', isEqualTo: description)
            .get();

        print("Query successful. Found: ${query.docs.length}");
        if (query.docs.isNotEmpty) {
          debugPrint("🔍 Duplicate check: found ${query.docs.length} existing reminders");
          duplicateCount++;
          continue;
        }
      } catch (e, stackTrace) {
        print("🔥 Firestore query failed: $e");
      }



      // Create new reminder
      final docRef = FirebaseFirestore.instance.collection('reminders').doc();
      final newReminder = Reminder(
        reminder_id: docRef.id,
        title: title,
        description: description,
        scheduledTime: scheduledTime,
        repeatType: repeatType,
        notification_id: Reminder.generateStableId(docRef.id),
      );

      await docRef.set(newReminder.toMap());
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
