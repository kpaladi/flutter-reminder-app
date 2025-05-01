import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

const MethodChannel _platform = MethodChannel('notification_access_channel');

class PermissionsHelper {
  /// Request Notification & Alarm permissions immediately
  static Future<void> requestEssentialPermissions() async {
    try {
      debugPrint("🔄 Requesting Notification and Alarm permissions...");

      // Request Notification Permission
      final notifStatus = await Permission.notification.request();
      debugPrint("🔔 Notification permission: $notifStatus");

      // Request Exact Alarm Permission
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      debugPrint("⏰ Exact alarm permission: $alarmStatus");

    } catch (e) {
      debugPrint("❌ Error requesting permissions: $e");
    }
  }

  /// Request special Notification Listener access with dialog
  static Future<void> requestSpecialNotificationAccess(BuildContext context) async {
    try {
      debugPrint("🔄 Checking if Notification Listener access is granted...");

      final bool isGranted = await _platform.invokeMethod('isNotificationAccessEnabled');

      if (isGranted) {
        debugPrint("✅ Notification Listener access already granted.");
        return;
      }

      debugPrint("🔄 Notification Listener access not granted. Showing dialog...");

      // Prompt user via dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Special Permission Needed"),
          content: const Text(
              "This app needs Notification Listener Access to monitor notifications and show smart reminders."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Later"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _platform.invokeMethod('openNotificationAccessSettings');
              },
              child: const Text("Grant Access"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("❌ Error checking notification listener access: $e");
    }
  }

  /// Convenience method to do both, with delay for UX
  static Future<void> handleAllPermissions(BuildContext context) async {
    debugPrint("🔄 Handling all permissions...");

    // 🔔 Request notification permission
    final notifStatus = await Permission.notification.request();
    debugPrint("🔔 Notification permission: $notifStatus");

    // Small buffer delay (let Android dismiss dialog smoothly)
    await Future.delayed(const Duration(milliseconds: 500));

    // ⏰ Request exact alarm permission
    final alarmStatus = await Permission.scheduleExactAlarm.request();
    debugPrint("⏰ Exact alarm permission: $alarmStatus");

    // Another short delay
    await Future.delayed(const Duration(milliseconds: 500));

    // 🔓 Finally, request special notification listener access
    if (context.mounted) {
      debugPrint("🔄 Requesting special notification access...");
      requestSpecialNotificationAccess(context);
    }
  }
}
