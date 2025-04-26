import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:reminder_app/screens/quickaddreminder.dart';
import '../models/reminder_model.dart';
import '../services/import_csv.dart';
import '../services/notification_service.dart';
import '../services/reminder_repository.dart';
import '../utils/dialogs.dart';
import '../widgets/app_reset_button.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/shared_widgets.dart';

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddEditReminderScreen({
    super.key,
    this.reminder,
  });

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

  bool get isEditing => widget.reminder != null;

  late String initialRepeatType;
  late String initialTitle;
  late String initialDescription;
  late DateTime? initialDateTime;
  String submitString = "Add Reminder";
  String updateString = "Update Reminder";

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;

    initialTitle = reminder?.title ?? '';
    initialDescription = reminder?.description ?? '';
    initialDateTime = reminder?.scheduledTime;
    initialRepeatType = reminder?.repeatType ?? 'once';

    titleController.text = initialTitle;
    descriptionController.text = initialDescription;
    selectedDateTime = initialDateTime;
    repeatType = initialRepeatType;

    titleController.addListener(_onFormChanged);
    descriptionController.addListener(_onFormChanged);
  }

  // Picking Date and Time
  void pickDateTime() async {
    final now = DateTime.now();

    final DateTime initial = selectedDateTime ?? now;
    final DateTime first = DateTime(2000);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime:
          !isEditing
              ? TimeOfDay(
                hour: now.add(const Duration(minutes: 1)).hour,
                minute: now.add(const Duration(minutes: 1)).minute,
              )
              : TimeOfDay(hour: initial.hour, minute: initial.minute),
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

  // Handling form changes (validation)
  void _onFormChanged() {
    final changed =
        titleController.text != initialTitle ||
        descriptionController.text != initialDescription ||
        selectedDateTime != initialDateTime ||
        repeatType != initialRepeatType;

    setState(() => hasChanges = changed);
  }

  // SnackBar function
  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Handle Quick Add dialog
  void showQuickAddDialog(
    BuildContext context,
    void Function(Reminder reminder) onCreated,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: QuickAddReminderWidget(
              onReminderCreated: (reminder) {
                Navigator.of(context).pop();
                onCreated(reminder);
              },
              repository: Provider.of<ReminderRepository>(
                context,
                listen: false,
              ), // Access via Provider
            ),
          ),
        );
      },
    );
  }

  // Save the reminder
  Future<void> saveReminder() async {
    if (selectedDateTime == null) {
      _showSnack("Schedule Time cannot be null");
      return;
    }

    if (!isEditing && !selectedDateTime!.isAfter(DateTime.now())) {
      _showSnack("Please select a future date and time.");
      return;
    }

    if (isEditing &&
        selectedDateTime != initialDateTime &&
        !selectedDateTime!.isAfter(DateTime.now())) {
      _showSnack("Please select a future date and time.");
      return;
    }

    final reminderId =
        isEditing
            ? widget.reminder!.reminder_id
            : Provider.of<ReminderRepository>(
              context,
              listen: false,
            ).getNewReminderId();

    final reminder = Reminder(
      reminder_id: reminderId,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      scheduledTime: selectedDateTime!,
      repeatType: repeatType,
      notification_id: Reminder.generateStableId(reminderId),
    );

    try {
      await Provider.of<ReminderRepository>(
        context,
        listen: false,
      ).saveReminder(reminder); // Save via Provider
      await NotificationService().scheduleNotification(reminder);

      _showSnack("✅ Reminder saved!");
      _resetToEmpty();
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_titleFocusNode);
      Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ Failed to save reminder: $e");
      _showSnack("❌ Failed to save reminder.");
    }
  }

  // Reset the form
  void _resetToEmpty() {
    setState(() {
      hasChanges = false;
      titleController.clear();
      descriptionController.clear();
      selectedDateTime = null;
      repeatType = 'once';
    });
  }

  void _resetToInitialValues() {
    setState(() {
      hasChanges = false;
      if (isEditing) {
        titleController.text = initialTitle;
        descriptionController.text = initialDescription;
        selectedDateTime = initialDateTime;
        repeatType = initialRepeatType;
      } else {
        _resetToEmpty();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // final repository = Provider.of<ReminderRepository>(context, listen: false);
    return GradientScaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Edit Reminder" : "Add Reminder"),
        centerTitle: true,
        actions: [
          if (!isEditing)
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'import':
                    await runWithLoadingDialog(
                      context: context,
                      message: "Importing reminders...",
                      task: () => importFromCsv(context),
                    );
                    break;
                  case 'quick_add':
                    showQuickAddDialog(context, (reminder) {
                      Navigator.pushNamed(
                        context,
                        '/reminder-detail',
                        arguments: reminder.reminder_id,
                      );
                    });
                    break;
                }
              },
              itemBuilder:
                  (_) => const [
                    PopupMenuItem(
                      value: 'import',
                      child: Text('Import from CSV'),
                    ),
                    PopupMenuItem(
                      value: 'quick_add',
                      child: Text('Quick Add Reminder'),
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
              validator:
                  (value) =>
                      (value == null || value.isEmpty)
                          ? 'Please enter a title'
                          : null,
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
            if (selectedDateTime != null) ...[
              const Text(
                "Repeat Every",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              AppDropdown(
                label: "Type",
                value: repeatType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      repeatType = value;
                      _onFormChanged();
                    });
                  }
                },
                items: const ['once', 'daily', 'weekly', 'monthly', 'yearly'],
              ),
              const SizedBox(height: 24),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppSubmitButton(
                  onPressed: hasChanges ? saveReminder : null,
                  label: isEditing ? "Update Reminder" : "Add Reminder",
                ),
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
