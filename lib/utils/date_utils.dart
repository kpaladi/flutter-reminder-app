import 'package:intl/intl.dart';

String formatTime(DateTime? dateTime) {
  if (dateTime == null) return '';
  return DateFormat.jm().format(dateTime); // e.g., 5:30 PM
}

String formatDate(DateTime? dateTime) {
  if (dateTime == null) return '';
  return DateFormat.yMMMd().format(dateTime); // e.g., Apr 9, 2025
}