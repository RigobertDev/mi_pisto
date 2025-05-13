import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'auth_provider.dart';
import 'theme_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  final int usuarioId;

  const AddExpenseScreen({Key? key, required this.usuarioId})
      : super(key: key);

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  late DatabaseHelper _dbHelper;

  // Lista de categorías con iconos
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Comida', 'icon': Icons.restaurant},
    {'name': 'Transporte', 'icon': Icons.directions_car},
    {'name': 'Vivienda', 'icon': Icons.home},
    {'name': 'Salud', 'icon': Icons.medical_services},
    {'name': 'Entretenimiento', 'icon': Icons.movie},
    {'name': 'Otros', 'icon': Icons.category},
    {'name': 'Educación', 'icon': Icons.school},
    {'name': 'Ropa', 'icon': Icons.shopping_bag},
    {'name': 'Servicios', 'icon': Icons.settings},
    {'name': 'Regalos', 'icon': Icons.card_giftcard},
    {'name': 'Facturas', 'icon': Icons.receipt_long},
  ];

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper.instance;
    _useSharedPreferences();
  }

  Future<void> _useSharedPreferences() async {
    print('SharedPreferences initialized in AddExpenseScreen');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      builder: (context, child) {
        return Theme(
          data: Provider.of<ThemeProvider>(context).themeMode ==
                  ThemeMode.dark
              ? ThemeData.dark().copyWith(
                  primaryColor: Colors.green,
                  hintColor: Colors.white,
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.green,
                    onPrimary: Colors.white,
                    surface: Colors.black54, // Usando una constante de Colors
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: Colors.grey[800],
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                )
              : ThemeData.light(),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUserId;

      if (userId != null) {
        try {
          final amount = double.parse(_amountController.text);
          if (amount <= 0) {
            _showErrorDialog('El monto debe ser mayor que cero.');
            return;
          }

          final newTransaction = {
            'usuario_id': userId,
            'descripcion': _descriptionController.text,
            'monto': amount,
            'tipo': 'gasto',
            'fecha': _selectedDate.toIso8601String(),
            'categoria': _selectedCategory,
          };

          await _dbHelper.insertarTransaccion(newTransaction);

          if (mounted) {
            Navigator.pop(context, true);
          }
        } catch (e) {
          print("Error saving expense: $e");
          _showErrorDialog('Failed to save expense. Please try again.');
        }
      } else {
        _showErrorDialog('User not authenticated. Please log in.');
      }
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final textFieldBorderColor = Colors.green;
    final backgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final appBarColor = isDarkMode ? Colors.grey[900] : Colors.green;
    final buttonColor = isDarkMode ? Colors.green[700] : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Nuevo Gasto'),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: textFieldBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: textFieldBorderColor),
                  ),
                ),
                style: TextStyle(color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                items: _categories.map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category['name'],
                    child: Row(
                      children: [
                        Icon(category['icon'] as IconData, color: textColor),
                        const SizedBox(width: 10),
                        Text(category['name'], style: TextStyle(color: textColor)),
                      ],
                    ),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: textFieldBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: textFieldBorderColor),
                  ),
                ),
                dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                style: TextStyle(color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecciona una categoría';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto (\$)',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: textFieldBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: textFieldBorderColor),
                  ),
                ),
                style: TextStyle(color: textColor),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un monto';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Text(
                    'Fecha: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}',
                    style: TextStyle(fontSize: 16, color: textColor),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: const Text('Seleccionar Fecha', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveExpense,
                child: const Text('Guardar Gasto', style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: backgroundColor,
    );
  }
}