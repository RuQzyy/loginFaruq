import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Tambahkan import ini
import 'home.dart'; // Pastikan untuk mengimpor halaman home

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

  void _fetchTransactions() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('transactions').get();
      List<Map<String, dynamic>> transactions = snapshot.docs.map((doc) {
        return {
          'type': doc['type'],
          'amount': doc['amount'],
          'description': doc['description'], // Menyimpan deskripsi untuk kategori
        };
      }).toList();

      setState(() {
        _transactions = transactions;
        _calculateCategoryTotals();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    }
  }

  void _calculateCategoryTotals() {
    _categoryTotals.clear();
    for (var transaction in _transactions) {
      String category = transaction['description']; // Menggunakan deskripsi sebagai kategori
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
    // Daftar kategori yang dikenali
    const knownCategories = [
      'Makan',
      'Joki',
      'Uang Semester',
      'Gaji',
      'Shopping',
      'Lainnya', // Pastikan kategori "Lainnya" ada di sini
    ];
    return knownCategories.contains(category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grafik Pie Transaksi',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white), // Mengubah warna tulisan
        ),
        backgroundColor: const Color(0xFF293239), // Warna AppBar
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showIncome = true;
                    _calculateCategoryTotals(); // Hitung ulang total kategori
                  });
                },
                child: Text('Income'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD2E5E9), // Warna tombol
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showIncome = false;
                    _calculateCategoryTotals(); // Hitung ulang total kategori
                  });
                },
                child: Text('Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD2E5E9), // Warna tombol
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tampilkan total pendapatan atau pengeluaran
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Total ${_showIncome ? "Pendapatan" : "Pengeluaran"}: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(_categoryTotals.values.fold(0.0, (sum, value) => sum + value))}',
              style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: _categoryTotals.entries.map((entry) {
                  return PieChartSectionData(
                    value: entry.value,
                    color: _getColorForCategory(entry.key), // Mendapatkan warna berdasarkan kategori
                    title: '${(entry.value / _categoryTotals.values.fold(0.0, (sum, value) => sum + value) * 100).toStringAsFixed(1)}%', // Menampilkan persentase
                    radius: 60,
                  );
                }).toList(),
                borderData: FlBorderData(show: false),
                centerSpaceRadius: 40,
                sectionsSpace: 2, // Jarak antar bagian
                startDegreeOffset: 180, // Memutar grafik untuk tampilan yang lebih baik
              ),
            ),
          ),
          // Keterangan di bawah grafik
          Padding(
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
                    Text('${entry.key}: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(entry.value)}'), // Format nominal
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Color(0xFF293239)),
              onPressed: () {
                // Navigasi ke halaman home
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.pie_chart, color: Color(0xFF293239)),
              onPressed: () {
                // Navigasi ke halaman grafik
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PieChartPage()),
                );
              },
            ),
          ],
        ),
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
        return Colors.transparent; // Menghindari warna untuk kategori yang tidak dikenali
    }
  }
}