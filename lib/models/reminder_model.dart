import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime? timestamp;
  final String? repeatType; // e.g., "daily", "weekly", "monthly"
  final int? repeatInterval; // e.g., 1 for daily, 7 for weekly, etc.
  final DateTime? repeatEnd; // Optional end date for repeating reminders

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    this.timestamp,
    this.repeatType,
    this.repeatInterval,
    this.repeatEnd,
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
      repeatInterval: data['repeatInterval'],
      repeatEnd: data['repeatEnd'] is Timestamp
          ? (data['repeatEnd'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
      'repeatType': repeatType,
      'repeatInterval': repeatInterval,
      'repeatEnd': repeatEnd != null ? Timestamp.fromDate(repeatEnd!) : null,
    };
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    String? repeatType,
    int? repeatInterval,
    DateTime? repeatEnd,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      repeatType: repeatType ?? this.repeatType,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      repeatEnd: repeatEnd ?? this.repeatEnd,
    );
  }

}
