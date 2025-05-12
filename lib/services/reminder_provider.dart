import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import 'reminder_repository.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderRepository repository;

  List<Reminder> _reminders = [];
  bool _isLoaded = false;

  ReminderProvider({required this.repository});

  List<Reminder> get reminders => _reminders;

  Future<void> loadReminders() async {
    if (_isLoaded) return; // cache already loaded

    _reminders = await repository.getReminders();
    _isLoaded = true;
    notifyListeners();
  }

  void refresh() async {
    _reminders = await repository.getReminders();
    notifyListeners();
  }

  Future<void> addReminder(Reminder reminder) async {
    await repository.addReminder(reminder);
    _reminders.add(reminder);
    notifyListeners();
  }

  Future<void> updateReminder(Reminder reminder) async {
    await repository.updateReminder(reminder);
    int index = _reminders.indexWhere((r) => r.reminderId == reminder.reminderId);
    if (index != -1) {
      _reminders[index] = reminder;
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    await repository.deleteReminder(id);
    _reminders.removeWhere((r) => r.reminderId == id);
    notifyListeners();
  }
}
