// helpers/reminder_firestore_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';



Reminder mapDocToReminder(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return Reminder(
    reminder_id: doc.id,
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    scheduledTime: (data['timestamp'] as Timestamp?)?.toDate(),
    repeatType: data['repeatType'],
    notification_id: data['notification_id'] ?? Reminder.generateStableId(doc.id),
  );
}

Map<String, List<Reminder>> groupAndSortReminders(List<Reminder> reminders) {
  final Map<String, List<Reminder>> grouped = {
    'One-Time': [],
    'Daily': [],
    'Weekly': [],
    'Monthly': [],
    'Yearly': [],
    'Others': [],
  };

  for (var reminder in reminders) {
    final type = reminder.repeatType?.toLowerCase();

    if (type == null || type.isEmpty || type == 'once') {
      grouped['One-Time']!.add(reminder);
    } else if (type == 'daily') {
      grouped['Daily']!.add(reminder);
    } else if (type == 'weekly') {
      grouped['Weekly']!.add(reminder);
    } else if (type == 'monthly') {
      grouped['Monthly']!.add(reminder);
    } else if (type == 'yearly') {
      grouped['Yearly']!.add(reminder);
    } else {
      grouped['Others']!.add(reminder);
    }
  }

  grouped.forEach((key, list) {
    list.sort((a, b) {
      final aTime = a.scheduledTime ?? DateTime(2100);
      final bTime = b.scheduledTime ?? DateTime(2100);

      switch (key) {
        case 'One-Time':
          return aTime.compareTo(bTime);

        case 'Daily':
          final aMinutes = aTime.hour * 60 + aTime.minute;
          final bMinutes = bTime.hour * 60 + bTime.minute;
          return aMinutes.compareTo(bMinutes);

        case 'Weekly':
        case 'Monthly':
          final aUnit = (key == 'Weekly') ? aTime.weekday : aTime.day;
          final bUnit = (key == 'Weekly') ? bTime.weekday : bTime.day;

          if (aUnit != bUnit) return aUnit.compareTo(bUnit);

          final aMin = aTime.hour * 60 + aTime.minute;
          final bMin = bTime.hour * 60 + bTime.minute;
          return aMin.compareTo(bMin);

        case 'Yearly':
          if (aTime.month != bTime.month) {
            return aTime.month.compareTo(bTime.month);
          }
          if (aTime.day != bTime.day) {
            return aTime.day.compareTo(bTime.day);
          }

          final aMin = aTime.hour * 60 + aTime.minute;
          final bMin = bTime.hour * 60 + bTime.minute;
          return aMin.compareTo(bMin);

        default:
          return aTime.compareTo(bTime);
      }
    });
  });

  return grouped;
}
