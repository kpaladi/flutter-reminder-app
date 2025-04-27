import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:reminder_app/models/reminder_model.dart';
import 'package:reminder_app/screens/add_edit_reminder_screen.dart';
import 'package:reminder_app/screens/home_screen.dart';
import 'package:reminder_app/screens/loginregistration.dart';
import 'package:reminder_app/screens/loginscreen.dart';
import 'package:reminder_app/screens/verifyemail.dart';
import 'package:reminder_app/screens/view_reminder.dart';
import 'package:reminder_app/services/autoauth.dart';
import 'package:reminder_app/services/initialize_notifications.dart';
import 'package:reminder_app/services/notification_service.dart';
import 'package:reminder_app/services/reminder_repository.dart';
import 'package:reminder_app/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:reminder_app/widgets/error_app.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const MethodChannel platform = MethodChannel('reminder_channel_darahaas');

  // Handle platform-specific communication (e.g., rescheduling notifications from native side)
  platform.setMethodCallHandler((MethodCall call) async {
    if (call.method == "rescheduleNotifications") {
      debugPrint("🛠️ Dart: Received 'rescheduleNotifications' method call");
      try {
        await Firebase.initializeApp();
        debugPrint("✅ Firebase initialized");

        // Initialize notifications and fetch reminders
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

  // Ensure the app is initialized only if running on the UI thread
  if (PlatformDispatcher.instance.implicitView != null) {
    await dotenv.load(fileName: ".env");

    try {
      await Firebase.initializeApp();
    } catch (e, stackTrace) {
      debugPrint("🔥 Firebase init failed : $e");
      debugPrint("📍 StackTrace: $stackTrace");
      runApp(ErrorApp(errorMessage: "Firebase initialization failed: $e"));
      return;
    }

    await _requestPermissions();
    await initializeNotifications();
    debugPrint("🚀 Flutter App Starting...");
    runApp(AppBootstrapper());
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

class AppBootstrapper extends StatelessWidget {
  const AppBootstrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Something went wrong')),
            ),
          );
        }

        final user = snapshot.data;
        final repository = user != null ? ReminderRepository(userId: user.uid) : null;

        return ChangeNotifierProvider<ReminderRepository?>.value(
          value: repository,
          child: ReminderApp(isLoggedIn: user != null),
        );
      },
    );
  }
}

class ReminderApp extends StatelessWidget {
  final bool isLoggedIn;

  const ReminderApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: isLoggedIn ? const AuthGate() : const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/add-edit':
            if (settings.arguments is Reminder) {
              final reminder = settings.arguments as Reminder;
              return MaterialPageRoute(
                builder: (context) => AddEditReminderScreen(reminder: reminder),
              );
            }
            throw Exception('Invalid arguments for /add-edit');

          case '/reminder-detail':
            final reminderId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => ReminderDetailScreen(
                reminderId: reminderId
              ),
            );

          case '/home':
            final repository = settings.arguments as ReminderRepository;
            return MaterialPageRoute(
              builder: (context) => HomeScreen(reminderRepository: repository),
            );

          case '/register': // ✅ Add this!
            return MaterialPageRoute(
              builder: (context) => const RegisterScreen(),
            );

          case '/verify-email': // ✅ Add this!
            return MaterialPageRoute(
              builder: (context) => const VerifyEmailScreen(),
            );

          case '/login':
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );

          default:
            return null;
        }
      },
    );
  }
}

