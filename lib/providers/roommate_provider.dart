import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class RoommateProvider extends ChangeNotifier {
  Box? _roommatesBox;
  Box? _roommateDetailsBox;
  Box? _userBox;

  List<Map<String, dynamic>> _roommatesList = [];

  Future<void> initializeBoxes() async {
    _roommatesBox = await Hive.openBox('roommatesBox');
    _roommateDetailsBox = await Hive.openBox('roommateDetailsBox');
    _userBox = await Hive.openBox('usersBox');
  }

  Future<void> _ensureBoxesInitialized() async {
    if (_roommatesBox == null) {
      _roommatesBox = await Hive.openBox('roommatesBox');
    }
    if (_roommateDetailsBox == null) {
      _roommateDetailsBox = await Hive.openBox('roommateDetailsBox');
    }
    if (_userBox == null) {
      _userBox = await Hive.openBox('usersBox');
    }
  }

  Future<List<String>> get roommatesAsync async {
    await _ensureBoxesInitialized();
    if (_roommatesBox == null) return [];
    final List<String> list = _roommatesBox!.values.cast<String>().toList();
    return list.isEmpty ? [] : list;
  }

  List<Map<String, dynamic>> get roommates {
    if (_roommatesBox == null) return [];

    final entries = _roommatesBox!.toMap().entries;
    if (entries.isEmpty) return [];

    return entries
        .where((entry) => entry.key != 'select_roommate')
        .map((entry) => {'id': entry.key, 'name': entry.value})
        .toList();
  }

  List<Map<String, String>> get roommatesDropdownItems {
    if (_roommatesBox == null)
      return [
        {'id': 'select_roommate', 'name': 'Select Roommate'},
      ];

    final items =
        roommates
            .map(
              (roommate) => {
                'id': roommate['id'] as String,
                'name': roommate['name'] as String,
              },
            )
            .toList();

    items.insert(0, {'id': 'select_roommate', 'name': 'Select Roommate'});
    return items;
  }

  String getRoommateName(String id) {
    return _roommatesBox?.get(id, defaultValue: 'Unknown') ?? 'Unknown';
  }

  String getRoommateId(String name) {
    return name.toLowerCase().replaceAll(' ', '_');
  }

  String getDefaultRoommateId() {
    return 'select_roommate';
  }

  String? getDefaultRoommate() {
    final list = roommates;
    if (list.isEmpty) return null;
    if (list.length == 1 && list[0] == 'Select Roommate') return null;
    return list[0]['name'] as String?;
  }

  Future<void> addRoommate(String name, {String? id}) async {
    try {
      await _ensureBoxesInitialized();
      if (name.isNotEmpty && name != 'Select Roommate') {
        final String roommateId = id ?? 'user${_roommatesBox!.length + 1}';
        if (!_roommatesBox!.containsKey(roommateId)) {
          await _roommatesBox?.put(roommateId, name);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error adding roommate: $e');
    }
  }

  Future<void> removeRoommate(String index) async {
    try {
      await _ensureBoxesInitialized();
      await _roommatesBox?.delete(index);
      notifyListeners();
    } catch (e) {
      print('Error removing roommate: $e');
    }
  }

  Future<void> updateRoommate(dynamic id, String newName) async {
    try {
      await _ensureBoxesInitialized();
      if (newName.isNotEmpty) {
        await _roommatesBox?.put(id, newName);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating roommate: $e');
      throw Exception('Failed to update roommate: $e');
    }
  }

  Map<String, dynamic> getRoommateDetails(String name) {
    if (_roommateDetailsBox == null) return {};
    return _roommateDetailsBox!.get(
      name,
      defaultValue: {
        'name': name,
        'email': '',
        'phone': '',
        'paymentHistory': [],
        'expenses': [],
        'billsPaid': 0.0,
      },
    );
  }

  void updateRoommateDetails(String name, Map<String, dynamic> details) {
    if (_roommateDetailsBox == null) return;
    _roommateDetailsBox!.put(name, details);
    notifyListeners();
  }

  void addExpenseToRoommate(String name, Map<String, dynamic> expense) {
    final details = getRoommateDetails(name);
    List expenses = List.from(details['expenses'] ?? []);
    expenses.add(expense);
    details['expenses'] = expenses;
    updateRoommateDetails(name, details);
  }

  void recordBillPayment(String name, double amount) {
    final details = getRoommateDetails(name);
    details['billsPaid'] = (details['billsPaid'] ?? 0.0) + amount;
    updateRoommateDetails(name, details);
  }

  double getTotalExpenses(String name) {
    final details = getRoommateDetails(name);
    final expenses = details['expenses'] as List? ?? [];
    return expenses.fold(
      0.0,
      (sum, expense) => sum + (expense['amount'] ?? 0.0),
    );
  }

  double getBillsPaid(String name) {
    final details = getRoommateDetails(name);
    return details['billsPaid'] ?? 0.0;
  }

  void clearPaymentHistory(String name) {
    final details = getRoommateDetails(name);
    details['paymentHistory'] = [];
    updateRoommateDetails(name, details);
  }

  double calculateOwing(String name) {
    final totalExpenses = getTotalExpenses(name);
    final billsPaid = getBillsPaid(name);
    return totalExpenses - billsPaid;
  }

  Future<void> saveUserNames(String user1, String user2) async {
    await _ensureBoxesInitialized();
    final user1Id = getRoommateId(user1);
    final user2Id = getRoommateId(user2);

    await _userBox!.put('users', [
      {'name': user1, 'id': user1Id},
      {'name': user2, 'id': user2Id},
    ]);

    await _roommatesBox!.clear();
    final Map<String, String> entries = {
      'select_roommate': 'Select Roommate',
      user1Id: user1,
      user2Id: user2,
    };
    await _roommatesBox!.putAll(entries);
    notifyListeners();
  }

  Future<List<String>> getUserNames() async {
    if (_userBox == null) {
      _userBox = await Hive.openBox('usersBox');
    }

    final users =
        _userBox!.get(
              'users',
              defaultValue: [
                {'name': 'User 1', 'id': 'user1'},
                {'name': 'User 2', 'id': 'user2'},
              ],
            )
            as List;
    return users.map((user) => user['name'] as String).toList();
  }

  Map<String, String> getRoommateNames() {
    if (_roommatesBox == null) return {'user1': 'Unknown', 'user2': 'Unknown'};

    final users =
        roommates.where((r) => r['id'] != 'select_roommate').take(2).toList();
    if (users.isEmpty) return {'user1': 'Unknown', 'user2': 'Unknown'};

    return {
      'user1': users[0]['name'] as String,
      'user2': users.length > 1 ? users[1]['name'] as String : 'Unknown',
    };
  }
}
