import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final bool isFormField;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.validator,
    this.isFormField = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final decoration = InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.colorScheme.primary),
      border: const OutlineInputBorder(),
    );

    return isFormField
        ? TextFormField(
      controller: controller,
      validator: validator,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.sentences,
      decoration: decoration,
    )
        : TextField(
      controller: controller,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.sentences,
      decoration: decoration,
      cursorColor: theme.colorScheme.primary,
    );
  }
}

class AppDropdown extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String?) onChanged;
  final List<String> items;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.colorScheme.primary),
        border: const OutlineInputBorder(),
      ),
      dropdownColor: theme.cardColor,
    );
  }
}

class AppSubmitButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const AppSubmitButton({
    super.key,
    required this.onPressed,
    this.label = "Submit Reminder",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.check),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? theme.colorScheme.primary : theme.disabledColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

Widget buildDateTimePickerButton({
  required BuildContext context,
  required VoidCallback onPressed,
  required DateTime? selectedDateTime,
}) {
  final theme = Theme.of(context);
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(
      selectedDateTime == null
          ? "Schedule Time"
          : "Selected: ${DateFormat('d MMM yyyy HH:mm').format(selectedDateTime.toLocal())}",
    ),
  );
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
