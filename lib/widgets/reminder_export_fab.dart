import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/constants.dart';
import '../services/reminder_repository.dart';


class ReminderExportFAB extends StatelessWidget {
  final ReminderRepository repository;

  const ReminderExportFAB({super.key, required this.repository});

  Future<void> _exportReminders(BuildContext context) async {
    try {
      // Fetch reminders using repository
      final reminders = await repository.getAllReminders();

      final rows = <List<String>>[
        ["Title", "Description", "Scheduled Time", "Repeat Type", "ID (do not change)"],
        ...reminders.map((r) => [
          r.title, // If title is null, use an empty string
          r.description, // If description is null, use an empty string
          r.scheduledTime != null ? r.scheduledTime.toString() : "",
          r.repeatType ?? "once", // If repeatType is null, use "once"
          r.reminderId, // If reminder_id is null, use an empty string
        ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$exportFilePrefix-${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'My exported reminders');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.file_upload),
      label: const Text("Export"),
      onPressed: () => _exportReminders(context),
    );
  }
}
