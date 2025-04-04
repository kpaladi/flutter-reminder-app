import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class EditReminderScreen extends StatefulWidget {
  final String reminderId;
  final Map<String, dynamic> reminderData;

  const EditReminderScreen({
    super.key,
    required this.reminderId,
    required this.reminderData,
  });

  @override
  EditReminderScreenState createState() => EditReminderScreenState();
}

class EditReminderScreenState extends State<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDateTime;
  bool _hasChanges = false; // Track if any changes were made

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.reminderData['title']);
    _descriptionController = TextEditingController(text: widget.reminderData['description']);

    if (widget.reminderData['timestamp'] is Timestamp) {
      _selectedDateTime = (widget.reminderData['timestamp'] as Timestamp).toDate();
    } else if (widget.reminderData['timestamp'] is DateTime) {
      _selectedDateTime = widget.reminderData['timestamp'];
    }

    // Listen for text changes
    _titleController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges = _titleController.text != widget.reminderData['title'] ||
          _descriptionController.text != widget.reminderData['description'] ||
          _selectedDateTime != widget.reminderData['timestamp'];
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

    // Update Firestore
    await FirebaseFirestore.instance.collection("reminders").doc(widget.reminderId).update({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'timestamp': _selectedDateTime != null ? Timestamp.fromDate(_selectedDateTime!) : null,
    });

    // Cancel and reschedule notification if time changed
    NotificationService().cancelNotification(widget.reminderId.hashCode);
    NotificationService().scheduleNotification(
      widget.reminderId.hashCode,
      _titleController.text,
      _descriptionController.text,
      _selectedDateTime!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reminder Updated!")));
    }

    // ✅ Reset the state with updated values
    setState(() {
      widget.reminderData['title'] = _titleController.text;
      widget.reminderData['description'] = _descriptionController.text;
      widget.reminderData['timestamp'] = _selectedDateTime;

      _hasChanges = false; // Disable button as no pending changes
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
                textCapitalization: TextCapitalization.sentences,
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (value) => value!.isEmpty ? "Title cannot be empty" : null,
              ),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (value) => value!.isEmpty ? "Description cannot be empty" : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: _pickDateTime,
                    style: TextButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1), // Border
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
              ElevatedButton(
                onPressed: _hasChanges ? _updateReminder : null, // Disable if no changes
                child: const Text("Update Reminder"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
