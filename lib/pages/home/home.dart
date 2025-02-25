import 'package:faruqbase/services/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:faruqbase/pages/home/transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart'; // Import Lottie
import 'package:flutter_masked_text2/flutter_masked_text2.dart'; // Import untuk MoneyMaskedTextController
import 'package:faruqbase/pages/home/pie.dart'; // Import halaman grafik

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> _transactions = [];
  double _totalBalance = 0; // Set total balance to 0 for new users
  String _selectedFilter = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';

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
          'id': doc.id, // Menyimpan ID dokumen untuk penghapusan dan pengeditan
          'type': doc['type'],
          'amount': doc['amount'],
          'description': doc['description'],
          'date': (doc['timestamp'] as Timestamp).toDate(),
        };
      }).toList();

      setState(() {
        _transactions.clear();
        _transactions.addAll(transactions);
        _totalBalance = _transactions.fold(0, (sum, item) {
          return sum + (item['type'] == 'Income' ? item['amount'] : -item['amount']);
        });
      });
    } catch (e) {
      // Tampilkan pesan kesalahan jika gagal mengambil data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data: $e')),
      );
    }
  }

  void _addTransaction(String type, double amount, String description) {
    // Menentukan kategori berdasarkan deskripsi
    String category = description; // Menggunakan deskripsi sebagai kategori
    if (category != 'Makan' && category != 'Joki' && category != 'Gaji') {
      category = 'Semua'; // Jika kategori tidak sesuai, masukkan ke kategori 'Semua'
    }

    setState(() {
      _transactions.insert(0, {
        'type': type,
        'amount': amount,
        'description': description,
        'date': DateTime.now(),
      });
      _totalBalance += type == 'Income' ? amount : -amount;
    });
  }

  void _editTransaction(String id, String type, double amount, String description) async {
    try {
      await FirebaseFirestore.instance.collection('transactions').doc(id).update({
        'type': type,
        'amount': amount,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update local state
      setState(() {
        final index = _transactions.indexWhere((transaction) => transaction['id'] == id);
        if (index != -1) {
          _transactions[index] = {
            'id': id,
            'type': type,
            'amount': amount,
            'description': description,
            'date': DateTime.now(),
          };
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil diperbarui!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui transaksi: $e')),
      );
    }
  }

  void _deleteTransaction(String id) async {
    // Menampilkan dialog konfirmasi sebelum menghapus
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('transactions').doc(id).delete();

                  setState(() {
                    _transactions.removeWhere((transaction) => transaction['id'] == id);
                    _totalBalance = _transactions.fold(0, (sum, item) {
                      return sum + (item['type'] == 'Income' ? item['amount'] : -item['amount']);
                    });
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaksi berhasil dihapus!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus transaksi: $e')),
                  );
                }
                Navigator.of(context).pop(); // Menutup dialog setelah menghapus
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  List<Map<String, dynamic>> getFilteredTransactions() {
    List<Map<String, dynamic>> filteredList = _transactions.where((transaction) {
      final descriptionMatch = transaction['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      return descriptionMatch;
    }).toList();

    DateTime now = DateTime.now();

    if (_selectedFilter == 'Monthly') {
      filteredList = filteredList.where((transaction) {
        DateTime date = transaction['date'];
        return date.year == now.year && date.month == now.month;
      }).toList();
    } else if (_selectedFilter == 'Yearly') {
      filteredList = filteredList.where((transaction) {
        DateTime date = transaction['date'];
        return date.year == now.year;
      }).toList();
    }

    // Menampilkan semua transaksi jika kategori "Semua" dipilih
    if (_selectedCategory == 'Semua') {
      return filteredList; // Kembalikan semua transaksi yang sudah difilter berdasarkan pencarian
    }

    if (_selectedCategory != 'All') {
      filteredList = filteredList.where((transaction) => transaction['description'] == _selectedCategory).toList();
    }

    return filteredList;
  }

  Widget _categoryButton(String label, IconData icon, Color color) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : const Color(0xFFD2E5E9), // Menggunakan warna baru
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> transaction) {
    final MoneyMaskedTextController _amountController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'Rp ',
      precision: 0,
      initialValue: transaction['amount'],
    );
    final TextEditingController _descriptionController = TextEditingController(text: transaction['description']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Transaksi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final double amount = _amountController.numberValue;
                final String description = _descriptionController.text;

                if (amount > 0 && description.isNotEmpty) {
                  _editTransaction(transaction['id'], transaction['type'], amount, description);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Masukkan jumlah dan deskripsi yang valid')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser  ;
    List<Map<String, dynamic>> filteredTransactions = getFilteredTransactions();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Mengubah latar belakang menjadi putih
      appBar: AppBar(
        title: Text(
          'Money Tracker',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white), // Mengubah warna tulisan
        ),
        backgroundColor: const Color(0xFF293239), // Mengubah warna latar belakang AppBar
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            icon: const Icon(Icons.filter_list, color: Colors.white),
            dropdownColor: const Color(0xFF293239), // Mengubah warna dropdown
            items: ['All', 'Monthly', 'Yearly'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedFilter = value!;
              });
            },
          ),
          IconButton(
            onPressed: () async {
              await AuthService().signout(context: context);
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang di Money Tracker\nby Muhammad Al-Faruq',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD2E5E9), // Mengubah warna latar belakang
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5, spreadRadius: 2), // Menambahkan efek bayangan
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Balance', style: GoogleFonts.raleway(fontSize: 16)),
                    Text(
                      _formatCurrency(_totalBalance),
                      style: GoogleFonts.raleway(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Lottie.asset(
                  'assets/home.json',
                  height: 100,
                  width: 100,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari transaksi...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _categoryButton('Makan', Icons.fastfood, const Color(0xFF293239)), // Mengubah warna kategori
                  _categoryButton('Joki', Icons.assignment, const Color(0xFF293239)), // Mengubah warna kategori
                  _categoryButton('Gaji', Icons.attach_money, const Color(0xFF293239)), // Mengubah warna kategori
                  _categoryButton('Semua', Icons.more_horiz, const Color(0xFF293239)), // Mengubah warna kategori
                ],
              ),
              const SizedBox(height: 20),
              Text('Transaksi Terbaru', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: filteredTransactions.isEmpty
                    ? const Center(child: Text('Belum ada transaksi'))
                    : ListView.builder(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          final isIncome = transaction['type'] == 'Income';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isIncome ? Colors.green : Colors.red,
                                child: Icon(
                                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(transaction['description']),
                              subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(transaction['date'])),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${isIncome ? '+' : '-'} ${_formatCurrency(transaction['amount'])}',
                                    style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteTransaction(transaction['id']);
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showEditDialog(transaction);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
     // Di bagian bottomNavigationBar
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PieChartPage()), // Ganti dengan nama kelas yang sesuai di pie.dart
          );
        },
      ),
    ],
  ),
),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPage(
                onTransactionAdded: _addTransaction,
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF293239), // Mengubah warna tombol FAB
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}