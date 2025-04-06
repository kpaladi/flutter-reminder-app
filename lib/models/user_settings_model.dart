// lib/models/user_settings.dart
class UserSettings {
  final String email;
  final bool emailEnabled;

  UserSettings({
    required this.email,
    required this.emailEnabled,
  });

  factory UserSettings.fromPreferences(Map<String, dynamic> prefsMap) {
    return UserSettings(
      email: prefsMap['recipient_email'] ?? '',
      emailEnabled: prefsMap['email_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toPreferencesMap() {
    return {
      'recipient_email': email,
      'email_enabled': emailEnabled,
    };
  }
}
