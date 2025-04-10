import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportToCsv(BuildContext context, List<Map<String, dynamic>> reminders) async {
  try {
    // Step 1: Prepare CSV headers
    final headers = [
      'reminder_id',
      'title',
      'description',
      'scheduledTime',
      'repeatType',
      'createdAt',
      'priority',
      'importance',
    ];

    // Step 2: Convert each reminder to a row
    final rows = <List<dynamic>>[headers];
    for (var reminder in reminders) {
      rows.add([
        reminder['reminder_id'] ?? '',
        reminder['title'] ?? '',
        reminder['description'] ?? '',
        reminder['scheduledTime'] ?? '',
        reminder['repeatType'] ?? '',
        reminder['createdAt'] ?? '',
        reminder['priority'] ?? '',
        reminder['importance'] ?? '',
      ]);
    }

    // Step 3: Convert to CSV string
    final csv = const ListToCsvConverter().convert(rows);

    // Step 4: Save to file
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reminders_export.csv');
    await file.writeAsString(csv);

    // Step 5: Share or notify
    await Share.shareXFiles([XFile(file.path)], text: 'Exported reminders CSV');

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV Export failed: $e')),
    );
  }
}
