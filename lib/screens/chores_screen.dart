import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../providers/roommate_provider.dart';
import '../providers/chores_provider.dart';

class ChoresScreen extends StatefulWidget {
  @override
  _ChoresScreenState createState() => _ChoresScreenState();
}

class _ChoresScreenState extends State<ChoresScreen> {
  final TextEditingController _choreController = TextEditingController();
  late final Box _choresBox;
  String? _selectedUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initHive();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roommateItems =
          context.read<RoommateProvider>().roommatesDropdownItems;
      if (roommateItems.length > 1) {
        setState(() {
          _selectedUserId = roommateItems[1]['id']; // Skip 'Select Roommate'
        });
      }
    });
  }

  Future<void> _initHive() async {
    try {
      _choresBox = await Hive.openBox('choresBox');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing Hive: $e');
      // Handle the error appropriately
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    final provider = Provider.of<RoommateProvider>(context, listen: false);
    final userNames = await provider.getUserNames();
    if (userNames.isNotEmpty) {
      setState(() {
        _selectedUserId = userNames.first;
      });
    }
  }

  void _addChore() {
    if (_choreController.text.isEmpty || _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a chore and select a user')),
      );
      return;
    }

    // Set default due date to 7 days from now
    final dueDate = DateTime.now().add(Duration(days: 7));

    try {
      _choresBox.add({
        'userId': _selectedUserId,
        'chore': _choreController.text,
        'isDone': false,
        'timestamp': DateTime.now().toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
      });
      _choreController.clear();
      setState(() {});
    } catch (e) {
      print('Error adding chore: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add chore')));
    }
  }

  void _deleteChore(int index) {
    _choresBox.deleteAt(index);
    setState(() {});
  }

  void _toggleChore(int index) {
    try {
      final chore = _choresBox.getAt(index);
      if (chore != null) {
        chore['isDone'] = !(chore['isDone'] ?? false);
        _choresBox.putAt(index, chore);
        setState(() {});
      }
    } catch (e) {
      print('Error toggling chore: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update chore')));
    }
  }

  void _editChore(int index) {
    final chore = _choresBox.getAt(index);
    TextEditingController editController = TextEditingController(
      text: chore['chore'],
    );
    DateTime selectedDate = DateTime.parse(
      chore['dueDate'] ?? DateTime.now().toIso8601String(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Chore'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editController,
                  decoration: InputDecoration(
                    labelText: 'Chore',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Due Date'),
                  subtitle: Text(selectedDate.toString().split(' ')[0]),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  chore['chore'] = editController.text;
                  chore['dueDate'] = selectedDate.toIso8601String();
                  _choresBox.putAt(index, chore);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showAddUserDialog() {
    final TextEditingController userController = TextEditingController();
    final roommateNames = context.read<RoommateProvider>().getRoommateNames();

    // Count actual roommates (excluding 'Unknown')
    int actualRoommates =
        roommateNames.values.where((name) => name != 'Unknown').length;

    if (actualRoommates >= 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maximum of 2 roommates allowed')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add New Roommate'),
            content: TextField(
              controller: userController,
              decoration: InputDecoration(
                labelText: 'Roommate Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted:
                  (_) => _submitNewRoommate(userController.text, context),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    () => _submitNewRoommate(userController.text, context),
                child: Text('Add'),
              ),
            ],
          ),
    );
  }

  void _submitNewRoommate(String name, BuildContext context) {
    if (name.trim().isEmpty) return;

    final provider = context.read<RoommateProvider>();
    final roommateNames = provider.getRoommateNames();

    String userId = roommateNames['user1'] == 'Unknown' ? 'user1' : 'user2';
    provider.updateRoommate(userId, name.trim());

    Navigator.pop(context);
    setState(() {
      _selectedUserId = userId;
    });
  }

  void _deleteRoommate(String userId, String userName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Roommate'),
            content: Text('Are you sure you want to delete $userName?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  try {
                    // Delete all chores for this user
                    final choresProvider = context.read<ChoresProvider>();
                    await choresProvider.deleteChoresForUser(userId);

                    // Reset the roommate name to 'Unknown'
                    await context.read<RoommateProvider>().updateRoommate(
                      userId,
                      'Unknown',
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete roommate'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildUserChoresList() {
    final roommateNames = context.read<RoommateProvider>().getRoommateNames();

    return Column(
      children:
          roommateNames.entries.map((entry) {
            final userId = entry.key;
            final userName = entry.value;

            // Skip showing 'Unknown' users
            if (userName == 'Unknown') return SizedBox.shrink();

            final userChores =
                List.generate(_choresBox.length, (index) {
                  final chore = _choresBox.getAt(index);
                  if (chore['userId'] == userId) {
                    final dueDate = DateTime.parse(
                      chore['dueDate'] ?? DateTime.now().toIso8601String(),
                    );
                    final isOverdue =
                        dueDate.isBefore(DateTime.now()) &&
                        !(chore['isDone'] ?? false);

                    return ListTile(
                      leading: Checkbox(
                        value: chore['isDone'] ?? false,
                        onChanged: (_) => _toggleChore(index),
                      ),
                      title: Text(
                        chore['chore'],
                        style: TextStyle(
                          decoration:
                              chore['isDone'] == true
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                          color: isOverdue ? Colors.red : null,
                        ),
                      ),
                      subtitle: Text(
                        'Due: ${dueDate.toString().split(' ')[0]}',
                        style: TextStyle(color: isOverdue ? Colors.red : null),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editChore(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteChore(index),
                          ),
                        ],
                      ),
                    );
                  }
                  return null;
                }).whereType<ListTile>().toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.person_remove, color: Colors.red),
                        onPressed: () => _deleteRoommate(userId, userName),
                      ),
                    ],
                  ),
                ),
                if (userChores.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No chores for $userName'),
                  )
                else
                  ...userChores,
                Divider(thickness: 2),
              ],
            );
          }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roommateNames = context.watch<RoommateProvider>().getRoommateNames();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chores List',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person_add, color: Colors.white),
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFF2193b0)),
                        color: Colors.white,
                      ),
                      child: DropdownButton<String>(
                        value: _selectedUserId,
                        hint: Text('Select User'),
                        isExpanded: true,
                        underline: SizedBox(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedUserId = newValue;
                            });
                          }
                        },
                        items:
                            roommateNames.entries.map<DropdownMenuItem<String>>(
                              (entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(entry.value),
                                );
                              },
                            ).toList(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _choreController,
                      decoration: InputDecoration(
                        labelText: 'Enter a chore',
                        labelStyle: TextStyle(color: Color(0xFF2193b0)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFF2193b0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Color(0xFF6dd5ed),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addChore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2193b0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Add Chore',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: _buildUserChoresList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _choreController.dispose();
    _choresBox.close();
    super.dispose();
  }
}
