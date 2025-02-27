import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TargetPage extends StatefulWidget {
  const TargetPage({super.key});

  @override
  _TargetPageState createState() => _TargetPageState();
}

class _TargetPageState extends State<TargetPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _reminderController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addTarget() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      try {
        await FirebaseFirestore.instance.collection('targets').add({
          'userId': user!.uid,
          'targetAmount': double.parse(_targetController.text),
          'progress': 0,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target keuangan ditambahkan!'), backgroundColor: Colors.green),
        );
        _targetController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan target: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addReminder() async {
    if (_reminderController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      try {
        await FirebaseFirestore.instance.collection('reminders').add({
          'userId': user!.uid,
          'reminderText': _reminderController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengingat transaksi ditambahkan!'), backgroundColor: Colors.blue),
        );
        _reminderController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan pengingat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Target Keuangan', style: GoogleFonts.raleway(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF293239),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTitle('Tetapkan Target Tabungan'),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration().copyWith(hintText: 'Masukkan jumlah target'),
                    validator: (value) => (value == null || value.isEmpty) ? 'Harap isi target' : null,
                  ),
                  const SizedBox(height: 15),
                  _buildSubmitButton('Tambahkan Target', _addTarget),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildTitle('Atur Pengingat Transaksi'),
            TextField(
              controller: _reminderController,
              decoration: _inputDecoration().copyWith(hintText: 'Tulis pengingat transaksi...'),
            ),
            const SizedBox(height: 15),
            _buildSubmitButton('Tambahkan Pengingat', _addReminder),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
