import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class AddFundsScreen extends StatefulWidget {
  final DateTime selectedMonth;

  const AddFundsScreen({super.key, required this.selectedMonth});

  @override
  State<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  final _amountController = TextEditingController();

  void _addFunds() async {
    final amount = double.tryParse(_amountController.text);
    if (amount != null && amount > 0) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUserId;

      if (userId != null) {
        // Usa el mes seleccionado que se pasó desde HomeScreen
        final transactionDate = DateTime(widget.selectedMonth.year, widget.selectedMonth.month, 1);
        final formattedDate = DateFormat('yyyy-MM-dd').format(transactionDate);

        final transaction = {
          'usuario_id': userId,
          'descripcion': 'Añadir fondos',
          'monto': amount,
          'fecha': formattedDate,
          'tipo': 'ingreso',
        };

        final dbHelper = Provider.of<DatabaseHelper>(context, listen: false);
        int id = await dbHelper.insertarTransaccion(transaction);

        if (id > 0) {
          Navigator.pop(context, amount);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al añadir fondos.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Fondos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto a añadir (\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addFunds,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Añadir Fondos'),
            ),
          ],
        ),
      ),
    );
  }
}