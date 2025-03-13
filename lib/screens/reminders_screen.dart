import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

class Reminder {
  String title;
  String? description;
  DateTime dateTime;
  bool isCompleted;
  String? billType; // New property
  String? source; // Add source to track where the reminder came from
  String? userId; // Add userId to track which user the reminder belongs to

  Reminder({
    required this.title,
    this.description,
    required this.dateTime,
    this.isCompleted = false,
    this.billType,
    this.source,
    this.userId,
  });
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  _RemindersScreenState createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<Reminder> _reminders = [];
  final List<String> _billTypes = [
    'Electricity',
    'Water',
    'Internet',
    'Rent',
    'Other',
  ];
  late Box _billsBox;
  late Box _choresBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    try {
      _billsBox = await Hive.openBox('billsBox');
      _choresBox = await Hive.openBox('choresBox');
      await _loadAllReminders();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing Hive: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAllReminders() async {
    _reminders.clear();

    // Load bills as reminders
    for (var i = 0; i < _billsBox.length; i++) {
      var bill = _billsBox.getAt(i);
      if (bill != null && !bill['isPaid']) {
        _reminders.add(
          Reminder(
            title: '${bill['amount']?.toString() ?? '0.0'}',
            description: bill['description'] ?? '',
            dateTime: DateTime.parse(
              bill['dueDate'] ?? DateTime.now().toIso8601String(),
            ),
            billType: bill['category'] ?? 'Other',
            source: 'bill',
            userId:
                bill['user1Id'], // You might want to handle this differently
          ),
        );
      }
    }

    // Load chores as reminders
    for (var i = 0; i < _choresBox.length; i++) {
      var chore = _choresBox.getAt(i);
      if (chore != null && !(chore['isDone'] ?? false)) {
        _reminders.add(
          Reminder(
            title: chore['chore'] ?? '',
            description: 'Assigned to: ${chore['userId'] ?? 'Unknown'}',
            dateTime: DateTime.parse(
              chore['timestamp'] ?? DateTime.now().toIso8601String(),
            ),
            billType: 'Other',
            source: 'chore',
            userId: chore['userId'],
          ),
        );
      }
    }

    // Sort reminders by date
    _reminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  void _refreshReminders() {
    _loadAllReminders().then((_) => setState(() {}));
  }

  Future<void> _showAddEditReminderDialog([Reminder? reminder]) async {
    final isEditing = reminder != null;
    final titleController = TextEditingController(text: reminder?.title);
    final descController = TextEditingController(text: reminder?.description);
    String? selectedBillType = reminder?.billType;
    DateTime selectedDate = reminder?.dateTime ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      reminder?.dateTime ?? DateTime.now(),
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isEditing ? 'Edit Bill Reminder' : 'New Bill Reminder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedBillType,
                    decoration: const InputDecoration(labelText: 'Bill Type'),
                    items:
                        _billTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (value) => selectedBillType = value,
                  ),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Amount/Details',
                    ),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes',
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        selectedDate = date;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                  ListTile(
                    title: Text('Time: ${selectedTime.format(context)}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        selectedTime = time;
                        (context as Element).markNeedsBuild();
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      selectedBillType != null) {
                    final datetime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    setState(() {
                      if (isEditing) {
                        reminder.title = titleController.text;
                        reminder.description = descController.text;
                        reminder.dateTime = datetime;
                        reminder.billType = selectedBillType;
                      } else {
                        _reminders.add(
                          Reminder(
                            title: titleController.text,
                            description: descController.text,
                            dateTime: datetime,
                            billType: selectedBillType,
                          ),
                        );
                        _reminders.sort(
                          (a, b) => a.dateTime.compareTo(b.dateTime),
                        );
                      }
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text(isEditing ? 'Save' : 'Add'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Reminders')),
      body:
          _reminders.isEmpty
              ? const Center(child: Text('No scheduled reminders'))
              : ListView.builder(
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  return ListTile(
                    leading: Checkbox(
                      value: reminder.isCompleted,
                      onChanged: (value) async {
                        if (reminder.source == 'bill') {
                          // Handle bill completion
                          for (var i = 0; i < _billsBox.length; i++) {
                            var bill = _billsBox.getAt(i);
                            if (bill['description'] == reminder.description) {
                              bill['isPaid'] = value;
                              await _billsBox.putAt(i, bill);
                              break;
                            }
                          }
                        } else if (reminder.source == 'chore') {
                          // Handle chore completion
                          for (var i = 0; i < _choresBox.length; i++) {
                            var chore = _choresBox.getAt(i);
                            if (chore['chore'] == reminder.title) {
                              chore['isDone'] = value;
                              await _choresBox.putAt(i, chore);
                              break;
                            }
                          }
                        }
                        _refreshReminders();
                      },
                    ),
                    title: Row(
                      children: [
                        Icon(
                          reminder.billType == 'Electricity'
                              ? Icons.electric_bolt
                              : reminder.billType == 'Water'
                              ? Icons.water_drop
                              : reminder.billType == 'Internet'
                              ? Icons.wifi
                              : reminder.billType == 'Rent'
                              ? Icons.house
                              : Icons.receipt_long,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${reminder.billType}: ${reminder.title}',
                          style: TextStyle(
                            decoration:
                                reminder.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reminder.description?.isNotEmpty ?? false)
                          Text(reminder.description!),
                        Text(
                          DateFormat(
                            'MMM dd, yyyy - hh:mm a',
                          ).format(reminder.dateTime),
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAddEditReminderDialog(reminder),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() => _reminders.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditReminderDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _billsBox.close();
    _choresBox.close();
    super.dispose();
  }
}
