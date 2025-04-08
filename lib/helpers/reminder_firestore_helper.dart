// helpers/reminder_firestore_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';



Reminder mapDocToReminder(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;

  return Reminder(
    id: doc.id,
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    repeatType: data['repeatType'],
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

    if (type == null || type.isEmpty || type == 'only once') {
      grouped['One-Time']!.add(reminder);
    } else if (type == 'day') {
      grouped['Daily']!.add(reminder);
    } else if (type == 'week') {
      grouped['Weekly']!.add(reminder);
    } else if (type == 'month') {
      grouped['Monthly']!.add(reminder);
    } else if (type == 'year') {
      grouped['Yearly']!.add(reminder);
    } else {
      grouped['Others']!.add(reminder);
    }
  }

  grouped.forEach((key, list) {
    list.sort((a, b) {
      final aTime = a.timestamp ?? DateTime(2100);
      final bTime = b.timestamp ?? DateTime(2100);

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
