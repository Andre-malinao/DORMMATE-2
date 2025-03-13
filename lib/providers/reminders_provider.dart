import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class RemindersProvider with ChangeNotifier {
  final _remindersBox = Hive.box('remindersBox');

  List<Map<String, dynamic>> get reminders {
    final remindersData = _remindersBox.values.toList();
    return List<Map<String, dynamic>>.from(remindersData);
  }

  List<Map<String, dynamic>> get sortedReminders {
    final sorted = List<Map<String, dynamic>>.from(reminders);
    sorted.sort((a, b) {
      final aPriority = a['priority'] ?? 0;
      final bPriority = b['priority'] ?? 0;
      return bPriority.compareTo(aPriority);
    });
    return sorted;
  }

  List<Map<String, dynamic>> getDueReminders() {
    final now = DateTime.now();
    return reminders.where((reminder) {
      final dueDate = DateTime.parse(reminder['dueDate']);
      return dueDate.isAfter(now);
    }).toList();
  }

  void addReminder(Map<String, dynamic> reminder) {
    if (!_validateReminder(reminder)) throw Exception('Invalid reminder data');
    _remindersBox.add(reminder);
    notifyListeners();
  }

  bool _validateReminder(Map<String, dynamic> reminder) {
    return reminder.containsKey('title') && reminder.containsKey('dueDate');
  }

  void updateReminder(int index, Map<String, dynamic> reminder) {
    _remindersBox.putAt(index, reminder);
    notifyListeners();
  }

  void deleteReminder(int index) {
    _remindersBox.deleteAt(index);
    notifyListeners();
  }
}
