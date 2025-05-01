// utils/reminder_utils.dart
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';

/// Checks if the reminder is in the past (used for greying out past reminders)
bool isReminderInPast(Reminder reminder) {
  final now = DateTime.now();
  final time = reminder.scheduledTime;

  if (time == null) return false;

  switch (reminder.repeatType?.toLowerCase()) {
    case null:
    case '':
    case 'once':
      return time.isBefore(now);

    case 'daily':
      return time.hour < now.hour ||
          (time.hour == now.hour && time.minute < now.minute);

    case 'weekly':
      if (time.weekday < now.weekday) return true;
      if (time.weekday > now.weekday) return false;

      return time.hour < now.hour ||
          (time.hour == now.hour && time.minute < now.minute);

    case 'monthly':
      if (time.day < now.day) return true;
      if (time.day > now.day) return false;

      return time.hour < now.hour ||
          (time.hour == now.hour && time.minute < now.minute);

    case 'yearly':
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
  final timestamp = reminder.scheduledTime;
  final type = reminder.repeatType?.toLowerCase();

  if (timestamp == null) return 'Unknown time';

  final timeString = DateFormat.jm().format(timestamp);

  switch (type) {
    case 'daily':
      return 'Every day at $timeString';
    case 'weekly':
      final weekday = DateFormat.EEEE().format(timestamp);
      return 'Every $weekday at $timeString';
    case 'monthly':
      return 'Every month on day ${timestamp.day} at $timeString';
    case 'yearly':
      final dateString = DateFormat('MMM d').format(timestamp);
      return 'Every year on $dateString at $timeString';
    case 'once':
    default:
      return 'Once at ${DateFormat.yMMMd().add_jm().format(timestamp)}';
  }
}

DateTime? getNextOccurrence(Reminder reminder) {
  final now = DateTime.now();
  final time = reminder.scheduledTime;
  if (time == null) return null;

  switch (reminder.repeatType?.toLowerCase()) {
    case 'daily':
      final next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return next.isAfter(now) ? next : next.add(const Duration(days: 1));

    case 'weekly':
      final daysToAdd = (time.weekday - now.weekday + 7) % 7;
      var next = DateTime(now.year, now.month, now.day, time.hour, time.minute).add(Duration(days: daysToAdd));
      return next.isAfter(now) ? next : next.add(const Duration(days: 7));

    case 'monthly':
      var next = DateTime(now.year, now.month, time.day, time.hour, time.minute);
      if (next.isBefore(now)) {
        next = DateTime(now.year, now.month + 1, time.day, time.hour, time.minute);
      }
      return next;

    case 'yearly':
      var next = DateTime(now.year, time.month, time.day, time.hour, time.minute);
      if (next.isBefore(now)) {
        next = DateTime(now.year + 1, time.month, time.day, time.hour, time.minute);
      }
      return next;

    case 'once':
      var next = time;
      if(next.isAfter(now)){
        return next;
      }
      else {
        return null;
      }

    default:
      return null;
  }
}

