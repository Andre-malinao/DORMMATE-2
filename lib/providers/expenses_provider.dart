import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class ExpensesProvider with ChangeNotifier {
  final _expensesBox = Hive.box('expensesBox');

  List<Map<String, dynamic>> get expenses {
    final expensesData = _expensesBox.values.toList();
    return List<Map<String, dynamic>>.from(expensesData);
  }

  double get totalExpenses {
    return expenses.fold(
      0.0,
      (sum, expense) => sum + (expense['amount'] ?? 0.0),
    );
  }

  Map<String, double> get expensesByCategory {
    final categoryTotals = <String, double>{};
    for (var expense in expenses) {
      final category = expense['category'] ?? 'Other';
      final amount = expense['amount'] ?? 0.0;
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }
    return categoryTotals;
  }

  List<Map<String, dynamic>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return expenses.where((expense) {
      final date = DateTime.parse(expense['date']);
      return date.isAfter(start) && date.isBefore(end);
    }).toList();
  }

  void addExpense(Map<String, dynamic> expense) {
    if (!_validateExpense(expense)) throw Exception('Invalid expense data');
    _expensesBox.add(expense);
    notifyListeners();
  }

  void updateExpense(int index, Map<String, dynamic> expense) {
    _expensesBox.putAt(index, expense);
    notifyListeners();
  }

  void deleteExpense(int index) {
    _expensesBox.deleteAt(index);
    notifyListeners();
  }

  bool _validateExpense(Map<String, dynamic> expense) {
    return expense.containsKey('amount') &&
        expense.containsKey('category') &&
        expense.containsKey('date');
  }
}
