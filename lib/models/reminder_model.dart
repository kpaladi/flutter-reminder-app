import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime? timestamp;
  final String? repeatType; // e.g., "daily", "weekly", "monthly"

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    this.timestamp,
    this.repeatType,
  });

  /// Use this for local notification ID (int)
  int get notificationId => id.hashCode.abs();

  factory Reminder.fromMap(Map<String, dynamic> data, [String? id]) {
    return Reminder(
      id: id ?? '', // fallback if ID is null
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : null,
      repeatType: data['repeatType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'repeatType': repeatType,
    };
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    String? repeatType,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      repeatType: repeatType ?? this.repeatType,
    );
  }

}
