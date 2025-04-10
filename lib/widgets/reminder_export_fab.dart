import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/constants.dart';


class ReminderExportFAB extends StatelessWidget {
  final FirebaseFirestore db;

  const ReminderExportFAB({super.key, required this.db});

  Future<void> _exportReminders(BuildContext context) async {
    try {
      final snapshot = await db.collection("reminders").get();
      final reminders = snapshot.docs.map((doc) {
        final data = doc.data();
        data['reminder_id'] = doc.id; // Include document ID explicitly
        return data;
      }).toList();

      final rows = <List<String>>[
        ["Title", "Description", "Scheduled Date", "Repeat Type", "ID (do not change)",],
        ...reminders.map((r) => [
          r["title"] ?? "",
          r["description"] ?? "",
          r["scheduledTime"].toDate().toString() ?? "",
          r["repeatType"] ?? "once",
          r["reminder_id"] ?? "",
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
