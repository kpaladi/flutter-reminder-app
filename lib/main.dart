import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:reminder_app/models/reminder_model.dart';
import 'package:reminder_app/screens/add_edit_reminder_screen.dart';
import 'package:reminder_app/screens/loginregistration.dart';
import 'package:reminder_app/screens/loginscreen.dart';
import 'package:reminder_app/screens/settings_screen.dart';
import 'package:reminder_app/screens/verifyemail.dart';
import 'package:reminder_app/screens/view_reminder.dart';
import 'package:reminder_app/screens/view_reminders_screen.dart';
import 'package:reminder_app/services/initialize_notifications.dart';
import 'package:reminder_app/services/notification_service.dart';
import 'package:reminder_app/services/special_permission_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reminder_app/theme/app_theme.dart';
import 'package:reminder_app/widgets/gradient_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel platform = MethodChannel('reminder_channel_darahaas');

  platform.setMethodCallHandler((MethodCall call) async {
    if (call.method == "rescheduleNotifications") {
      debugPrint("🛠️ Dart: Received 'rescheduleNotifications' method call");
      try {
        await Firebase.initializeApp();
        debugPrint("✅ Firebase initialized");

        await initializeNotifications();
        debugPrint("✅ Notifications initialized");

        await fetchAndScheduleReminders();
        debugPrint("✅ Reminders fetched and scheduled");

        return "done";
      } catch (e, stackTrace) {
        debugPrint("❌ Error during rescheduleNotifications: $e");
        debugPrint("📍 StackTrace: $stackTrace");
        return Future.error("Failed to reschedule: $e");
      }
    }
    return null;
  });

  if (PlatformDispatcher.instance.implicitView != null) {
    await dotenv.load(fileName: ".env");

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint("🔥 Firebase init failed : $e");
    }

    // await Firebase.initializeApp();
    await _requestPermissions();
    await initializeNotifications();
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

Future<int> fetchAndScheduleReminders() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final snapshot = await db.collection("reminders").get();

  int scheduledCount = 0;

  for (var doc in snapshot.docs) {
    final reminder = Reminder.fromMap(doc.data());

    if (reminder.scheduledTime != null) {
      await NotificationService().scheduleNotification(reminder);
      scheduledCount++;
    }
  }

  return scheduledCount;
}

class ReminderApp extends StatelessWidget {
  const ReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: FirebaseAuth.instance.currentUser == null
          ? '/login'
          : FirebaseAuth.instance.currentUser!.emailVerified
          ? '/home'
          : '/verify-email',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const HomeScreen(), // your reminder list screen
        '/verify-email': (_) => const VerifyEmailScreen(),
      },
      // ✅ Add this route handler
      onGenerateRoute: (settings) {
        if (settings.name == '/add-edit') {
          final reminder = settings.arguments as Reminder;
          return MaterialPageRoute(
            builder: (_) => AddEditReminderScreen(reminder: reminder),
          );
        } else if (settings.name == '/reminder-detail') {
          final reminderId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => ReminderDetailScreen(reminderId: reminderId),
          );
        }
        return null;
      },
    );
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
        checkAndRequestNotificationAccess(context);
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
    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          "Reminder",
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', height: 40),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).iconTheme.color),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _checkEmailSet();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main gradient + content
          Container(
            decoration: const BoxDecoration(
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
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddEditReminderScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    icon: Icons.list_alt,
                    label: "View Reminders",
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ViewRemindersScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 🔓 Positioned Logout Button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: Icon(Icons.logout, color: Theme.of(context).appBarTheme.foregroundColor),
              label: Text(
                "Logout",
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                ),
              ),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            ),
          ),
        ],
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
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: Colors.black54,
      ),
      onPressed: onPressed,
    );
  }
}
