import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';

class EditReminderScreen extends StatefulWidget {
  final Reminder reminder;

  const EditReminderScreen({super.key, required this.reminder});

  @override
  EditReminderScreenState createState() => EditReminderScreenState();
}

class EditReminderScreenState extends State<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDateTime;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(text: widget.reminder.description);
    _selectedDateTime = widget.reminder.timestamp;

    _titleController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges = _titleController.text != widget.reminder.title ||
          _descriptionController.text != widget.reminder.description ||
          _selectedDateTime != widget.reminder.timestamp;
    });
  }

  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (!mounted || pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
    );

    if (!mounted || pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _checkForChanges();
    });
  }

  Future<void> _updateReminder() async {
    if (!_hasChanges) return;

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid date and time")),
      );
      return;
    }

    await NotificationService().cancelNotification(widget.reminder.id);

    Reminder updated = Reminder(
      id: widget.reminder.id,
      title: _titleController.text,
      description: _descriptionController.text,
      timestamp: _selectedDateTime,
    );

    await FirebaseFirestore.instance
        .collection("reminders")
        .doc(updated.id)
        .update(updated.toMap());

    NotificationService().scheduleNotification(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminder Updated!")),
      );
    }

    setState(() {
      _hasChanges = false;
    });
  }

  void _resetChanges() {
    setState(() {
      _titleController.text = widget.reminder.title;
      _descriptionController.text = widget.reminder.description;
      _selectedDateTime = widget.reminder.timestamp;
      _hasChanges = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Reminder")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) => value!.isEmpty ? "Title cannot be empty" : null,
              ),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) => value!.isEmpty ? "Description cannot be empty" : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: _pickDateTime,
                    style: TextButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text("Pick Date & Time"),
                  ),
                  const Spacer(),
                  Text(
                    _selectedDateTime != null
                        ? DateFormat('dd-MM-yyyy HH:mm').format(_selectedDateTime!)
                        : "No Date Selected",
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _hasChanges ? _updateReminder : null,
                    child: const Text("Update Reminder"),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _hasChanges ? _resetChanges : null,
                    child: const Text("Reset"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
