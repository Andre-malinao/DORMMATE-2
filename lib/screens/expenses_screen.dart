import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final List<Expense> _expenses = [];
  late Box _billsBox;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _billsBox = await Hive.openBox('billsBox');
    setState(() {});
  }

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
    });
  }

  double _calculateTotal() {
    double expensesTotal = _expenses.fold(
      0,
      (sum, expense) => sum + expense.amount,
    );
    double billsTotal = 0;

    // Calculate total from bills
    for (var i = 0; i < _billsBox.length; i++) {
      var bill = _billsBox.getAt(i);
      billsTotal += bill['amount'] ?? 0.0;
    }

    return expensesTotal + billsTotal;
  }

  List<Widget> _buildExpensesList() {
    List<Widget> allItems = [];

    // Add bills
    for (var i = 0; i < _billsBox.length; i++) {
      var bill = _billsBox.getAt(i);
      if (bill != null) {
        var billDate = DateTime.parse(bill['date']);
        if (billDate.month == DateTime.now().month) {
          allItems.add(
            ExpenseItem(
              expense: Expense(
                title: bill['description'] ?? 'No description',
                amount: bill['amount'] ?? 0.0,
                category: ExpenseCategory.bills,
                date: billDate,
              ),
              isBill: true,
            ),
          );
        }
      }
    }

    // Add regular expenses
    allItems.addAll(
      _expenses
          .map((expense) => ExpenseItem(expense: expense, isBill: false))
          .toList(),
    );

    // Sort by date
    allItems.sort((a, b) {
      final aDate = (a as ExpenseItem).expense.date;
      final bDate = (b as ExpenseItem).expense.date;
      return bDate.compareTo(aDate);
    });

    return allItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expenses Tracker',
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
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total: ₱${_calculateTotal().toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Color(0xFF2193b0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Month: ${DateFormat('MMMM yyyy').format(DateTime.now())}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Color(0xFF6dd5ed),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: ListView(children: _buildExpensesList())),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
        backgroundColor: Color(0xFF2193b0),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddExpenseForm(onSubmit: _addExpense),
    );
  }
}

class Expense {
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;

  Expense({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });
}

enum ExpenseCategory { bills, groceries, transport, entertainment, other }

class ExpenseItem extends StatelessWidget {
  final Expense expense;
  final bool isBill;

  const ExpenseItem({required this.expense, this.isBill = false, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          isBill ? Icons.receipt_long : Icons.shopping_bag,
          color: isBill ? Colors.blue : Colors.green,
        ),
        title: Text(expense.title),
        subtitle: Text(
          '${isBill ? "Bill" : expense.category.toString().split('.').last} • ${DateFormat('MMM dd').format(expense.date)}',
        ),
        trailing: Text(
          '₱${expense.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isBill ? Colors.blue : Colors.green,
          ),
        ),
      ),
    );
  }
}

class AddExpenseForm extends StatefulWidget {
  final Function(Expense) onSubmit;

  const AddExpenseForm({required this.onSubmit, Key? key}) : super(key: key);

  @override
  State<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends State<AddExpenseForm> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  ExpenseCategory _selectedCategory = ExpenseCategory.other;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(labelText: 'Amount'),
            keyboardType: TextInputType.number,
          ),
          DropdownButton<ExpenseCategory>(
            value: _selectedCategory,
            items:
                ExpenseCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.toString().split('.').last),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
          ElevatedButton(
            onPressed: _submitExpense,
            child: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  void _submitExpense() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? 0;

    if (title.isEmpty || amount <= 0) {
      return;
    }

    widget.onSubmit(
      Expense(
        title: title,
        amount: amount,
        category: _selectedCategory,
        date: DateTime.now(),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
