import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    String savedEmail = prefs.getString('recipient_email') ?? '';
    bool savedEmailEnabled = prefs.getBool('email_enabled') ?? false;

    setState(() {
      _emailController.text = savedEmail;
      _isEmailEnabled = savedEmailEnabled;
      _initialEmail = savedEmail;
      _initialEmailEnabled = savedEmailEnabled;
      _isSaveEnabled = false;
      _isLoading = false;
    });

    _emailController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    setState(() {
      _isSaveEnabled =
          _emailController.text != _initialEmail ||
          _isEmailEnabled != _initialEmailEnabled;
    });
  }

  Future<void> _saveSettings() async {
    final scaffoldMessenger = ScaffoldMessenger.of(
      context,
    ); // ✅ Capture before async

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recipient_email', _emailController.text);
    await prefs.setBool('email_enabled', _isEmailEnabled);

    if (!context.mounted) {
      return; // ✅ Ensures widget is still active before calling setState
    }
    setState(() {
      _initialEmail = _emailController.text;
      _initialEmailEnabled = _isEmailEnabled;
      _isSaveEnabled = false;
    });

    // ✅ Use captured scaffoldMessenger instead of context
    scaffoldMessenger.showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
    );
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
            ElevatedButton(
              onPressed: _isSaveEnabled ? _saveSettings : null,
              child: Text("Save Settings"),
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
