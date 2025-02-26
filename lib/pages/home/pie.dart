import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';

class PieChartPage extends StatefulWidget {
  const PieChartPage({Key? key}) : super(key: key);

  @override
  _PieChartPageState createState() => _PieChartPageState();
}

class _PieChartPageState extends State<PieChartPage> {
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _categoryTotals = {};
  bool _showIncome = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser ;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user.uid)
            .get();

        List<Map<String, dynamic>> transactions = snapshot.docs.map((doc) {
          return {
            'type': doc['type'],
            'amount': doc['amount'],
            'description': doc['description'],
          };
        }).toList();

        setState(() {
          _transactions = transactions;
          _calculateCategoryTotals();
        });
      } catch (e) {
        _showErrorSnackBar('Gagal mengambil data: $e');
      }
    } else {
      _showErrorSnackBar('Silakan login untuk melihat grafik.');
    }
  }

  void _calculateCategoryTotals() {
    _categoryTotals.clear();
    for (var transaction in _transactions) {
      String category = transaction['description'];
      double amount = transaction['amount'];

      if (_showIncome && transaction['type'] == 'Income') {
        _categoryTotals[category] = (_categoryTotals[category] ?? 0) + amount;
      } else if (!_showIncome && transaction['type'] == 'Expense') {
        _categoryTotals[category] = (_categoryTotals[category] ?? 0) + amount;
      }
    }

    // Hapus kategori yang tidak dikenali
    _categoryTotals.removeWhere((key, value) => !_isKnownCategory(key));
  }

  bool _isKnownCategory(String category) {
    const knownCategories = [
      'Makan',
      'Joki',
      'Uang Semester',
      'Gaji',
      'Shopping',
      'Lainnya',
    ];
    return knownCategories.contains(category) || category.isNotEmpty;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grafik Pie Transaksi',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF293239),
      ),
      body: Column(
        children: [
          _buildToggleButtons(),
          const SizedBox(height: 20),
          _buildTotalDisplay(),
          Expanded(child: _buildPieChart()),
          _buildLegend(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(), // This line is now correct
    );
  }

  Widget _buildToggleButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton('Income', true),
        const SizedBox(width: 10),
        _buildToggleButton('Expense', false),
      ],
    );
  }

  Widget _buildToggleButton(String label, bool isIncome) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _showIncome = isIncome;
          _calculateCategoryTotals();
        });
      },
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD2E5E9),
      ),
    );
  }

  Widget _buildTotalDisplay() {
    double total = _categoryTotals.values.fold(0.0, (sum, value) => sum + value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'Total ${_showIncome ? "Pendapatan" : "Pengeluaran"}: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(total)}',
        style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: _categoryTotals.entries.map((entry) {
          return PieChartSectionData(
            value: entry.value,
            color: _getColorForCategory(entry.key),
            title: '${(entry.value / _categoryTotals.values.fold(0.0, (sum, value) => sum + value) * 100).toStringAsFixed(1)}%',
            radius: 60,
          );
        }).toList(),
        borderData: FlBorderData(show: false),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        startDegreeOffset: 180,
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: _categoryTotals.entries.map((entry) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                color: _getColorForCategory(entry.key),
              ),
              const SizedBox(width: 8),
              Text('${entry.key}: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(entry.value)}'),
            ],
          );
        }).toList(),
      ),
    );
  }

  BottomAppBar _buildBottomNavigationBar() { // Changed return type to BottomAppBar
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF293239)),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Home()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.pie_chart, color: Color(0xFF293239)),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PieChartPage()));
            },
          ),
        ],
      ),
    );
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case 'Makan':
        return Colors.blue;
      case 'Joki':
        return Colors.orange;
      case 'Uang Semester':
        return Colors.red;
      case 'Gaji':
        return Colors.green;
      case 'Shopping':
        return Colors.purple;
      case 'Lainnya':
        return Colors.grey;
      default:
        return Color.fromARGB(255, 255, 255, 0); // Menggunakan warna default jika kategori tidak dikenali
    }
  }
}