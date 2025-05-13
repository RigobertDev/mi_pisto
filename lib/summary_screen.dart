import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Importa la librería para las gráficas
import 'home_screen.dart'; // Importa Transaction y TransactionType

class SummaryScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final DateTime currentMonth;

  const SummaryScreen(
      {super.key, required this.transactions, required this.currentMonth});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String _filter = 'Mes'; // Opciones: 'Semana', 'Mes', 'Año'
  DateTime? _startDate;
  DateTime? _endDate;

  List<Transaction> get _filteredTransactions {
    return widget.transactions.where((t) {
      if (t.type == TransactionType.expense) {
        if (_filter == 'Semana') {
          if (_startDate != null && _endDate != null) {
            return t.date.isAfter(
                    _startDate!.subtract(const Duration(days: 1))) &&
                t.date.isBefore(_endDate!.add(const Duration(days: 1)));
          }
          return false;
        } else if (_filter == 'Año') {
          return t.date.year == widget.currentMonth.year;
        } else {
          // 'Mes'
          return t.date.year == widget.currentMonth.year &&
              t.date.month == widget.currentMonth.month;
        }
      }
      return false;
    }).toList();
  }

  Map<String, double> get _categoryExpenses {
    final expenses = <String, double>{};
    for (var transaction in _filteredTransactions) {
      expenses[transaction.category ?? 'Sin Categoría'] =
          (expenses[transaction.category ?? 'Sin Categoría'] ?? 0) +
              transaction.amount.abs();
    }
    return expenses;
  }

  List<PieChartSectionData> get _pieChartData {
    final data = <PieChartSectionData>[];
    final categoryColors = <String, Color>{};
    final categories = _categoryExpenses.keys.toList();

    // Asigna un color único a cada categoría
    for (int i = 0; i < categories.length; i++) {
      categoryColors[categories[i]] = _getColor(i);
    }

    _categoryExpenses.forEach((category, amount) {
      const radius = 80.0; // Increased radius for better visibility
      data.add(
        PieChartSectionData(
          color: categoryColors[category], // Usa el color asignado
          value: amount,
          title:
              '${category.split(' ').first}\n\$${amount.toStringAsFixed(2)}', // Show amount
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ), // Style the labels
        ),
      );
    });
    return data;
  }

  List<BarChartGroupData> get _barChartData {
  final data = <BarChartGroupData>[];
  final categoryColors = <String, Color>{};
  final categories = _categoryExpenses.keys.toList();

  // Asigna un color único a cada categoría
  for (int i = 0; i < categories.length; i++) {
    categoryColors[categories[i]] = _getColor(i);
  }

  _categoryExpenses.forEach((category, amount) {
    final color = categoryColors[category] ??
        Colors
            .blueAccent; // Fallback color, should not happen with _getColor

    data.add(
      BarChartGroupData(
        x: categories.indexOf(category), // Use index for x-axis
        barRods: [
          BarChartRodData(
            toY: amount,
            color: color, // Use the assigned color
            width: 16, // Make bars wider
            borderRadius:
                const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            
          ),
        ],
        
      ),
    );
  });
  return data;
}

// Función para obtener un color único para cada categoría
Color _getColor(int index) {
  const colorList = <Color>[
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.cyan,
  ];
  return colorList[index % colorList.length];
}

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _filter = 'Semana';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Gastos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Gastos por Categoría',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300, // Increased height for the chart
              child: _categoryExpenses.isNotEmpty
                  ? PieChart(
                      PieChartData(
                        sections: _pieChartData,
                        centerSpaceRadius: 40, // Space in the center
                        sectionsSpace: 8, // Space between sections
                      ),
                      swapAnimationDuration:
                          const Duration(milliseconds: 150), // Add animation
                    )
                  : const Center(
                      child: Text(
                          'No hay gastos para mostrar en el gráfico.')), // বার্তা যদি ডেটা না থাকে
            ),
            const SizedBox(height: 30),
            const Text(
              'Tendencia de Gastos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: _categoryExpenses.isNotEmpty
                  ? BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine:
                              false, // Remove vertical grid lines
                          getDrawingHorizontalLine: (value) {
                            return const FlLine(
                              color: Colors
                                  .grey, // Customize horizontal grid lines
                              strokeWidth: 0.8,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget:
                                  (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < _categoryExpenses.keys.length) {
                                  return Text(
                                    _categoryExpenses.keys
                                        .toList()[index]
                                        .split(' ')
                                        .first,
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ); // Shorten category names
                                }
                                return const Text('');
                              },
                              interval: 1, // Show all labels
                            ),
                            
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _barChartData,
                        
                      ),
                      swapAnimationDuration:
                          const Duration(milliseconds: 150), // Add animation
                    )
                  : const Center(
                      child: Text(
                          'No hay gastos para mostrar en el gráfico.')), // বার্তা যদি ডেটা না থাকে
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filter = 'Semana';
                      _startDate =
                          DateTime.now().subtract(const Duration(days: 7));
                      _endDate = DateTime.now();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Semana'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filter = 'Mes';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mes'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filter = 'Año';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Año'),
                ),
                ElevatedButton(
                  onPressed: () => _selectDateRange(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Rango'),
                ),
              ],
            ),
            if (_filter == 'Semana' && _startDate != null && _endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    'Filtrando desde: ${DateFormat('dd-MM-yyyy').format(_startDate!)} hasta: ${DateFormat('dd-MM-yyyy').format(_endDate!)}'),
              ),
          ],
        ),
      ),
    );
  }
}
