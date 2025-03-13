import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class ShoppingProvider with ChangeNotifier {
  final _shoppingBox = Hive.box('shoppingBox');

  List<Map<String, dynamic>> get items {
    final itemsData = _shoppingBox.values.toList();
    return List<Map<String, dynamic>>.from(itemsData);
  }

  List<Map<String, dynamic>> getItemsByCategory(String category) {
    return items.where((item) => item['category'] == category).toList();
  }

  List<Map<String, dynamic>> get pendingItems {
    return items.where((item) => !(item['purchased'] ?? false)).toList();
  }

  void toggleItemStatus(int index) {
    final item = _shoppingBox.getAt(index);
    if (item != null) {
      final updatedItem = Map<String, dynamic>.from(item);
      updatedItem['purchased'] = !(item['purchased'] ?? false);
      _shoppingBox.putAt(index, updatedItem);
      notifyListeners();
    }
  }

  void addItem(Map<String, dynamic> item) {
    if (!_validateItem(item)) throw Exception('Invalid item data');
    _shoppingBox.add(item);
    notifyListeners();
  }

  bool _validateItem(Map<String, dynamic> item) {
    return item.containsKey('name') && item.containsKey('category');
  }

  void updateItem(int index, Map<String, dynamic> item) {
    _shoppingBox.putAt(index, item);
    notifyListeners();
  }

  void deleteItem(int index) {
    _shoppingBox.deleteAt(index);
    notifyListeners();
  }
}
