import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? timer;
  bool canResendEmail = false;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    sendVerificationEmail();
    timer = Timer.periodic(const Duration(seconds: 3), (_) => checkEmailVerified());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> sendVerificationEmail() async {
    try {
      setState(() => isSending = true);

      User? user = FirebaseAuth.instance.currentUser;

      // Retry logic if user not ready
      int retries = 0;
      while (user == null && retries < 5) {
        await Future.delayed(const Duration(seconds: 1));
        user = FirebaseAuth.instance.currentUser;
        retries++;
      }

      if (user == null) {
        setState(() => isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not available. Please try again later.')),
        );
        return;
      }

      await user.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );

      setState(() {
        canResendEmail = false;
        isSending = false;
      });

      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return;
      setState(() => canResendEmail = true);
    } catch (e) {
      setState(() => isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: $e')),
      );
    }
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      timer?.cancel();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');  // Automatically navigate to login
    }
  }

  Future<void> goToLogin() async {
    timer?.cancel();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Same as View Reminders screen
      appBar: AppBar(
        title: Text(
          'Verify Email',
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              'A verification link has been sent to your email.\nPlease check your inbox (and spam folder).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (canResendEmail && !isSending) ? sendVerificationEmail : null,
              child: isSending
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Resend Email'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: goToLogin,
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
