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
  late TextEditingController _repeatIntervalController;

  DateTime? _selectedDateTime;
  String? _repeatType;
  int? _repeatInterval;
  DateTime? _repeatEnd;
  bool _hasChanges = false;

  late String _initialTitle;
  late String _initialDescription;
  late DateTime? _initialTimestamp;
  String? _initialRepeatType;
  int? _initialRepeatInterval;
  DateTime? _initialRepeatEnd;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(text: widget.reminder.description);
    _repeatIntervalController = TextEditingController(
      text: (widget.reminder.repeatInterval ?? 1).toString(),
    );

    _selectedDateTime = widget.reminder.timestamp;
    _repeatType = widget.reminder.repeatType ?? 'only once';
    _repeatInterval = widget.reminder.repeatInterval ?? 1;
    _repeatEnd = widget.reminder.repeatEnd;

    _initialTitle = widget.reminder.title;
    _initialDescription = widget.reminder.description;
    _initialTimestamp = widget.reminder.timestamp;
    _initialRepeatType = _repeatType;
    _initialRepeatInterval = _repeatInterval;
    _initialRepeatEnd = _repeatEnd;

    _titleController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
    _repeatIntervalController.addListener(_onRepeatIntervalChanged);
  }

  void _onRepeatIntervalChanged() {
    final val = int.tryParse(_repeatIntervalController.text.trim());
    if (val != null && val != _repeatInterval) {
      setState(() {
        _repeatInterval = val;
        _checkForChanges();
      });
    }
  }

  void _checkForChanges() {
    _hasChanges =
        _titleController.text != _initialTitle ||
            _descriptionController.text != _initialDescription ||
            _selectedDateTime != _initialTimestamp ||
            _repeatType != _initialRepeatType ||
            (_repeatType != 'only once' && _repeatInterval != _initialRepeatInterval) ||
            (_repeatType != 'only once' && _repeatEnd != _initialRepeatEnd);
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

  Future<void> _pickRepeatEndDate() async {
    DateTime? pickedEndDate = await showDatePicker(
      context: context,
      initialDate: _repeatEnd ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (!mounted || pickedEndDate == null) return;

    setState(() {
      _repeatEnd = pickedEndDate;
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
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      timestamp: _selectedDateTime!,
      repeatType: _repeatType,
      repeatInterval: _repeatType != 'only once' ? _repeatInterval : null,
      repeatEnd: _repeatType != 'only once' ? _repeatEnd : null,
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
      _initialTitle = _titleController.text;
      _initialDescription = _descriptionController.text;
      _initialTimestamp = _selectedDateTime!;
      _initialRepeatType = _repeatType;
      _initialRepeatInterval = _repeatInterval;
      _initialRepeatEnd = _repeatEnd;
      _hasChanges = false;
    });
  }

  void _resetChanges() {
    final r = widget.reminder;
    setState(() {
      _titleController.text = r.title;
      _descriptionController.text = r.description;
      _selectedDateTime = r.timestamp;
      _repeatType = r.repeatType ?? 'only once';
      _repeatInterval = r.repeatInterval ?? 1;
      _repeatIntervalController.text = _repeatInterval.toString();
      _repeatEnd = r.repeatEnd;
      _hasChanges = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _repeatIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          items: <String>['only once', 'day', 'week', 'month', 'year']
                              .map((String value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_repeatType != 'only once')
                      TextFormField(
                        controller: _repeatIntervalController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Repeat Interval"),
                      ),
                    const SizedBox(height: 10),
                    if (_repeatType != 'only once')
                      ElevatedButton(
                        onPressed: _pickRepeatEndDate,
                        child: Text(_repeatEnd == null
                            ? "Select Repeat End Date"
                            : "Repeat Ends: ${DateFormat('dd-MM-yyyy').format(_repeatEnd!)}"),
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
