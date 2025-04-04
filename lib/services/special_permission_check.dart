import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

const platform = MethodChannel('notification_access_channel');

Future<void> checkAndRequestNotificationAccess(BuildContext context) async {
  try {
    final bool isGranted =
    await platform.invokeMethod('isNotificationAccessEnabled');

    if (isGranted) {
      debugPrint("✅ Notification listener access is already granted.");
      return;
    }

    // If not granted, prompt user
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "This app needs Notification Listener Access to function properly."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await platform.invokeMethod('openNotificationAccessSettings');
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
