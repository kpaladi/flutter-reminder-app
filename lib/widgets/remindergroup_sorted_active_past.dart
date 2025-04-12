import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import 'reminder_group_section.dart';

class ReminderGroupWithSortedActiveAndPast extends StatelessWidget {
  final String groupTitle;
  final List<Reminder> reminders;
  final void Function(Reminder reminder) onEdit;
  final void Function(Reminder reminder) onDelete;

  const ReminderGroupWithSortedActiveAndPast({
    super.key,
    required this.groupTitle,
    required this.reminders,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    bool isInPast(Reminder r, DateTime now) {
      final t = r.scheduledTime;
      if (t == null) return false;

      switch (r.repeatType?.toLowerCase()) {
        case 'once':
          return t.isBefore(now);

        case 'daily':
          final today = DateTime(now.year, now.month, now.day, t.hour, t.minute);
          return now.isAfter(today);

        case 'weekly':
          final daysDiff = (now.weekday - t.weekday + 7) % 7;
          final thisWeek = now.subtract(Duration(days: daysDiff));
          final occurrence = DateTime(thisWeek.year, thisWeek.month, thisWeek.day, t.hour, t.minute);
          return now.isAfter(occurrence);

        case 'monthly':
          DateTime occurrence;
          try {
            occurrence = DateTime(now.year, now.month, t.day, t.hour, t.minute);
          } catch (_) {
            // Handle months with fewer days than t.day (e.g., Feb 30)
            final lastDay = DateTime(now.year, now.month + 1, 0).day;
            occurrence = DateTime(now.year, now.month, lastDay, t.hour, t.minute);
          }
          return now.isAfter(occurrence);

        case 'yearly':
          DateTime occurrence;
          try {
            occurrence = DateTime(now.year, t.month, t.day, t.hour, t.minute);
          } catch (_) {
            // Handle leap years or invalid dates
            final lastDay = DateTime(now.year, t.month + 1, 0).day;
            occurrence = DateTime(now.year, t.month, lastDay, t.hour, t.minute);
          }
          return now.isAfter(occurrence);

        default:
          return false;
      }
    }


    final List<Reminder> active = [];
    final List<Reminder> past = [];

    for (var r in reminders) {
      (isInPast(r, now) ? past : active).add(r);
    }

    active.sort((a, b) => _compareByNextSchedule(a, b, now));
    past.sort((a, b) => _compareByLastMissed(a, b, now));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (active.isNotEmpty)
          ReminderGroupSection(
            groupTitle: '$groupTitle * Active',
            reminders: active,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        if (past.isNotEmpty)
          ReminderGroupSection(
            groupTitle: '$groupTitle • Past',
            reminders: past,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
      ],
    );
  }

  int _compareByNextSchedule(Reminder a, Reminder b, DateTime now) {
    final aMin = _minutesUntilReminder(a.scheduledTime!, a.repeatType, now);
    final bMin = _minutesUntilReminder(b.scheduledTime!, b.repeatType, now);
    return aMin.compareTo(bMin);
  }

  int _compareByLastMissed(Reminder a, Reminder b, DateTime now) {
    final aMin = _minutesSinceReminder(a.scheduledTime!, a.repeatType, now);
    final bMin = _minutesSinceReminder(b.scheduledTime!, b.repeatType, now);
    return aMin.compareTo(bMin);
  }

  int _minutesUntilReminder(DateTime time, String? repeatType, DateTime now) {
    switch (repeatType?.toLowerCase()) {
      case 'daily':
        final t = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        return t.difference(now).inMinutes;
      case 'weekly':
        DateTime next = now.add(Duration(days: (time.weekday - now.weekday + 7) % 7));
        next = DateTime(next.year, next.month, next.day, time.hour, time.minute);
        return next.difference(now).inMinutes;
      case 'monthly':
        DateTime next = DateTime(now.year, now.month, time.day, time.hour, time.minute);
        if (next.isBefore(now)) next = DateTime(now.year, now.month + 1, time.day, time.hour, time.minute);
        return next.difference(now).inMinutes;
      case 'yearly':
        DateTime next = DateTime(now.year, time.month, time.day, time.hour, time.minute);
        if (next.isBefore(now)) next = DateTime(now.year + 1, time.month, time.day, time.hour, time.minute);
        return next.difference(now).inMinutes;
      default:
        return time.difference(now).inMinutes;
    }
  }

  int _minutesSinceReminder(DateTime time, String? repeatType, DateTime now) {
    switch (repeatType?.toLowerCase()) {
      case 'daily':
        final t = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        return now.difference(t).inMinutes;
      case 'weekly':
        DateTime last = now.subtract(Duration(days: (now.weekday - time.weekday + 7) % 7));
        last = DateTime(last.year, last.month, last.day, time.hour, time.minute);
        return now.difference(last).inMinutes;
      case 'monthly':
        DateTime last = DateTime(now.year, now.month, time.day, time.hour, time.minute);
        if (last.isAfter(now)) last = DateTime(now.year, now.month - 1, time.day, time.hour, time.minute);
        return now.difference(last).inMinutes;
      case 'yearly':
        DateTime last = DateTime(now.year, time.month, time.day, time.hour, time.minute);
        if (last.isAfter(now)) last = DateTime(now.year - 1, time.month, time.day, time.hour, time.minute);
        return now.difference(last).inMinutes;
      default:
        return now.difference(time).inMinutes;
    }
  }
}