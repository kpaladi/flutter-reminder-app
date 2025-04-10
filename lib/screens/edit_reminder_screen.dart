import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../widgets/app_reset_button.dart';
import '../widgets/gradient_scaffold.dart';

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
  String? _repeatType;
  bool _hasChanges = false;

  late String _initialTitle;
  late String _initialDescription;
  late DateTime? _initialscheduledTime;
  String? _initialRepeatType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(text: widget.reminder.description);

    _selectedDateTime = widget.reminder.scheduledTime;
    _repeatType = widget.reminder.repeatType ?? 'once';

    _initialTitle = widget.reminder.title;
    _initialDescription = widget.reminder.description;
    _initialscheduledTime = widget.reminder.scheduledTime;
    _initialRepeatType = _repeatType;

    _titleController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
  }


  void _checkForChanges() {
    _hasChanges =
        _titleController.text != _initialTitle ||
            _descriptionController.text != _initialDescription ||
            _selectedDateTime != _initialscheduledTime ||
            _repeatType != _initialRepeatType;
    setState(() {});
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

    await NotificationService().cancelNotification(widget.reminder.notification_id);

    Reminder updated = Reminder(
      reminder_id: widget.reminder.reminder_id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      scheduledTime: _selectedDateTime!,
      repeatType: _repeatType,
      notification_id: widget.reminder.notification_id,
    );

    await FirebaseFirestore.instance
        .collection("reminders")
        .doc(updated.reminder_id)
        .update(updated.toMap());

    NotificationService().scheduleNotification(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reminder Updated!")),
      );
    }

    setState(() {
      _initialTitle = _titleController.text;
      _initialDescription = _descriptionController.text;
      _initialscheduledTime = _selectedDateTime!;
      _initialRepeatType = _repeatType;
      _hasChanges = false;
    });
  }

  void _resetChanges() {
    final r = widget.reminder;
    setState(() {
      _titleController.text = r.title;
      _descriptionController.text = r.description;
      _selectedDateTime = r.scheduledTime;
      _repeatType = r.repeatType ?? 'once';
      _hasChanges = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text("Edit Reminder")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) => value!.isEmpty ? "Title cannot be empty" : null,
              ),
              const SizedBox(height: 16),
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
                    child: const Text("Schedule"),
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
              if (_selectedDateTime != null)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Repeat Type", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 20),
                        DropdownButton<String>(
                          value: _repeatType,
                          onChanged: (String? newValue) {
                            setState(() {
                              _repeatType = newValue!;
                              _checkForChanges();
                            });
                          },
                          items: <String>['once', 'daily', 'weekly', 'monthly', 'yearly']
                              .map((String value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _hasChanges ? _updateReminder : null,
                    child: const Text("Update Reminder"),
                  ),
                  AppResetButton(
                    onPressed: _resetChanges,
                    isEnabled: _hasChanges,
                    showIcon: false,
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
