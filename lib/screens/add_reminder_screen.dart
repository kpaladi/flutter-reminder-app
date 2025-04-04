import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reminder_app/services/notification_service.dart';

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

    DocumentReference docRef = await FirebaseFirestore.instance
        .collection('reminders')
        .add({
          'title': titleController.text,
          'description': descriptionController.text,
          'timestamp': selectedDateTime,
        });

    // Schedule Notification
    NotificationService().scheduleNotification(
      docRef.id.hashCode, // Convert Firestore ID to int hash
      titleController.text,
      descriptionController.text,
      selectedDateTime!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminder Added!")),
      );
    }

    // Clear inputs
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
      appBar: AppBar(title: Text("Add Reminder")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: titleController,
              decoration: InputDecoration(labelText: "Title"),
            ),
            TextField(
              textCapitalization: TextCapitalization.sentences,
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Description"),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickDateTime,
              child: Text(
                selectedDateTime == null
                    ? "Pick Date & Time"
                    : "Selected: ${selectedDateTime!.toLocal().toString()}",
              ),
            ),
            SizedBox(height: 20),
        ElevatedButton(
          onPressed: hasChanges ? addReminder : null,
          child: Text("Add Reminder"),
        ),
          ],
        ),
      ),
    );
  }
}
