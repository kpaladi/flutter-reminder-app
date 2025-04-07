import 'package:flutter/material.dart';

class AppResetButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;
  final bool showIcon;

  const AppResetButton({
    super.key,
    required this.onPressed,
    this.isEnabled = true,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = isEnabled ? theme.colorScheme.secondary : theme.disabledColor;

    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: showIcon ? const Icon(Icons.restore) : const SizedBox.shrink(),
      label: const Text("Reset"),
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
