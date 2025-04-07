import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key}); // ✅ Add 'key' parameter

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
    final settings = UserSettings.fromPreferences({
      'recipient_email': prefs.getString('recipient_email'),
      'email_enabled': prefs.getBool('email_enabled'),
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
    final prefs = await SharedPreferences.getInstance();

    final updatedSettings = UserSettings(
      email: _emailController.text,
      emailEnabled: _isEmailEnabled,
    );

    final map = updatedSettings.toPreferencesMap();
    await prefs.setString('recipient_email', map['recipient_email'] as String);
    await prefs.setBool('email_enabled', map['email_enabled'] as bool);

    if (!context.mounted) return;

    setState(() {
      _initialEmail = updatedSettings.email;
      _initialEmailEnabled = updatedSettings.emailEnabled;
      _isSaveEnabled = false;
    });

    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  void _resetToInitialValues() {
    setState(() {
      _emailController.text = _initialEmail ?? '';
      _isEmailEnabled = _initialEmailEnabled ?? false;
      _isSaveEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings reset to last saved state.')),
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Settings")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Recipient Email",
                hintText: "Enter your email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Enable Email Notifications"),
                Switch(
                  value: _isEmailEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _isEmailEnabled = value;
                      _checkForChanges();
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaveEnabled ? _saveSettings : null,
                  icon: Icon(Icons.save),
                  label: Text("Save Settings"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: (_isSaveEnabled || _emailController.text != _initialEmail || _isEmailEnabled != _initialEmailEnabled)
                      ? _resetToInitialValues
                      : null,
                  icon: Icon(Icons.restore),
                  label: Text("Reset"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
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
