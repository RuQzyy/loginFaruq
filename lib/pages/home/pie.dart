import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'target.dart';
import 'SavingsTargetPage.dart'; 

class PieChartPage extends StatefulWidget {
  const PieChartPage({Key? key}) : super(key: key);

  @override
  _PieChartPageState createState() => _PieChartPageState();
}

class _PieChartPageState extends State<PieChartPage> {
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _categoryTotals = {};
  bool _showIncome = true;
  String _selectedMonth = 'All'; // Menyimpan bulan yang dipilih
  final List<String> _months = [
    'All',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  double _totalBalance = 0; // Tambahkan variabel untuk total balance

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _fetchTotalBalance(); // Ambil total balance saat inisialisasi
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
            'date': (doc['timestamp'] as Timestamp).toDate(), // Menyimpan tanggal
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

  Future<void> _fetchTotalBalance() async {
    final user = FirebaseAuth.instance.currentUser ;
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          setState(() {
            _totalBalance = (snapshot['totalBalance'] as num).toDouble(); // Ambil total balance dari Firestore
          });
        }
      } catch (e) {
        _showErrorSnackBar('Gagal mengambil total balance: $e');
      }
    }
  }

  void _calculateCategoryTotals() {
    _categoryTotals.clear();
    for (var transaction in _transactions) {
      String category = transaction['description'];
      double amount = transaction['amount'];
      DateTime date = transaction['date'];

      // Filter berdasarkan bulan yang dipilih
      if (_selectedMonth != 'All') {
        if (date.month != _getMonthIndex(_selectedMonth)) continue; // Jika bulan tidak cocok, lewati
      }

      if (_showIncome && transaction['type'] == 'Income') {
        _categoryTotals[category] = (_categoryTotals[category] ?? 0) + amount;
      } else if (!_showIncome && transaction['type'] == 'Expense') {
        _categoryTotals[category] = (_categoryTotals[category] ?? 0) + amount;
      }
    }

    // Hapus kategori yang tidak dikenali
    _categoryTotals.removeWhere((key, value) => !_isKnownCategory(key));
  }

  int _getMonthIndex(String month) {
    switch (month) {
      case 'Januari': return 1;
      case 'Februari': return 2;
      case 'Maret': return 3;
      case 'April': return 4;
      case 'Mei': return 5;
      case 'Juni': return 6;
      case 'Juli': return 7;
      case 'Agustus': return 8;
      case 'September': return 9;
      case 'Oktober': return 10;
      case 'November': return 11;
      case 'Desember': return 12;
      default: return 0; // Untuk 'All'
    }
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
        automaticallyImplyLeading: false, // Menghilangkan tombol kembali
        title: Text(
          'Grafik Pie Transaksi',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF293239),
      ),
      body: Column(
        children: [
          _buildMonthDropdown(), // Menambahkan dropdown bulan
          _buildToggleButtons(),
          const SizedBox(height: 20),
          _buildTotalDisplay(),
          Expanded(child: _buildPieChart()),
          _buildLegend(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
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
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButton<String>(
        value: _selectedMonth,
        icon: const Icon(Icons.calendar_today, color: Colors.black),
        isExpanded: true,
        items: _months.map((String month) {
          return DropdownMenuItem<String>(
            value: month,
            child: Text(month == 'All' ? 'Semua Bulan' : month),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedMonth = value!;
            _calculateCategoryTotals(); // Hitung ulang total kategori saat bulan berubah
          });
        },
      ),
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