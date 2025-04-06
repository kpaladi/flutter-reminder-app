import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const MethodChannel _platform = MethodChannel('notification_access_channel');

Future<void> checkAndRequestNotificationAccess(BuildContext context) async {
  try {
    final bool isGranted = await _platform.invokeMethod('isNotificationAccessEnabled');

    if (isGranted) {
      debugPrint("✅ Notification listener access is already granted.");
      return;
    }

    if (!context.mounted) return;

    // Prompt user if not granted
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
          "This app needs Notification Listener Access to function properly.\n\n"
              "Please enable it in system settings.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _platform.invokeMethod('openNotificationAccessSettings');
              } catch (e) {
                debugPrint("⚠️ Failed to open settings: $e");
              }
            },
            child: const Text("Grant Access"),
          ),
        ],
      ),
    );
  } catch (e) {
    debugPrint("❌ Error checking notification access: $e");
  }
}
