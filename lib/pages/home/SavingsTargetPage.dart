import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lottie/lottie.dart'; // Import Lottie
import 'target.dart'; // Pastikan untuk mengimpor halaman target
import 'home.dart'; // Pastikan untuk mengimpor halaman Home
import 'pie.dart'; // Pastikan untuk mengimpor halaman PieChartPage

class SavingsTargetPage extends StatefulWidget {
  final double totalBalance; // Variabel untuk total saldo

  const SavingsTargetPage({Key? key, required this.totalBalance}) : super(key: key);

  @override
  _SavingsTargetPageState createState() => _SavingsTargetPageState();
}

class _SavingsTargetPageState extends State<SavingsTargetPage> {
  late final FirebaseMessaging _firebaseMessaging;

  @override
  void initState() {
    super.initState();
    _firebaseMessaging = FirebaseMessaging.instance;
    _requestPermission();
    _getToken();
  }

  void _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User  granted permission');
    } else {
      print('User  declined or has not accepted permission');
    }
  }

  void _getToken() async {
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
    // Simpan token ke Firestore
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser ?.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  void _schedulePaymentReminder(String userId, DateTime dueDate) async {
    // Simpan tanggal jatuh tempo pembayaran di Firestore
    await FirebaseFirestore.instance.collection('reminders').add({
      'userId': userId,
      'dueDate': dueDate,
      'reminderAmount': 100000, // Contoh jumlah, sesuaikan dengan kebutuhan
      'transactionType': 'Pembayaran', // Contoh tipe transaksi
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser ;

    // Format total saldo menggunakan MoneyMaskedTextController
    final MoneyMaskedTextController _totalBalanceController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'Rp ',
      precision: 0,
      initialValue: widget.totalBalance,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Target Tabungan',
          style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white), // Ubah warna teks menjadi putih
        ),
        backgroundColor: const Color(0xFF293239),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tampilkan ikon total saldo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.account_balance_wallet, size: 40, color: Colors.green),
                Text(
                  _totalBalanceController.text, // Format total saldo
                  style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('targets')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(), // Ambil semua target tanpa filter bulan dan tahun
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _emptyState('Belum ada target tabungan!', 'assets/data.json');
                  }

                  return ListView(
                    children: snapshot.data!.docs.map((target) {
                      double targetAmount = (target['targetAmount'] as num).toDouble();
                      double progress = targetAmount > 0 ? widget.totalBalance / targetAmount : 0;

                      return Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Target Tabungan (${target['month']}/${target['year']}):',
                                  style: GoogleFonts.raleway(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: progress > 1 ? 1 : progress, // Batasi nilai progres maksimum 1
                                backgroundColor: Colors.grey[300],
                                color: Colors.green,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Rp ${_totalBalanceController.text} / Rp ${MoneyMaskedTextController(
                                  decimalSeparator: ',',
                                  thousandSeparator: '.',
                                  leftSymbol: 'Rp ',
                                  precision: 0,
                                  initialValue: targetAmount,
                                ).text}',
                                style: GoogleFonts.raleway(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      _showEditTargetDialog(context, target.id, targetAmount);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteTargetDialog(context, target.id);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reminders')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(), // Ambil semua pengingat tanpa filter bulan dan tahun
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _emptyState('Tidak ada transaksi yang harus dilakukan', 'assets/data.json');
                  }

                  double totalTransaction = snapshot.data!.docs.fold(
                      0,
                      (sum, doc) =>
                          sum + (doc['reminderAmount'] as num).toDouble());

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daftar Transaksi:',
                          style: GoogleFonts.raleway(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView(
                          children: snapshot.data!.docs.map((doc) {
                            Timestamp timestamp = doc['timestamp']; // Ambil timestamp
                            DateTime dateTime = timestamp.toDate(); // Konversi ke DateTime
                            String formattedDate = "${dateTime.toLocal()}".split(' ')[0]; // Format tanggal

                            // Format jumlah transaksi menggunakan MoneyMaskedTextController
                            final MoneyMaskedTextController _reminderAmountController = MoneyMaskedTextController(
                              decimalSeparator: ',',
                              thousandSeparator: '.',
                              leftSymbol: 'Rp ',
                              precision: 0,
                              initialValue: (doc['reminderAmount'] as num).toDouble(),
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                title: Text(doc['transactionType'],
                                    style: GoogleFonts.raleway(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_reminderAmountController.text), // Tampilkan jumlah transaksi
                                    Text(
                                      formattedDate, // Tampilkan tanggal
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        _showEditTransactionDialog(context, doc.id, doc['transactionType'], doc['reminderAmount']);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _deleteTransactionDialog(context, doc.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      _balanceWarning(widget.totalBalance, totalTransaction),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TargetPage()), // Arahkan ke halaman target
          );
        },
        backgroundColor: const Color(0xFF293239),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showEditTargetDialog(BuildContext context, String targetId, double currentTargetAmount) {
    final MoneyMaskedTextController _targetAmountController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'Rp ',
      precision: 0,
      initialValue: currentTargetAmount,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Target Tabungan'),
          content: TextField(
            controller: _targetAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Jumlah Target'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                double newTargetAmount = _targetAmountController.numberValue;
                if (newTargetAmount > 0) {
                  await FirebaseFirestore.instance.collection('targets').doc(targetId).update({
                    'targetAmount': newTargetAmount,
                  });
                  // Kirim notifikasi setelah mengupdate target
                  _sendNotification("Target Tabungan Diperbarui", "Target baru Anda adalah Rp ${newTargetAmount.toString()}");
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Jumlah target harus lebih besar dari 0')),
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

  void _deleteTargetDialog(BuildContext context, String targetId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus target tabungan ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('targets').doc(targetId).delete();
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTransactionDialog(BuildContext context, String transactionId, String currentType, double currentAmount) {
    final MoneyMaskedTextController _amountController = MoneyMaskedTextController(
      decimalSeparator: ',',
      thousandSeparator: '.',
      leftSymbol: 'Rp ',
      precision: 0,
      initialValue: currentAmount,
    );

    final TextEditingController _typeController = TextEditingController(text: currentType);

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
                decoration: const InputDecoration(labelText: 'Jumlah Transaksi'),
              ),
              TextField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: 'Tipe Transaksi'),
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
              onPressed: () async {
                double newAmount = _amountController.numberValue;
                String newType = _typeController.text.trim(); // Ambil dari TextField

                if (newAmount > 0 && newType.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('reminders').doc(transactionId).update({
                    'reminderAmount': newAmount,
                    'transactionType': newType,
                  });
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Jumlah transaksi harus lebih besar dari 0 dan tipe transaksi tidak boleh kosong')),
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

  void _deleteTransactionDialog(BuildContext context, String transactionId) {
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
                await FirebaseFirestore.instance.collection('reminders').doc(transactionId).delete();
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _sendNotification(String title, String body) {
    // Logika untuk mengirim notifikasi menggunakan FCM
    // Anda bisa menggunakan server untuk mengirim notifikasi ke token FCM
    // Contoh: menggunakan HTTP POST ke endpoint FCM
    print("Notifikasi: $title - $body");
  }

  Widget _emptyState(String message, String lottiePath) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Lottie.asset(
              lottiePath,
              height: 100, // Atur tinggi animasi sesuai kebutuhan
              width: 100, // Atur lebar animasi sesuai kebutuhan
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.raleway(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _balanceWarning(double balance, double totalTransaction) {
    if (balance < totalTransaction) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saldo Anda kurang dari jumlah transaksi yang harus dilakukan! Harap tambah tabungan.',
                  style: GoogleFonts.raleway(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox();
  }
}