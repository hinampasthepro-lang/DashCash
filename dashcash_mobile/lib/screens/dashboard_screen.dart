import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = const FlutterSecureStorage();
  List<dynamic> _transactions = [];
  List<dynamic> _filteredTransactions = [];
  String _balance = '\$0.00';
  String _userEmail = 'Loading...';
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _handleUnauthorized() async {
    await _storage.delete(key: 'jwt_token');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchWalletBalance(),
      _fetchTransactions(),
      _fetchUserProfile(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchUserProfile() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5099/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userEmail = data['email'] ?? 'User';
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchWalletBalance() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5099/api/wallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _balance =
              '\$${(data['balance'] as num?)?.toStringAsFixed(2) ?? '0.00'} ${data['currency'] ?? 'USD'}';
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchTransactions() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5099/api/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;
      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      if (response.statusCode == 200) {
        setState(() {
          _transactions = jsonDecode(response.body);
          _applyFilter(_selectedFilter);
        });
      }
    } catch (_) {}
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Deposits') {
        _filteredTransactions =
            _transactions.where((tx) => (tx['amount'] as num) >= 0).toList();
      } else if (filter == 'Withdrawals') {
        _filteredTransactions =
            _transactions.where((tx) => (tx['amount'] as num) < 0).toList();
      } else {
        _filteredTransactions = _transactions;
      }
    });
  }

  void _showAddTransactionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'Deposit';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Transaction'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                      labelText: 'Title (e.g. Salary, Coffee)'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a title'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final n = double.tryParse(value);
                    if (n == null || n <= 0) {
                      return 'Enter a valid number greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(value: 'Deposit', child: Text('Deposit')),
                    DropdownMenuItem(
                        value: 'Withdrawal', child: Text('Withdrawal')),
                  ],
                  onChanged: (val) => type = val ?? 'Deposit',
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _submitTransaction(
                    titleController.text.trim(),
                    double.parse(amountController.text.trim()),
                    type,
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showTransferDialog() {
    final recipientController = TextEditingController();
    final amountController = TextEditingController();
    final transferFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Money (P2P)'),
          content: Form(
            key: transferFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: recipientController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Recipient Email'),
                  validator: (val) => val == null || !val.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (\$)'),
                  validator: (val) {
                    final n = double.tryParse(val ?? '');
                    if (n == null || n <= 0) {
                      return 'Enter an amount greater than 0';
                    }
                    return null;
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
            ElevatedButton(
              onPressed: () async {
                if (transferFormKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _executeTransfer(
                    recipientController.text.trim(),
                    double.parse(amountController.text.trim()),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeTransfer(String email, double amount) async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5099/api/transactions/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipientEmail': email,
          'amount': amount,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer completed successfully!')),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Transfer failed.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Network error. Check connection and try again.')),
      );
    }
  }

  Future<void> _submitTransaction(
      String title, double amount, String type) async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5099/api/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'amount': amount,
          'type': type,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 401) {
        _handleUnauthorized();
        return;
      }

      if (response.statusCode == 200) {
        _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction recorded successfully!')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  errorData['message'] ?? 'Failed to process transaction.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'jwt_token');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHCASH Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _showTransferDialog,
            tooltip: 'Send Money',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('DashCash User'),
              accountEmail: Text(_userEmail),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Balance',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          _balance,
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        color: Colors.green,
                        value: _transactions
                            .where((t) => ((t['amount'] as num?) ?? 0) >= 0)
                            .fold<double>(
                                0.0,
                                (sum, t) =>
                                    sum +
                                    ((t['amount'] as num?)?.toDouble() ?? 0.0)),
                        title: 'In',
                        radius: 50,
                      ),
                      PieChartSectionData(
                        color: Colors.red,
                        value: _transactions
                            .where((t) => ((t['amount'] as num?) ?? 0) < 0)
                            .fold<double>(
                                0.0,
                                (sum, t) =>
                                    sum +
                                    ((t['amount'] as num?)?.toDouble() ?? 0.0))
                            .abs(),
                        title: 'Out',
                        radius: 50,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ToggleButtons(
                    isSelected: [
                      _selectedFilter == 'All',
                      _selectedFilter == 'Deposits',
                      _selectedFilter == 'Withdrawals',
                    ],
                    onPressed: (index) {
                      if (index == 0) _applyFilter('All');
                      if (index == 1) _applyFilter('Deposits');
                      if (index == 2) _applyFilter('Withdrawals');
                    },
                    borderRadius: BorderRadius.circular(8),
                    constraints:
                        const BoxConstraints(minHeight: 32, minWidth: 70),
                    children: const [
                      Text('All', style: TextStyle(fontSize: 12)),
                      Text('In', style: TextStyle(fontSize: 12)),
                      Text('Out', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredTransactions.isEmpty
                        ? const Center(child: Text('No transactions found.'))
                        : ListView.builder(
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final tx = _filteredTransactions[index];
                              final amount = (tx['amount'] as num?) ?? 0;
                              final isDeposit = amount >= 0;
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isDeposit
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    child: Icon(
                                      isDeposit
                                          ? Icons.arrow_downward
                                          : Icons.arrow_upward,
                                      color:
                                          isDeposit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  title: Text(tx['title'] ?? 'Transaction',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(tx['type'] ??
                                      (isDeposit ? 'Deposit' : 'Withdrawal')),
                                  trailing: Text(
                                    '${isDeposit ? '+' : ''}\$${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDeposit ? Colors.green : Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
