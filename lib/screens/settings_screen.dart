import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings_model.dart';
import '../widgets/app_reset_button.dart';
import '../widgets/gradient_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailEnabled = false;
  bool _isSaveEnabled = false;
  bool _isLoading = true;

  String? _initialEmail;
  bool? _initialEmailEnabled;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      // fallback or error if no user is logged in
      return;
    }

    final settings = UserSettings.fromPreferences({
      'recipient_email': prefs.getString('${uid}_recipient_email'),
      'email_enabled': prefs.getBool('${uid}_email_enabled'),
    });

    setState(() {
      _emailController.text = settings.email;
      _isEmailEnabled = settings.emailEnabled;
      _initialEmail = settings.email;
      _initialEmailEnabled = settings.emailEnabled;
      _isSaveEnabled = false;
      _isLoading = false;
    });

    _emailController.addListener(_checkForChanges);
  }

  Future<void> _saveSettings() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();

    final updatedSettings = UserSettings(
      email: _emailController.text,
      emailEnabled: _isEmailEnabled,
    );

    final map = updatedSettings.toPreferencesMap();
    await prefs.setString('${uid}_recipient_email', map['recipient_email'] as String);
    await prefs.setBool('${uid}_email_enabled', map['email_enabled'] as bool);

    if (!context.mounted) return;

    setState(() {
      _initialEmail = updatedSettings.email;
      _initialEmailEnabled = updatedSettings.emailEnabled;
      _isSaveEnabled = false;
    });

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('✅ Settings saved successfully!')),
    );
  }

  void _resetToInitialValues() {
    setState(() {
      _emailController.text = _initialEmail ?? '';
      _isEmailEnabled = _initialEmailEnabled ?? false;
      _isSaveEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('↩️ Settings reset to last saved state.')),
    );
  }

  void _checkForChanges() {
    setState(() {
      _isSaveEnabled =
          _emailController.text != _initialEmail ||
              _isEmailEnabled != _initialEmailEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return GradientScaffold(
        appBar: AppBar(title: const Text("Settings")),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GradientScaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Recipient Email",
                hintText: "Enter your email",
                border: const OutlineInputBorder(),
                labelStyle: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              cursorColor: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Enable Email Notifications",
                  style: textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Switch(
                  value: _isEmailEnabled,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (bool value) {
                    setState(() {
                      _isEmailEnabled = value;
                      _checkForChanges();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaveEnabled ? _saveSettings : null,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Settings"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaveEnabled
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                AppResetButton(
                  onPressed: _resetToInitialValues,
                  isEnabled: _isSaveEnabled ||
                      _emailController.text != _initialEmail ||
                      _isEmailEnabled != _initialEmailEnabled,
                  showIcon: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.removeListener(_checkForChanges);
    _emailController.dispose();
    super.dispose();
  }
}
