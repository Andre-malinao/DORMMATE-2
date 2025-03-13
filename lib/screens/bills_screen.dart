import 'package:dormmate/providers/roommate_provider.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'chores_screen.dart';

class BillsScreen extends StatefulWidget {
  @override
  _BillsScreenState createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  DateTime _selectedDueDate = DateTime.now();
  final TextEditingController _dueDateController = TextEditingController();
  late Box _billsBox;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _user1PaymentController = TextEditingController();
  final TextEditingController _user2PaymentController = TextEditingController();
  late Box _usersBox;
  String _user1Name = '';
  String _user2Name = '';
  String _user1Id = '';
  String _user2Id = '';
  String _selectedPayerId = '';
  String _selectedCategory = 'Rent';
  final List<String> _categories = [
    'Rent',
    'Electricity',
    'Groceries',
    'Other',
  ];

  bool _showSummary = false;

  final _cardDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.white, Colors.blue.shade50],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 2,
        blurRadius: 5,
        offset: Offset(0, 3),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _initHive();
    // Add listener to RoommateProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RoommateProvider>(context, listen: false);
      provider.addListener(() {
        _loadUserNames();
      });
    });
  }

  Future<void> _initHive() async {
    try {
      _billsBox = await Hive.openBox('billsBox');
      _usersBox = await Hive.openBox('usersBox');
      _loadUserNames();
      setState(() {});
    } catch (e) {
      print('Error initializing Hive boxes: $e');
      // Show error dialog or snackbar to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load data. Please restart the app.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadUserNames() async {
    try {
      // First try to get data from RoommateProvider
      final provider = Provider.of<RoommateProvider>(context, listen: false);
      final roommates =
          provider.roommatesDropdownItems
              .where((item) => item['id'] != 'select_roommate')
              .toList();

      if (roommates.isNotEmpty) {
        setState(() {
          // First user
          _user1Id = roommates[0]['id'] ?? 'user1';
          _user1Name = roommates[0]['name'] ?? 'User 1';

          // Second user (if exists)
          if (roommates.length > 1) {
            _user2Id = roommates[1]['id'] ?? 'user2';
            _user2Name = roommates[1]['name'] ?? 'User 2';
          }

          _selectedPayerId = _user1Id; // Default to first user
        });
        print('Loaded from Provider - User1: $_user1Name, User2: $_user2Name');
        return;
      }

      // Fallback: Try to load from chores_management box
      final choresBox = await Hive.openBox('chores_management');
      final List<dynamic> roommatesFromBox = choresBox.get(
        'roommates',
        defaultValue: [],
      );

      if (roommatesFromBox.isNotEmpty) {
        setState(() {
          final firstRoommate = roommatesFromBox[0];
          _user1Id = firstRoommate['id'] ?? 'user1';
          _user1Name = firstRoommate['name'];

          if (roommatesFromBox.length > 1) {
            final secondRoommate = roommatesFromBox[1];
            _user2Id = secondRoommate['id'] ?? 'user2';
            _user2Name = secondRoommate['name'];
          }

          _selectedPayerId = _user1Id;
        });
        print('Loaded from Box - User1: $_user1Name, User2: $_user2Name');
      } else {
        print('No roommates found in either source');
        // Show a message to the user that they need to add roommates first
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please add roommates in the Chores screen first'),
              action: SnackBarAction(
                label: 'Add Roommates',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChoresScreen()),
                  );
                },
              ),
            ),
          );
        });
      }
    } catch (e) {
      print('Error loading roommates: $e');
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading roommates: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addBill() {
    if (_descriptionController.text.isNotEmpty &&
        _amountController.text.isNotEmpty) {
      double amount = double.parse(_amountController.text);
      _billsBox.add({
        'description': _descriptionController.text,
        'amount': amount,
        'paidById': _selectedPayerId,
        'category': _selectedCategory,
        'date': DateTime.now().toIso8601String(),
        'dueDate': _selectedDueDate.toIso8601String(),
        'splitAmount': amount / 2,
      });
      _descriptionController.clear();
      _amountController.clear();
      _dueDateController.clear();
      setState(() {
        _showSummary = false;
      });
    }
  }

  void _addBillWithSplitPayment(double user1Payment, double user2Payment) {
    if (_descriptionController.text.isNotEmpty &&
        _amountController.text.isNotEmpty) {
      double amount = double.parse(_amountController.text);
      _billsBox.add({
        'description': _descriptionController.text,
        'amount': amount,
        'paidBy': _selectedPayerId,
        'category': _selectedCategory,
        'date': DateTime.now().toIso8601String(),
        'dueDate': _selectedDueDate.toIso8601String(),
        'user1Payment': user1Payment,
        'user2Payment': user2Payment,
        'isPaid': false,
      });
      _descriptionController.clear();
      _amountController.clear();
      _dueDateController.clear();
      _user1PaymentController.clear();
      _user2PaymentController.clear();
      setState(() {});
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
        _dueDateController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  void _deleteBill(int index) {
    _billsBox.deleteAt(index);
    setState(() {});
  }

  void _markBillAsPaid(int index) {
    var bill = _billsBox.getAt(index);
    bill['isPaid'] = true;
    _billsBox.putAt(index, bill);
    setState(() {});
  }

  void _payNow(int index) {
    final bill = _billsBox.getAt(index);
    double totalAmount = bill['amount'];
    bool user1HasPaid = bill['user1Paid'] ?? false;
    bool user2HasPaid = bill['user2Paid'] ?? false;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Select who is paying'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Amount: \₱${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                if (user1HasPaid)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '$_user1Name has paid their share',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                if (!user1HasPaid)
                  ElevatedButton(
                    onPressed: () => _showPaymentDialog(index, _user1Id),
                    child: Text('Pay as $_user1Name'),
                  ),
                SizedBox(height: 10),
                if (user2HasPaid)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          '$_user2Name has paid their share',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                if (!user2HasPaid)
                  ElevatedButton(
                    onPressed: () => _showPaymentDialog(index, _user2Id),
                    child: Text('Pay as $_user2Name'),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showPaymentDialog(int index, String userId) {
    final bill = _billsBox.getAt(index);
    final provider = Provider.of<RoommateProvider>(context, listen: false);
    double totalAmount = bill['amount'];
    final userName = userId == _user1Id ? _user1Name : _user2Name;
    final controller = TextEditingController(
      text: (totalAmount / 2).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
            content: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.blue.shade50],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Payment Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, color: Colors.blue.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Paying as: $userName',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Roommates',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 20),
                            SizedBox(width: 8),
                            Text(_user1Name),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 20),
                            SizedBox(width: 8),
                            Text(_user2Name),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Amount (₱)',
                      prefixIcon: Icon(
                        Icons.attach_money,
                        color: Colors.blue.shade700,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.blue.shade700,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (controller.text.isNotEmpty) {
                            if (userId == _user1Id) {
                              bill['user1Payment'] = double.parse(
                                controller.text,
                              );
                              bill['user1Paid'] = true;
                            } else {
                              bill['user2Payment'] = double.parse(
                                controller.text,
                              );
                              bill['user2Paid'] = true;
                            }
                            bill['isPaid'] =
                                (bill['user1Paid'] ?? false) &&
                                (bill['user2Paid'] ?? false);
                            bill['paidById'] = userId;
                            _billsBox.putAt(index, bill);
                            setState(() {});
                            Navigator.pop(context);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('Pay Now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showSummaryAndPayButton() {
    if (_descriptionController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _dueDateController.text.isNotEmpty) {
      setState(() {
        _showSummary = true;
      });

      double amount = double.parse(_amountController.text);
      _billsBox.add({
        'description': _descriptionController.text,
        'amount': amount,
        'category': _selectedCategory,
        'date': DateTime.now().toIso8601String(),
        'dueDate': _selectedDueDate.toIso8601String(),
        'isPaid': false,
        'user1Paid': false,
        'user2Paid': false,
        'user1Payment': 0.0,
        'user2Payment': 0.0,
        'user1Id': _user1Id,
        'user2Id': _user2Id,
      });
    }
  }

  Widget _buildBillCard(dynamic bill, int index) {
    final provider = Provider.of<RoommateProvider>(context, listen: false);
    final payerName =
        bill['paidById'] != null
            ? provider.getRoommateName(bill['paidById'])
            : 'Not paid';

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: _cardDecoration,
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(bill['category'] ?? 'Other'),
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill['description'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Category: ${bill['category'] ?? 'Other'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(index),
                  ),
                ],
              ),
              Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(
                          DateTime.parse(
                            bill['dueDate'] ?? DateTime.now().toIso8601String(),
                          ),
                        ),
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '\₱${(bill['amount'] ?? 0.0).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (bill['isPaid'] == true) ...[
                Text(
                  'Paid by: $payerName',
                  style: TextStyle(color: Colors.green),
                ),
                Text(
                  '$_user1Name paid: \₱${bill['user1Payment']?.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green),
                ),
                Text(
                  '$_user2Name paid: \₱${bill['user2Payment']?.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.green),
                ),
              ] else
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: () => _payNow(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Pay Now'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Bill'),
          content: Text('Are you sure you want to delete this bill?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteBill(index);
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBillsList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _billsBox.length,
      itemBuilder:
          (context, index) => _buildBillCard(_billsBox.getAt(index), index),
    );
  }

  double _calculateSplitAmount() {
    double totalBills = 0;

    for (var i = 0; i < _billsBox.length; i++) {
      var bill = _billsBox.getAt(i);
      totalBills += bill['amount'];
    }
    return totalBills / 2; // Split equally between 2 users
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Rent':
        return Icons.home;
      case 'Electricity':
        return Icons.electric_bolt;
      case 'Groceries':
        return Icons.shopping_cart;
      default:
        return Icons.receipt;
    }
  }

  Widget _buildSettlementReport() {
    double splitAmount = _calculateSplitAmount();

    return Card(
      color: Colors.blue[100],
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Bill Split Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Each person should pay: \₱${splitAmount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        title: Text(
          'Bills Split',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Bill',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _dueDateController,
                        decoration: InputDecoration(
                          labelText: 'Due Date',
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.blue.shade700,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade700,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        readOnly: true,
                        onTap: () => _selectDueDate(context),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          prefixIcon: Icon(
                            Icons.description,
                            color: Colors.blue.shade700,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade700,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount (₱)',
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: Colors.blue.shade700,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade700,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.blue.shade700,
                            ),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 16,
                            ),
                            items:
                                _categories.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getCategoryIcon(value),
                                          color: Colors.blue.shade700,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(value),
                                      ],
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showSummaryAndPayButton,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline),
                              SizedBox(width: 8),
                              Text('Add Bill', style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                _buildSettlementReport(),
                SizedBox(height: 24),
                _buildBillsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
