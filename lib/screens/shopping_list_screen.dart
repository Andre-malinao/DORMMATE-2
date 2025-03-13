import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/roommate_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _shoppingBox = Hive.box('shoppingBox');
  final _userBox = Hive.box('userBox');
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping List',
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
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
          ),
        ),
        child: ValueListenableBuilder(
          valueListenable: _shoppingBox.listenable(),
          builder: (context, box, _) {
            final items = box.values.toList();
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(
                      item['name'],
                      style: TextStyle(
                        decoration:
                            item['purchased']
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                    ),
                    subtitle: Text(
                      item['assignedTo'] != null
                          ? 'Assigned to: ${item['assignedTo']}'
                          : 'Not assigned',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!item['purchased'])
                          IconButton(
                            icon: Icon(Icons.person_add),
                            onPressed: () => _showAssignDialog(context, index),
                          ),
                        IconButton(
                          icon: Icon(
                            item['purchased']
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: item['purchased'] ? Colors.green : null,
                          ),
                          onPressed: () => _togglePurchased(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _shoppingBox.deleteAt(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF2193b0),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Item'),
            content: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: 'Enter item name'),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Add'),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    _shoppingBox.add({
                      'name': _controller.text,
                      'assignedTo': null,
                      'purchased': false,
                    });
                    _controller.clear();
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showAssignDialog(BuildContext context, int index) {
    final roommateProvider = Provider.of<RoommateProvider>(
      context,
      listen: false,
    );
    final roommateNames = roommateProvider.getRoommateNames();

    // Filter out 'Unknown' roommates
    final activeRoommates =
        roommateNames.entries
            .where((entry) => entry.value != 'Unknown')
            .toList();

    if (activeRoommates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No roommates added yet')));
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Assign Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    activeRoommates.map((entry) {
                      return ListTile(
                        title: Text('Assign to ${entry.value}'),
                        onTap: () {
                          final item = _shoppingBox.getAt(index);
                          _shoppingBox.putAt(index, {
                            ...item,
                            'assignedTo': entry.value,
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
              ),
            ),
          ),
    );
  }

  void _togglePurchased(int index) {
    final item = _shoppingBox.getAt(index);
    _shoppingBox.putAt(index, {
      ...item,
      'purchased': !(item['purchased'] ?? false),
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
