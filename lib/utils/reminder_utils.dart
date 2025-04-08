// utils/reminder_utils.dart
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';

/// Checks if the reminder is in the past (used for greying out past reminders)
bool isReminderInPast(Reminder reminder) {
  final now = DateTime.now();
  final time = reminder.timestamp;

  if (time == null) return false;

  switch (reminder.repeatType?.toLowerCase()) {
    case null:
    case '':
    case 'only once':
      return time.isBefore(now);

    case 'day':
      return time.hour < now.hour ||
          (time.hour == now.hour && time.minute < now.minute);

    case 'week':
      if (time.weekday < now.weekday) return true;
      if (time.weekday > now.weekday) return false;

      return time.hour < now.hour ||
          (time.hour == now.hour && time.minute < now.minute);

    case 'month':
      if (time.day < now.day) return true;
      if (time.day > now.day) return false;

      return time.hour < now.hour ||
          (time.hour == now.hour && time.minute < now.minute);

    case 'year':
      if (time.month < now.month) return true;
      if (time.month > now.month) return false;

      if (time.day < now.day) return true;
      if (time.day > now.day) return false;

      return time.hour < now.hour ||
          (time.hour == now.hour && time.minute < now.minute);

    default:
      return false;
  }
}

/// Builds a readable repeat summary
String buildRepeatSummary(Reminder reminder) {
  final timestamp = reminder.timestamp;
  final type = reminder.repeatType?.toLowerCase();

  if (timestamp == null) return 'Unknown time';

  final timeString = DateFormat.jm().format(timestamp);

  switch (type) {
    case 'day':
      return 'Every day at $timeString';
    case 'week':
      final weekday = DateFormat.EEEE().format(timestamp);
      return 'Every $weekday at $timeString';
    case 'month':
      return 'Every month on day ${timestamp.day} at $timeString';
    case 'year':
      final dateString = DateFormat('MMM d').format(timestamp);
      return 'Every year on $dateString at $timeString';
    case 'only once':
    default:
      return 'Once at ${DateFormat.yMMMd().add_jm().format(timestamp)}';
  }
}
