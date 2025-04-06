import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reminder_app/services/notification_service.dart';
import '../models/reminder_model.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  AddReminderScreenState createState() => AddReminderScreenState();
}

class AddReminderScreenState extends State<AddReminderScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? selectedDateTime;

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
          selectedDateTime != null;
    });
  }

  void addReminder() async {
    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        selectedDateTime == null) {
      return;
    }

    // Step 1: Create a new document reference with auto ID
    DocumentReference docRef =
    FirebaseFirestore.instance.collection('reminders').doc();

    // Step 2: Construct Reminder with generated ID
    final reminder = Reminder(
      id: docRef.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      timestamp: selectedDateTime!,
    );

    // Step 3: Save to Firestore
    await docRef.set(reminder.toMap());

    // Step 4: Schedule Notification using model's notificationId getter
    NotificationService().scheduleNotification(reminder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminder Added!")),
      );
    }

    // Step 5: Clear inputs
    titleController.clear();
    descriptionController.clear();
    setState(() {
      selectedDateTime = null;
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
      _onFormChanged(); // Update change flag
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Reminder")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickDateTime,
              child: Text(
                selectedDateTime == null
                    ? "Pick Date & Time"
                    : "Selected: ${selectedDateTime!.toLocal().toString()}",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: hasChanges ? addReminder : null,
              child: const Text("Add Reminder"),
            ),
          ],
        ),
      ),
    );
  }
}
