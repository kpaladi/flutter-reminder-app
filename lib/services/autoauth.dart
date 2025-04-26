import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/services/reminder_repository.dart';
import '../screens/home_screen.dart';
import '../screens/loginscreen.dart';
import '../screens/verifyemail.dart';

// autoauth.dart (or wherever your AuthGate is)

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error during auth')),
          );
        }

        if (user == null) {
          return const LoginScreen();
        }

        if (!user.emailVerified) {
          return const VerifyEmailScreen();
        }

        // ✅ Provide ReminderRepository
        final reminderRepository = ReminderRepository(userId: user.uid);

        return HomeScreen(reminderRepository: reminderRepository); // pass it properly
      },
    );
  }
}


