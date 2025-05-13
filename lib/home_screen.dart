import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'summary_screen.dart';
// import 'budget_management_screen.dart'; // Importación eliminada
import 'add_expense_screen.dart';
import 'database_helper.dart';
import 'auth_provider.dart';
import 'add_funds_screen.dart';
import 'edit_transaction_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
// import 'budget_provider.dart'; // Importación eliminada
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

enum TransactionType { income, expense }

class Transaction {
  int? id;
  String description;
  double amount;
  TransactionType type;
  DateTime date;
  String? category;

  Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    this.category,
  });

  Transaction.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int?,
        description = map['descripcion'] as String,
        amount = map['monto'] as double,
        type = map['tipo'] == 'ingreso' ? TransactionType.income : TransactionType.expense,
        date = DateTime.parse(map['fecha'] as String),
        category = map['categoria'] as String?;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'descripcion': description,
      'monto': amount,
      'tipo': type == TransactionType.income ? 'ingreso' : 'gasto',
      'fecha': date.toIso8601String(),
      'categoria': category,
    };
  }
}

class _HomeScreenState extends State<HomeScreen> {
  double _monthlyBalance = 0.0;
  final List<Transaction> _transactions = [];
  DateTime _currentMonth = DateTime.now();
  bool _isDarkMode = false;
  // String _selectedBudgetType = 'Semanal'; // Variable eliminada
  late DatabaseHelper _dbHelper;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _dbHelper = DatabaseHelper.instance;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      await _loadTransactions();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // final budgetProvider = Provider.of<BudgetProvider>(context, listen: false); // Provider eliminado
      if (authProvider.currentUserId != null) {
        // await budgetProvider.loadBudgetAndCalculateSpent(authProvider.currentUserId!); // Función eliminada
        // _selectedBudgetType = budgetProvider.selectedBudgetType; // Variable eliminada
      }
      _calculateMonthlyBalance();
    } catch (e) {
      print("Error in _loadInitialData: $e");
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'Failed to load initial data. Please try again later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  String get _formattedMonth => DateFormat('MMMM').format(_currentMonth);

  Future<void> _loadTransactions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUserId;

    if (userId != null) {
      try {
        final firstDayOfMonth =
            DateTime(_currentMonth.year, _currentMonth.month, 1);
        final lastDayOfMonth =
            DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

        final transactionsData =
            await _dbHelper.obtenerTransaccionesPorUsuario(
                userId, firstDayOfMonth, lastDayOfMonth);
        setState(() {
          _transactions.clear();
          for (var data in transactionsData) {
            _transactions.add(Transaction.fromMap(data));
          }
          _calculateMonthlyBalance();
        });
      } catch (e) {
        print("Error loading transactions: $e");
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text(
                  'Failed to load transactions. Please try again later.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _addFunds() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final budgetProvider = Provider.of<BudgetProvider>(context, listen: false); // Provider eliminado
    final userId = authProvider.currentUserId;
    final addedAmount = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFundsScreen(selectedMonth: _currentMonth),
      ),
    );
    if (addedAmount != null && addedAmount is double && userId != null) {
      await _loadTransactions();
      // await budgetProvider.loadBudgetAndCalculateSpent(userId); // Función eliminada
    }
  }

  void _addExpense() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final budgetProvider = Provider.of<BudgetProvider>(context, listen: false); // Provider eliminado
    final userId = authProvider.currentUserId;

    if (userId != null) {
      final newExpenseAdded = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseScreen(usuarioId: userId),
        ),
      );
      if (newExpenseAdded == true) {
        await _loadTransactions();
        // await budgetProvider.loadBudgetAndCalculateSpent(userId); // Función eliminada
      }
    }
  }

  Future<void> _editTransaction(int index) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final budgetProvider = Provider.of<BudgetProvider>(context, listen: false); // Provider eliminado
    final userId = authProvider.currentUserId;
    final editedTransaction = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditTransactionScreen(transaction: _transactions[index]),
      ),
    );
    if (editedTransaction != null &&
        editedTransaction is Transaction &&
        userId != null) {
      try {
        await _dbHelper.actualizarTransaccion(
            editedTransaction.id!, editedTransaction.toMap());
        await _loadTransactions();
        // await budgetProvider.loadBudgetAndCalculateSpent(userId); // Función eliminada
      } catch (e) {
        print("Error updating transaction: $e");
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text(
                  'Failed to update the transaction. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _deleteTransaction(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final budgetProvider = Provider.of<BudgetProvider>(context, listen: false); // Provider eliminado
    final userId = authProvider.currentUserId;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Transacción'),
          content:
              const Text('¿Estás seguro de que deseas eliminar esta transacción?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final transactionToDelete = _transactions[index];
                if (transactionToDelete.id != null && userId != null) {
                  try {
                    await _dbHelper
                        .eliminarTransaccion(transactionToDelete.id!);
                    _transactions.removeAt(index);
                    await _loadTransactions();
                    // budgetProvider.loadBudgetAndCalculateSpent(userId); // Función eliminada
                  } catch (e) {
                    print("Error deleting transaction: $e");
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: const Text(
                              'Failed to delete the transaction.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _changeMonth(int direction) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final budgetProvider = Provider.of<BudgetProvider>(context, listen: false); // Provider eliminado
    final userId = authProvider.currentUserId;
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + direction, 1);
      _loadTransactions();
      if (userId != null) {
        // budgetProvider.loadBudgetAndCalculateSpent(userId); // Función eliminada
      }
    });
  }

  void _calculateMonthlyBalance() {
    _monthlyBalance = _transactions.fold(0.0, (previousValue, transaction) {
      if (transaction.date.year == _currentMonth.year &&
          transaction.date.month == _currentMonth.month) {
        return previousValue + transaction.amount;
      }
      return previousValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMonthTransactions = _transactions
        .where((t) =>
            t.date.year == _currentMonth.year &&
            t.date.month == _currentMonth.month)
        .toList();
    final expensesByCategory = <String, double>{};
    double totalExpenses = 0;

    for (final transaction in currentMonthTransactions) {
      if (transaction.type == TransactionType.expense) {
        final expenseAmount = transaction.amount.abs();
        expensesByCategory[transaction.category ?? 'Sin Categoría'] =
            (expensesByCategory[transaction.category ?? 'Sin Categoría'] ?? 0) +
                expenseAmount;
        totalExpenses += expenseAmount;
      }
    }
    // final budgetProvider = Provider.of<BudgetProvider>(context); // Provider eliminado

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Image.asset(
          'assets/mi pisto.png',
          height: 50,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 30),
            onPressed: _addFunds,
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.attach_money, size: 30),
            onPressed: _addExpense,
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                'Mi Pisto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo del Mes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '\$${_monthlyBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _monthlyBalance < 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  if (_monthlyBalance < 0)
                    const Text(
                      '-',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SummaryScreen(
                          transactions: _transactions,
                          currentMonth: _currentMonth,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                  ),
                  label: const Text('Resumen'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              //Eliminado el boton de presupuesto
              const SizedBox(height: 10),
              const Text(
                'Gastos por Categoría',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (expensesByCategory.isEmpty)
                const Text('No hay gastos este mes.'),
              if (expensesByCategory.isNotEmpty)
                Column(
                  children: expensesByCategory.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${entry.key}:',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text('\$${entry.value.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              // Selector de tipo de presupuesto eliminado
              // Aquí se muestran las barras de presupuesto eliminadas
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transacciones - $_formattedMonth',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ],
              ),
              if (currentMonthTransactions.isEmpty)
                const Text('No hay transacciones este mes.'),
              if (currentMonthTransactions.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentMonthTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = currentMonthTransactions[index];
                    final formattedDate =
                        DateFormat('dd-MM-yyyy').format(transaction.date);
                    final amountColor =
                        transaction.type == TransactionType.income
                            ? Colors.green
                            : Colors.red;
                    IconData iconData;
                    if (transaction.type == TransactionType.income) {
                      iconData = Icons.arrow_downward;
                    } else {
                      iconData = Icons.arrow_upward;
                    }

                    return Card(
                      child: ListTile(
                        leading: Icon(iconData, color: amountColor),
                        title: Text(transaction.description),
                        subtitle: Text(
                            '$formattedDate ${transaction.category != null ? '(${transaction.category})' : ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('\$${transaction.amount.toStringAsFixed(2)}',
                                style: TextStyle(color: amountColor)),
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.green),
                              onPressed: () =>
                                  _editTransaction(_transactions.indexOf(transaction)),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _deleteTransaction(_transactions.indexOf(transaction)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}


