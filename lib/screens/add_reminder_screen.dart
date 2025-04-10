import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/import_csv.dart';
import '../services/notification_service.dart';
import '../utils/dialogs.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/shared_widgets.dart'; // Import the shared widgets

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  DateTime? selectedDateTime;
  String repeatType = 'once';
  bool hasChanges = false;

  void pickDateTime() async {
    // Pick the date first
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 1)),  // Start with 1 minute in the future
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return; // If the user cancels, return

    // Get the current time and set it to one minute in the future
    final now = DateTime.now();
    final initialTime = TimeOfDay(
      hour: now.hour,
      minute: now.minute + 1, // One minute after the current time
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime, // Use the current time plus one minute
    );

    if (pickedTime == null) return; // If the user cancels, return

    // Now update the date and time using the selected date and time
    setState(() {
      selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _onFormChanged() {
    setState(() {
      hasChanges = true;
    });
  }

  void addReminder() async {
    final now = DateTime.now();
    if (selectedDateTime == null || selectedDateTime!.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a future date and time.")),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('reminders').doc();
    final reminder = Reminder(
      reminder_id: docRef.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      scheduledTime: selectedDateTime!,
      repeatType: repeatType,
      notification_id: Reminder.generateStableId(docRef.id),
    );

    try {
      await docRef.set(reminder.toMap());
      await NotificationService().scheduleNotification(reminder);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Reminder added!")),
        );
      }

      setState(() {
        hasChanges = false;
        titleController.clear();
        descriptionController.clear();
        selectedDateTime = null;
        repeatType = 'once';
      });

      FocusScope.of(context).requestFocus(_titleFocusNode);
    } catch (e) {
      debugPrint("❌ Failed to add reminder: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to add reminder.")),
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
            itemBuilder: (_) => [
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
            AppTextField(
              controller: titleController,
              label: "Title",
              focusNode: _titleFocusNode,
              isFormField: true, // Use form field validation here
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: descriptionController,
              label: "Description",
              isFormField: false, // No validation needed here
            ),
            const SizedBox(height: 16),
            buildDateTimePickerButton(
              context: context,
              onPressed: pickDateTime,
              selectedDateTime: selectedDateTime,
            ),
            const SizedBox(height: 24),
            if (selectedDateTime != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Repeat Every", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  AppDropdown(
                    label: "Type",
                    value: repeatType,
                    onChanged: (newValue) {
                      setState(() {
                        repeatType = newValue!;
                        _onFormChanged();
                      });
                    },
                    items: const ['once', 'daily', 'weekly', 'monthly', 'yearly'],
                  ),
                ],
              ),
            const SizedBox(height: 24),
            AppSubmitButton(
              onPressed: hasChanges ? addReminder : null,
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
    _titleFocusNode.dispose();
    super.dispose();
  }
}