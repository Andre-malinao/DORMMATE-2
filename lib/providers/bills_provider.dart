import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class BillsProvider with ChangeNotifier {
  final _billsBox = Hive.box('billsBox');

  List<Map<String, dynamic>> get bills {
    final billsData = _billsBox.values.toList();
    return List<Map<String, dynamic>>.from(billsData);
  }

  double get totalBills {
    return bills.fold(0.0, (sum, bill) => sum + (bill['amount'] ?? 0.0));
  }

  List<Map<String, dynamic>> getBillsByMonth(DateTime date) {
    return bills.where((bill) {
      final billDate = DateTime.parse(bill['dueDate']);
      return billDate.month == date.month && billDate.year == date.year;
    }).toList();
  }

  void addBill(Map<String, dynamic> bill) {
    if (!_validateBill(bill)) throw Exception('Invalid bill data');
    _billsBox.add(bill);
    notifyListeners();
  }

  void updateBill(int index, Map<String, dynamic> bill) {
    _billsBox.putAt(index, bill);
    notifyListeners();
  }

  void deleteBill(int index) {
    _billsBox.deleteAt(index);
    notifyListeners();
  }

  bool _validateBill(Map<String, dynamic> bill) {
    return bill.containsKey('amount') &&
        bill.containsKey('title') &&
        bill.containsKey('dueDate');
  }
}
