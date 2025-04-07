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
  final TextEditingController repeatIntervalController = TextEditingController(text: '1');

  DateTime? selectedDateTime;
  String? repeatType = 'only once';
  int? repeatInterval = 1;
  DateTime? repeatEnd;

  bool hasChanges = false;

  @override
  void initState() {
    super.initState();
    titleController.addListener(_onFormChanged);
    descriptionController.addListener(_onFormChanged);
    repeatIntervalController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {
      hasChanges = titleController.text.isNotEmpty ||
          descriptionController.text.isNotEmpty ||
          selectedDateTime != null ||
          repeatType != 'only once' ||
          (int.tryParse(repeatIntervalController.text) ?? 1) != 1 ||
          repeatEnd != null;
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

    repeatInterval = int.tryParse(repeatIntervalController.text) ?? 1;

    final reminder = Reminder(
      id: docRef.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      timestamp: selectedDateTime!,
      repeatType: repeatType,
      repeatInterval: repeatInterval,
      repeatEnd: repeatEnd,
    );

    await docRef.set(reminder.toMap());

    NotificationService().scheduleNotification(reminder);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminder Added!")),
      );
    }

    titleController.clear();
    descriptionController.clear();
    repeatIntervalController.text = '1';
    setState(() {
      selectedDateTime = null;
      repeatType = 'only once';
      repeatInterval = 1;
      repeatEnd = null;
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

  void pickRepeatEndDate() async {
    DateTime? pickedEndDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (!mounted || pickedEndDate == null) return;

    setState(() {
      repeatEnd = pickedEndDate;
      _onFormChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Reminder")),
      body: SingleChildScrollView(
        child: Padding(
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
              if (selectedDateTime != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Repeat Every",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: repeatIntervalController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Interval"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: repeatType,
                            onChanged: (String? newValue) {
                              setState(() {
                                repeatType = newValue!;
                                _onFormChanged();
                              });
                            },
                            items: <String>['only once', 'day', 'week', 'month']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            decoration: const InputDecoration(labelText: "Type"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (repeatType != 'only once')
                      ElevatedButton(
                        onPressed: pickRepeatEndDate,
                        child: Text(
                          repeatEnd == null
                              ? "Select Repeat End Date"
                              : "Repeat Ends: ${repeatEnd!.toLocal().toString()}",
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: hasChanges ? addReminder : null,
                child: const Text("Add Reminder"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
