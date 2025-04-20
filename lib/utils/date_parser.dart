import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

String cleanInput(String input) {
  String cleaned = input
      .replaceAllMapped(
    RegExp(r'(\d+)(st|nd|rd|th)', caseSensitive: false),
        (match) => match.group(1)!,
  )
      .replaceAll(RegExp(r'\bat\b|\bon\b', caseSensitive: false), '')
      .replaceAll(',', '')
      .toLowerCase()
      .trim();

  cleaned = cleaned
      .split(' ')
      .map((word) =>
  word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
      .join(' ');

  return cleaned;
}

String normalizeMonths(String input) {
  final monthMap = {
    'january': 'Jan',
    'february': 'Feb',
    'march': 'Mar',
    'april': 'Apr',
    'may': 'May',
    'june': 'Jun',
    'july': 'Jul',
    'august': 'Aug',
    'september': 'Sep',
    'october': 'Oct',
    'november': 'Nov',
    'december': 'Dec',
  };

  monthMap.forEach((full, short) {
    final regex = RegExp(r'\b' + RegExp.escape(full) + r'\b', caseSensitive: false);
    input = input.replaceAllMapped(regex, (match) => short);
  });

  return input;
}

DateTime _buildDateFromTime(String timeStr, DateTime baseDate) {
  final timeMatch = RegExp(r'(\d{1,2})(:(\d{2}))?\s?(am|pm)?').firstMatch(timeStr);
  if (timeMatch != null) {
    int hour = int.parse(timeMatch.group(1)!);
    int minute = timeMatch.group(3) != null ? int.parse(timeMatch.group(3)!) : 0;
    final isPM = (timeMatch.group(4)?.toLowerCase() == 'pm');
    final isAM = (timeMatch.group(4)?.toLowerCase() == 'am');

    if (isPM && hour < 12) hour += 12;
    if (isAM && hour == 12) hour = 0;

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }

  return DateTime(baseDate.year, baseDate.month, baseDate.day);
}

DateTime? parseDateTime(String input) {
  final now = DateTime.now();
  String cleaned = normalizeMonths(cleanInput(input));

  if (cleaned.contains('Tomorrow')) {
    cleaned = cleaned.replaceAll('Tomorrow', '');
    return _buildDateFromTime(cleaned, now.add(Duration(days: 1)));
  }

  final inMatch = RegExp(r'in (\d+)\s?(minute|hour|day|week)s?', caseSensitive: false)
      .firstMatch(cleaned);
  if (inMatch != null) {
    final amount = int.parse(inMatch.group(1)!);
    final unit = inMatch.group(2)!.toLowerCase();
    switch (unit) {
      case 'minute':
        return now.add(Duration(minutes: amount));
      case 'hour':
        return now.add(Duration(hours: amount));
      case 'day':
        return now.add(Duration(days: amount));
      case 'week':
        return now.add(Duration(days: amount * 7));
    }
  }

  final weekdays = {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  for (final day in weekdays.keys) {
    if (cleaned.toLowerCase().contains(day)) {
      final targetWeekday = weekdays[day]!;
      cleaned = cleaned.replaceFirst(RegExp(r'(next\s)?' + day, caseSensitive: false), '').trim();

      int daysUntil = (targetWeekday - now.weekday) % 7;
      if (cleaned.contains('next') || daysUntil == 0) daysUntil += 7;

      return _buildDateFromTime(cleaned, now.add(Duration(days: daysUntil)));
    }
  }

  final formats = [
    'd MMM yyyy HH:mm',
    'd MMM yyyy h:mm a',
    'd MMM yyyy h a',
    'd MMM HH:mm',
    'd MMM h:mm a',
    'd MMM h a',
    'MMM d yyyy HH:mm',
    'MMM d yyyy h:mm a',
    'MMM d HH:mm',
    'MMM d h:mm a',
    'MMM d h a',
    'd MMM',
    'MMM d',
  ];

  debugPrint("Trying to parse: $cleaned");
  for (final format in formats) {
    try {
      debugPrint("Trying format: $format");
      final parsed = DateFormat(format, 'en').parse(cleaned);
      debugPrint("Parsed with format: $format => $parsed");
    } catch (e) {
      debugPrint("Failed format: $format");
    }
  }

  final fallbackMatch = RegExp(r'^(\d{1,2}) (\w{3}) (\d{1,2}):(\d{2})$').firstMatch(cleaned);

  debugPrint("Cleaned string: [$cleaned]");
  debugPrint("Code units: ${cleaned.codeUnits}");


  if (fallbackMatch != null) {
    final day = int.parse(fallbackMatch.group(1)!);
    final monthStr = fallbackMatch.group(2)!;
    final hour = int.parse(fallbackMatch.group(3)!);
    final minute = int.parse(fallbackMatch.group(4)!);

    final monthIndex = DateFormat('MMM').parse(monthStr).month;
    final fallbackDate = DateTime(now.year, monthIndex, day, hour, minute);
    return fallbackDate.isBefore(now)
        ? fallbackDate.add(Duration(days: 1))
        : fallbackDate;
  }
  return null;
}
