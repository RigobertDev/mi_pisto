import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart'; // Importa la clase Transaction y el enum TransactionType

class EditTransactionScreen extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionState();
}

class _EditTransactionState extends State<EditTransactionScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Comida', 'Facturas', 'Transporte', 'Ocio', 'Otros']; // Ejemplo de categorías

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.transaction.description;
    _amountController.text = widget.transaction.amount.toStringAsFixed(2).replaceAll('-', ''); // Remove negative sign for editing
    _selectedCategory = widget.transaction.category;
    _selectedDate = widget.transaction.date;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2026),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Transacción'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: _categories.map((category) => DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  ))
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Monto (\$)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Text('Fecha: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}'),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Seleccionar Fecha'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final description = _descriptionController.text;
                final amount = double.tryParse(_amountController.text);

                if (description.isNotEmpty && amount != null) {
                  Navigator.pop(
                    context,
                    Transaction(
                      description: description,
                      amount: widget.transaction.type == TransactionType.expense ? -amount.abs() : amount.abs(),
                      type: widget.transaction.type,
                      date: _selectedDate,
                      category: _selectedCategory,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, ingresa descripción y monto válidos.')),
                  );
                }
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}