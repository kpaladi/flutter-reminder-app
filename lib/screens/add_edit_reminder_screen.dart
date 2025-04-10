import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/import_csv.dart';
import '../services/notification_service.dart';
import '../utils/dialogs.dart';
import '../widgets/app_reset_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/shared_widgets.dart'; // Import shared widgets

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddEditReminderScreen({super.key, this.reminder});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  DateTime? selectedDateTime;
  String repeatType = 'once';
  bool hasChanges = false;

  // Flag to determine if we're editing an existing reminder
  bool get isEditing => widget.reminder != null;

  late String initialRepeatType;
  late String initialTitle;
  late String initialDescription;
  late DateTime? initialDateTime;

  @override
  void initState() {
    super.initState();

    initialTitle = widget.reminder?.title ?? '';
    initialDescription = widget.reminder?.description ?? '';
    initialDateTime = widget.reminder?.scheduledTime;
    initialRepeatType = widget.reminder?.repeatType ?? 'once';

    titleController.text = initialTitle;
    descriptionController.text = initialDescription;
    selectedDateTime = initialDateTime;
    repeatType = initialRepeatType;

    titleController.addListener(_onFormChanged);
    descriptionController.addListener(_onFormChanged);
  }

  void pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final now = DateTime.now();
    final initialTime = TimeOfDay(hour: now.hour, minute: now.minute + 1);

    if (!mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null) return;

    setState(() {
      selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      hasChanges = true;
    });
  }

  /*  void _onFormChanged() {
    setState(() {
      hasChanges = true;
    });
  }*/

  void _onFormChanged() {
    final titleChanged = titleController.text != initialTitle;
    final descriptionChanged = descriptionController.text != initialDescription;
    final dateTimeChanged = selectedDateTime != initialDateTime;
    final repeatTypeChanged = repeatType != initialRepeatType;

    setState(() {
      hasChanges =
          titleChanged ||
          descriptionChanged ||
          dateTimeChanged ||
          repeatTypeChanged;
    });
  }

  void saveReminder() async {
    final now = DateTime.now();
    if (selectedDateTime == null || selectedDateTime!.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a future date and time.")),
      );
      return;
    }

    final docRef =
        isEditing
            ? FirebaseFirestore.instance
                .collection('reminders')
                .doc(widget.reminder!.reminder_id)
            : FirebaseFirestore.instance.collection('reminders').doc();

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

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ Reminder saved!")));
      }

      setState(() {
        hasChanges = false;
        titleController.clear();
        descriptionController.clear();
        selectedDateTime = null;
        repeatType = 'once';
      });

      if (!mounted) {
        return;
      }

      FocusScope.of(context).requestFocus(_titleFocusNode);
    } catch (e) {
      debugPrint("❌ Failed to save reminder: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to save reminder.")),
        );
      }
    }
  }

  void _resetToInitialValues() {
    setState(() {
      hasChanges = false;

      if (widget.reminder == null) {
        titleController.clear();
        descriptionController.clear();
        selectedDateTime = null;
        repeatType = 'once';
      } else {
        titleController.text = initialTitle;
        descriptionController.text = initialDescription;
        selectedDateTime = initialDateTime;
        repeatType = initialRepeatType;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Reminder" : "Add Reminder"),
        centerTitle: true,
        actions: [
          // Conditionally show Import from CSV only in Add mode.
          if (widget.reminder == null)
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
              itemBuilder:
                  (_) => [
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
              isFormField: true,
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
              isFormField: false,
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
                  const Text(
                    "Repeat Every",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                    items: const [
                      'once',
                      'daily',
                      'weekly',
                      'monthly',
                      'yearly',
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSubmitButton(onPressed: hasChanges ? saveReminder : null),
                AppResetButton(
                  onPressed: _resetToInitialValues,
                  isEnabled: hasChanges,
                  showIcon: true,
                ),
              ],
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
