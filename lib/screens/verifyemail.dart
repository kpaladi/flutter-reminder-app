import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    // Check every 3 seconds if email is verified
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

      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      setState(() {
        canResendEmail = false;
        isSending = false;
      });

      await Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);
    } catch (e) {
      setState(() => isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: $e')),
      );
    }
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    final user = FirebaseAuth.instance.currentUser!;
    if (user.emailVerified) {
      timer?.cancel();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
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
              onPressed: canResendEmail ? sendVerificationEmail : null,
              child: isSending ? const CircularProgressIndicator() : const Text('Resend Email'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
