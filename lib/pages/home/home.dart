import 'package:faruqbase/services/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:faruqbase/pages/home/transaction.dart';
import 'package:fl_chart/fl_chart.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> _transactions = [];

  void _addTransaction(String type, double amount, String description) {
    setState(() {
      _transactions.add({
        'type': type,
        'amount': amount,
        'description': description,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Money Tracker',
            style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff0D6EFD),
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blue.shade700),
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
              // Greeting
              Text(
                'Hello👋, ${user?.email ?? 'Guest'}',
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              
              // Balance Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Balance', style: GoogleFonts.raleway(fontSize: 16)),
                    Text('Rp 5.000.000',
                        style: GoogleFonts.raleway(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Access Categories
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _categoryButton('Makan', Icons.fastfood, Colors.orange),
                  _categoryButton('Transport', Icons.directions_bus, Colors.blue),
                  _categoryButton('Gaji', Icons.attach_money, Colors.green),
                  _categoryButton('Lainnya', Icons.more_horiz, Colors.grey),
                ],
              ),
              const SizedBox(height: 20),

              // Statistics Chart
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: 30, color: Colors.red, title: 'Belanja'),
                      PieChartSectionData(value: 50, color: Colors.green, title: 'Gaji'),
                      PieChartSectionData(value: 20, color: Colors.blue, title: 'Transport'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Recent Transactions
              Text('Recent Transactions',
                  style: GoogleFonts.raleway(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: _transactions.isEmpty
                    ? const Center(child: Text('Belum ada transaksi'))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          final isIncome = transaction['type'] == 'Income';
                          return ListTile(
                            leading: Icon(
                              isIncome ? Icons.attach_money : Icons.shopping_cart,
                              color: isIncome ? Colors.green : Colors.red,
                            ),
                            title: Text(transaction['description']),
                            subtitle: Text('Rp ${transaction['amount']}'),
                            trailing: Text(
                              '${isIncome ? '+' : '-'} Rp ${transaction['amount']}',
                              style: TextStyle(color: isIncome ? Colors.green : Colors.red),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff0D6EFD),
        child: const Icon(Icons.add),
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
      ),
    );
  }

  Widget _categoryButton(String title, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 5),
        Text(title, style: GoogleFonts.raleway(fontSize: 12)),
      ],
    );
  }
}
