import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reminder_app/screens/settings_screen.dart';
import 'package:reminder_app/screens/view_reminders_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/reminder_repository.dart';
import '../widgets/gradient_scaffold.dart';
import 'add_edit_reminder_screen.dart';

class HomeScreen extends StatefulWidget {
  final ReminderRepository reminderRepository;

  @override
//  HomeScreenState createState() => HomeScreenState();
  const HomeScreen({super.key, required this.reminderRepository});

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
        // your permission check if needed
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

  Future<void> cancelAllScheduledReminders() async {
    final reminders = await widget.reminderRepository.getAllReminders();

    for (final reminder in reminders) {
      await NotificationService().cancelNotification(reminder.notificationId);
    }
  }

  @override
  Widget build(BuildContext context) {

    return GradientScaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Reminder",
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', height: 40),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _checkEmailSet();  // Now it's available
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton(
              icon: Icons.add_alert,
              label: "Add Reminder",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditReminderScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildButton(
              icon: Icons.list_alt,
              label: "View Reminders",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ViewRemindersScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Logout'),
                content: const Text('Are you sure you want to log out?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Logout'),
                  ),
                ],
              );
            },
          );

          if (confirmed == true) {
            try {
              // clear all the notifications for the current user
              await cancelAllScheduledReminders();

              await FirebaseAuth.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error logging out: $e')),
              );
            }
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text("Logout"),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
      ),
      onPressed: onPressed,
    );
  }
}
