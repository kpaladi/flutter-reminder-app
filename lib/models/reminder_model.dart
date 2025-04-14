import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String reminder_id; // Firebase document ID
  final String title;
  final String description;
  late final DateTime? scheduledTime; // First occurrence of the reminder
  final String? repeatType; // e.g., 'once', 'daily', 'weekly', 'monthly', 'yearly'
  final int notification_id; // Integer ID for local notifications

  Reminder({
    required this.reminder_id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.repeatType,
    required this.notification_id,
  });

  /// Generate a stable integer ID from reminder_id (used for notifications)
  static int generateStableId(String reminderId) => reminderId.hashCode.abs();

  /// Factory method to create Reminder from Firestore document/map
  factory Reminder.fromMap(Map<String, dynamic> data, [String? id]) {
    return Reminder(
      reminder_id: id ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      scheduledTime: data['scheduledTime'] is Timestamp
          ? (data['scheduledTime'] as Timestamp).toDate()
          : null,
      repeatType: data['repeatType'],
      notification_id: data['notification_id'] ??
          generateStableId(id ?? ''), // fallback if missing
    );
  }

  /// Convert Reminder to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime != null
          ? Timestamp.fromDate(scheduledTime!)
          : null,
      'repeatType': repeatType,
      'notification_id': notification_id,
    };
  }

  /// Create a copy with overrides (immutability)
  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    String? repeatType,
    int? notification_id,
  }) {
    return Reminder(
      reminder_id: id ?? this.reminder_id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatType: repeatType ?? this.repeatType,
      notification_id: notification_id ?? this.notification_id,
    );
  }

  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reminder(
      reminder_id: doc.id,
      title: data['title'],
      description: data['description'],
      scheduledTime: data['scheduledTime'] is Timestamp
          ? (data['scheduledTime'] as Timestamp).toDate()
          : null,
      repeatType: data['repeatType'],
      notification_id: data['notification_id'],
    );
  }

}
