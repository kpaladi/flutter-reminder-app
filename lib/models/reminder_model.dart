import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String reminderId; // Firebase document ID
  final String title;
  final String description;
  late final DateTime? scheduledTime; // First occurrence of the reminder
  final String? repeatType; // e.g., 'once', 'daily', 'weekly', 'monthly', 'yearly'
  final int notificationId; // Integer ID for local notifications

  Reminder({
    required this.reminderId,
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.repeatType,
    required this.notificationId,
  });

  /// Generate a stable integer ID from reminder_id (used for notifications)
  static int generateStableId(String reminderId) => reminderId.hashCode.abs();

  /// Factory method to create Reminder from Firestore document/map
  factory Reminder.fromMap(Map<String, dynamic> data, [String? id]) {
    return Reminder(
      reminderId: id ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      scheduledTime: data['scheduledTime'] is Timestamp
          ? (data['scheduledTime'] as Timestamp).toDate()
          : null,
      repeatType: data['repeatType'],
      notificationId: data['notification_id'] ??
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
      'notification_id': notificationId,
    };
  }

  /// Create a copy with overrides (immutability)
  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    String? repeatType,
    int? notificationId,
  }) {
    return Reminder(
      reminderId: id ?? reminderId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeatType: repeatType ?? this.repeatType,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  factory Reminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Reminder(
      reminderId: doc.id,
      title: data['title'],
      description: data['description'],
      scheduledTime: data['scheduledTime'] is Timestamp
          ? (data['scheduledTime'] as Timestamp).toDate()
          : null,
      repeatType: data['repeatType'],
      notificationId: data['notification_id'],
    );
  }

}
