import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? error;

  Future<void> register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      // Send user to verify email screen after registration
      Navigator.pushReplacementNamed(context, '/verify-email');
    } catch (e) {
      setState(() {
        error = 'Registration failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "New User Registration",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            const SizedBox(height: 16),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            if (error != null) Text(error!, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: register, child: Text('Register')),
            const SizedBox(height: 16),
            TextButton(
              child: Text('Already have an account? Login'),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
