import 'package:faruqbase/services/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:faruqbase/pages/home/transaction.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:faruqbase/pages/home/pie.dart';
import 'SavingsTargetPage.dart'; // Pastikan ini ada di bagian atas file

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> _transactions = [];
  double _totalBalance = 0;
  String _selectedFilter = 'All';
  String _selectedMonth = 'All';
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  void _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser ;
    if (user != null) {
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: user.uid)
            .get();

        List<Map<String, dynamic>> transactions = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: $e')),
        );
      }
    } else {
      setState(() {
        _totalBalance = 0;
        _transactions.clear();
      });
    }
  }

  void _addTransaction(String type, double amount, String description) {
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
                Navigator.of(context).pop();
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
      return transaction['description'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    DateTime now = DateTime.now();

    if (_selectedFilter == 'Monthly' && _selectedMonth != 'All') {
      int monthIndex = _getMonthIndex(_selectedMonth);
      filteredList = filteredList.where((transaction) {
        DateTime date = transaction['date'];
        return date.year == now.year && date.month == monthIndex;
      }).toList();
    } else if (_selectedFilter == 'Yearly') {
      filteredList = filteredList.where((transaction) {
        DateTime date = transaction['date'];
        return date.year == now.year;
      }).toList();
    }

    if (_selectedCategory != 'Semua') {
      filteredList = filteredList.where((transaction) {
        return transaction['description'].toLowerCase().contains(_selectedCategory.toLowerCase());
      }).toList();
    }

    return filteredList;
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
          color: isSelected ? color.withOpacity(0.3) : const Color(0xFFD2E5E9),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser ;
    List<Map<String, dynamic>> filteredTransactions = getFilteredTransactions();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Money Tracker',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF293239), Color(0xFF3B4A4D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              dropdownColor: const Color(0xFF3B4A4D),
              items: ['All', 'Monthly', 'Yearly'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                  _selectedMonth = 'All';
                });
              },
            ),
          ),
          if (_selectedFilter == 'Monthly') ...[
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: DropdownButton<String>(
                value: _selectedMonth,
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                dropdownColor: const Color(0xFF3B4A4D),
                items: [
                  'All',
                  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
                ].map((String month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Text(month == 'All' ? 'Semua Bulan' : month, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value!;
                  });
                },
              ),
            ),
          ],
          IconButton(
            onPressed: () async {
              await AuthService().signout(context: context);
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                    color: const Color(0xFFD2E5E9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 5, spreadRadius: 2),
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
                Text('Transaksi Terbaru', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _categoryButton('Makan', Icons.fastfood, const Color(0xFF293239)),
                    _categoryButton('Joki', Icons.assignment, const Color(0xFF293239)),
                    _categoryButton('Gaji', Icons.attach_money, const Color(0xFF293239)),
                    _categoryButton('Semua', Icons.more_horiz, const Color(0xFF293239)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 300,
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
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Color(0xFF293239)),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.pie_chart, color: Color(0xFF293239)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PieChartPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.flag, color: Color(0xFF293239)), // Ikon target/goal
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavingsTargetPage(totalBalance: _totalBalance), // Kirim total saldo
                  ),
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
        backgroundColor: const Color(0xFF293239),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}