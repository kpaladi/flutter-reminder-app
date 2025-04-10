import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../utils/reminder_utils.dart';
import '../utils/reminder_utils.dart' as ReminderUtils;

class NotificationRefresher {
  final List<Reminder> reminders;

  NotificationRefresher(this.reminders);

  Future<void> refresh() async {

    for (final reminder in reminders) {
      if (reminder.repeatType == null || reminder.repeatType == 'once') continue;

      final next = getNextOccurrence(reminder);
      if (next == null) continue;

      await NotificationService().scheduleNotification(
        reminder.copyWith(scheduledTime: next),
      );
    }
  }
}

// Usage (for example, in a popup menu action):
// final refresher = NotificationRefresher(reminders);
// await refresher.refresh();
