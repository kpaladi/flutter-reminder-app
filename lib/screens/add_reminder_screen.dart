import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reminder_app/services/notification_service.dart';
import '../models/reminder_model.dart';
import '../utils/dialogs.dart';
import '../widgets/gradient_scaffold.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  AddReminderScreenState createState() => AddReminderScreenState();
}

class AddReminderScreenState extends State<AddReminderScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  DateTime? selectedDateTime;
  String? repeatType = 'only once';

  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    titleController.addListener(_onFormChanged);
    descriptionController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {
      hasChanges = titleController.text.isNotEmpty ||
          descriptionController.text.isNotEmpty ||
          selectedDateTime != null ||
          repeatType != 'only once';
    });
  }

  void addReminder() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedDateTime == null) {
      return;
    }

    DocumentReference docRef =
    FirebaseFirestore.instance.collection('reminders').doc();

    final reminder = Reminder(
      id: docRef.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      timestamp: selectedDateTime!,
      repeatType: repeatType,
    );

    await docRef.set(reminder.toMap());

    NotificationService().scheduleNotification(reminder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Reminder Added!")),
      );
    }

    titleController.clear();
    descriptionController.clear();
    setState(() {
      selectedDateTime = null;
      repeatType = 'only once';
      hasChanges = false;
    });
  }

  void pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (!mounted || pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (!mounted || pickedTime == null) return;

    setState(() {
      selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _onFormChanged();
    });
  }


  Future<void> importFromCsv(BuildContext context) async {
    try {

      const XTypeGroup typeGroup = XTypeGroup(
        label: 'CSV',
        extensions: ['csv'],
      );

      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) {
        return;
      }

      final input = await file.readAsString();
      final rows = const CsvToListConverter().convert(input);

      if (rows.isEmpty || rows[0].length < 3) {
        throw FormatException('Invalid CSV structure');
      }

      int addedCount = 0;
      int duplicateCount = 0;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final title = row[0]?.toString() ?? '';
        final description = row[1]?.toString() ?? '';
        final timestampStr = row[2]?.toString() ?? '';
        final repeatType = row.length > 3 ? row[3]?.toString() : 'only once';

        if (title.isEmpty || timestampStr.isEmpty) continue;
        final timestamp = DateTime.tryParse(timestampStr);
        if (timestamp == null) continue;

        final query = await FirebaseFirestore.instance
            .collection('reminders')
            .where('title', isEqualTo: title)
            .where('description', isEqualTo: description)
            .where('repeatType', isEqualTo: repeatType)
            .get();

        if (query.docs.isNotEmpty) {
          duplicateCount++;
          continue;
        }

        final reminder = Reminder(
          id: '',
          title: title,
          description: description,
          timestamp: timestamp,
          repeatType: repeatType,
        );

        final docRef = await FirebaseFirestore.instance
            .collection('reminders')
            .add(reminder.toMap());

        final savedReminder = reminder.copyWith(id: docRef.id);
        await NotificationService().scheduleNotification(savedReminder);

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

    } catch (e) { // ✅ catch is now correctly outside the try
      debugPrint("❌ Import failed: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Import failed")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientScaffold(
      appBar: AppBar(
        title: const Text("Add Reminder"),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'import') {
                await runWithLoadingDialog(
                  context: context,
                  message: "Importing reminders...",
                  task: () => importFromCsv(context),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'import',
                child: Text('Import from CSV'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Title",
                labelStyle: TextStyle(color: theme.colorScheme.primary),
                border: const OutlineInputBorder(),
              ),
              cursorColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: "Description",
                labelStyle: TextStyle(color: theme.colorScheme.primary),
                border: const OutlineInputBorder(),
              ),
              cursorColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: pickDateTime,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                selectedDateTime == null
                    ? "Pick Date & Time"
                    : "Selected: ${selectedDateTime!.toLocal().toString()}",
              ),
            ),
            const SizedBox(height: 24),
            if (selectedDateTime != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Repeat Every",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: repeatType,
                    onChanged: (String? newValue) {
                      setState(() {
                        repeatType = newValue!;
                        _onFormChanged();
                      });
                    },
                    items: <String>[
                      'only once',
                      'day',
                      'week',
                      'month',
                      'year'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: "Type",
                      labelStyle: TextStyle(color: theme.colorScheme.primary),
                      border: const OutlineInputBorder(),
                    ),
                    dropdownColor: theme.cardColor,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: hasChanges ? addReminder : null,
              icon: const Icon(Icons.check), // Also updated icon for clarity
              label: const Text("Submit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasChanges
                    ? theme.colorScheme.primary
                    : theme.disabledColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.removeListener(_onFormChanged);
    descriptionController.removeListener(_onFormChanged);
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
