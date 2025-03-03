import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class TargetPage extends StatefulWidget {
  const TargetPage({Key? key}) : super(key: key);

  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  final _formKey = GlobalKey<FormState>();
  final MoneyMaskedTextController _targetController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'Rp ',
    precision: 0,
  );
  final TextEditingController _transactionTypeController = TextEditingController();
  final MoneyMaskedTextController _reminderAmountController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'Rp ',
    precision: 0,
  );
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _addTarget() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser ;
      final now = DateTime.now();
      try {
        await FirebaseFirestore.instance.collection('targets').add({
          'userId': user!.uid,
          'targetAmount': double.parse(_targetController.text.replaceAll('Rp ', '').replaceAll('.', '').replaceAll(',', '.').trim()),
          'progress': 0,
          'timestamp': FieldValue.serverTimestamp(),
          'month': now.month, // Menyimpan bulan
          'year': now.year,   // Menyimpan tahun
        });
        _showSnackBar('Target keuangan ditambahkan!', Colors.green);
        _targetController.clear();
      } catch (e) {
        _showSnackBar('Gagal menambahkan target: ${e.toString()}', Colors.red);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addReminder() async {
    if (_transactionTypeController.text.isNotEmpty && _reminderAmountController.text.isNotEmpty && _selectedDate != null) {
      final user = FirebaseAuth.instance.currentUser ;
      final now = DateTime.now();
      try {
        await FirebaseFirestore.instance.collection('reminders').add({
          'userId': user!.uid,
          'transactionType': _transactionTypeController.text,
          'reminderAmount': double.parse(_reminderAmountController.text.replaceAll('Rp ', '').replaceAll('.', '').replaceAll(',', '.').trim()),
          'reminderDate': _selectedDate,
          'timestamp': FieldValue.serverTimestamp(),
          'month': now.month, // Menyimpan bulan
          'year': now.year,   // Menyimpan tahun
        });

        // Logika untuk mengatur pengingat 2 hari sebelum tanggal jatuh tempo
        DateTime reminderDate = _selectedDate!.subtract(Duration(days: 2));
        await FirebaseFirestore.instance.collection('reminders').doc(user.uid).set({
          'reminderDate': reminderDate,
        }, SetOptions(merge: true));

        _showSnackBar('Pengingat transaksi ditambahkan!', Colors.blue);
        _transactionTypeController.clear();
        _reminderAmountController.clear();
        _selectedDate = null; // Reset date
      } catch (e) {
        _showSnackBar('Gagal menambahkan pengingat: ${e.toString()}', Colors.red);
      }
    } else {
      _showSnackBar('Harap isi semua informasi pengingat!', Colors.orange);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Target Keuangan', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF293239),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionTitle('Tetapkan Target Tabungan'),
            _buildTargetForm(),
            const SizedBox(height: 30),
            _buildSectionTitle('Atur Pengingat Transaksi'),
            _buildReminderField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 20)),
    );
  }

  Widget _buildTargetForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Masukkan jumlah target'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap isi target';
                  }
                  // Perbaiki validasi untuk memeriksa angka yang valid
                  final amount = value.replaceAll('Rp ', '').replaceAll('.', '').replaceAll(',', '.').trim();
                  if (double.tryParse(amount) == null) {
                    return 'Harap masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildSubmitButton('Tambahkan Target', _addTarget),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderField() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _transactionTypeController,
              decoration: _inputDecoration('Jenis Transaksi (misal: Biaya Wifi)'),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _reminderAmountController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('Nominal Pengingat'),
            ),
            const SizedBox(height: 15),
            TextField(
              readOnly: true,
              decoration: _inputDecoration('Tanggal Pembayaran: ${_selectedDate != null ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}" : "Pilih Tanggal"}'),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 15),
            _buildSubmitButton('Tambahkan Pengingat', _addReminder),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      border: OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFFE3ECED),
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF293239),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: GoogleFonts.raleway(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}