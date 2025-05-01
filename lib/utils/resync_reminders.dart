// in notification_service.dart or a new utils/reminder_utils.dart
import 'package:reminder_app/utils/reminder_utils.dart';

import '../services/notification_service.dart';
import '../services/reminder_repository.dart';

class ReminderHelper {
  static Future<int> resyncReminders(ReminderRepository repository) async {
    final reminders = await repository.getAllReminders();
    int resyncedCount = 0;

    for (var reminder in reminders) {
      if (reminder.repeatType != null) {
        final nextTime = getNextOccurrence(reminder);
        if (nextTime != null) {
          final updatedReminder = reminder.copyWith(scheduledTime: nextTime);
          await NotificationService().scheduleNotification(updatedReminder);
          resyncedCount++;
        }
      }
    }

    return resyncedCount;
  }
}
