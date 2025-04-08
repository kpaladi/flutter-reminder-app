import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/reminder_model.dart';

Future<void> sendReminder({
  required BuildContext context,
  required Reminder reminder,
  String? phoneNumber,
}) async {
  final message = '${reminder.description}';

  final Map<String, String> queryParams = {
    'text': message, // No manual encoding needed here
    if (phoneNumber != null) 'phone': phoneNumber,
  };

  final Uri url = Uri.https('api.whatsapp.com', '/send', queryParams);

  debugPrint('[WhatsAppService] Trying URL: $url');

  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('[WhatsAppService] Could not launch: $e');
  }
}
