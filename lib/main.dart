
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reminder_app/screens/add_reminder_screen.dart';
import 'package:reminder_app/screens/settings_screen.dart';
import 'package:reminder_app/screens/view_reminders_screen.dart';
import 'package:reminder_app/services/initialize_notifications.dart';
import 'package:reminder_app/services/notification_service.dart';
import 'package:reminder_app/services/special_permission_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel platform = MethodChannel('reminder_channel_darahaas');

  platform.setMethodCallHandler((MethodCall call) async {
    if (call.method == "rescheduleNotifications") {
      print("🛠️ Dart: Received 'rescheduleNotifications' method call");
      try {
        await Firebase.initializeApp();
        print("✅ Firebase initialized");

        await initializeNotifications();
        print("✅ Notifications initialized");

        await fetchAndScheduleReminders();
        print("✅ Reminders fetched and scheduled");

        return "done";
      } catch (e, stackTrace) {
        print("❌ Error during rescheduleNotifications: $e");
        print("📍 StackTrace: $stackTrace");
        return Future.error("Failed to reschedule: $e");
      }
    }
    return null;
  });


  // Only run full app if UI is available
  if (PlatformDispatcher.instance.implicitView != null) {
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp();
    await _requestPermissions();
    await initializeNotifications();
    // await fetchAndScheduleReminders(); // Dont need to refresh on every app start. Providing manual refresh option on UI.
    debugPrint("🚀 Flutter App Starting...");
    runApp(ReminderApp());
  } else {
    debugPrint("💤 Headless Dart execution only — UI not started.");
  }
}


Future<void> _requestPermissions() async {
  List<Permission> permissions = [
    Permission.notification,
    Permission.ignoreBatteryOptimizations,
    Permission.scheduleExactAlarm,
  ];

  for (var permission in permissions) {
    if (!await permission.isGranted) {
      await permission.request();
    }
  }
}

Future<void> clearAllScheduledReminders() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('scheduled_reminders');
  debugPrint("Cleared all scheduled reminders from SharedPreferences.");
}

Future<void> fetchAndScheduleReminders() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final snapshot = await db.collection("reminders").get();

  await clearAllScheduledReminders();

  for (var doc in snapshot.docs) {
    Map<String, dynamic> reminderData = doc.data();
    DateTime scheduledTime = (reminderData['timestamp'] as Timestamp).toDate();
    // Schedule notification
    await NotificationService().scheduleNotification(
      doc.id.hashCode,
      reminderData['title'],
      reminderData['description'],
      tz.TZDateTime.from(scheduledTime, tz.local),
    );
  }
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool isEmailSet = false;

  @override
  void initState() {
    super.initState();

    _checkEmailSet();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        checkAndRequestNotificationAccess(
            context); // ✅ Context is now safe to use
      }
    });
  }

  Future<void> _checkEmailSet() async {
    final prefs = await SharedPreferences.getInstance();
    String? recipientEmail = prefs.getString('recipient_email');
    setState(() {
      isEmailSet = (recipientEmail != null && recipientEmail.isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Reminder",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.greenAccent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo.png',
            height: 40,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.blue[800]),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
              _checkEmailSet();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') {
                _refreshReminders(context);
              }
            },
            itemBuilder: (context) =>
            [
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Refresh Reminders'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                icon: Icons.add_alert,
                label: "Add Reminder",
                color: Colors.greenAccent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddReminderScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              _buildButton(
                icon: Icons.list_alt,
                label: "View Reminders",
                color: Colors.greenAccent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewRemindersScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: Colors.black54,
      ),
      onPressed: onPressed,
    );
  }
}

  void _refreshReminders(BuildContext context) async {
    try {
      await fetchAndScheduleReminders();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Reminders refreshed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to refresh: $e')),
      );
    }
  }
