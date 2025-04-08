import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


class ReminderExportFAB extends StatelessWidget {
  final FirebaseFirestore db;

  const ReminderExportFAB({super.key, required this.db});

  Future<void> _exportReminders(BuildContext context) async {
    try {
      final snapshot = await db.collection("reminders").get();
      final reminders = snapshot.docs.map((doc) => doc.data()).toList();

      final rows = <List<String>>[
        ["Title", "Description", "Timestamp", "Repeat Type"],
        ...reminders.map((r) => [
          r["title"] ?? "",
          r["description"] ?? "",
          r["timestamp"]?.toDate().toString() ?? "",
          r["repeatType"] ?? "only once",
        ]),
      ];

      final csv = const ListToCsvConverter().convert(rows);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/reminders_export.csv';
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
