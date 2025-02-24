import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTransactionPage extends StatefulWidget {
  final void Function(String type, double amount, String description) onTransactionAdded;

  const AddTransactionPage({super.key, required this.onTransactionAdded});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final MoneyMaskedTextController _amountController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'Rp ',
    precision: 0,
  );

  String? _selectedType;
  String? _selectedDescription;
  bool _isCustomDescription = false;
  final TextEditingController _customDescriptionController = TextEditingController();
  final List<String> _descriptions = ['Makan', 'Gaji', 'Transport', 'Uang Semester', 'Shopping', 'Lainnya'];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Transaksi', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff0D6EFD),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildTitle('Jenis Transaksi'),
                _buildTransactionTypeDropdown(),
                const SizedBox(height: 15),
                _buildTitle('Jumlah'),
                _buildAmountField(),
                const SizedBox(height: 15),
                _buildTitle('Deskripsi'),
                _buildDescriptionDropdown(),
                if (_isCustomDescription) _buildCustomDescriptionField(),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTypeDropdown() {
    return DropdownButtonFormField(
      value: _selectedType,
      items: ['Income', 'Expense'].map((String type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedType = value.toString();
        });
      },
      decoration: _inputDecoration(),
      validator: (value) => value == null ? 'Pilih jenis transaksi' : null,
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(),
      validator: (value) {
        if (_amountController.numberValue <= 0) {
          return 'Masukkan angka yang valid';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionDropdown() {
    return DropdownButtonFormField(
      value: _selectedDescription,
      items: _descriptions.map((String desc) {
        return DropdownMenuItem(
          value: desc,
          child: Text(desc),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDescription = value.toString();
          _isCustomDescription = value == 'Lainnya';
        });
      },
      decoration: _inputDecoration(),
      validator: (value) => value == null ? 'Pilih deskripsi' : null,
    );
  }

  Widget _buildCustomDescriptionField() {
    return Column(
      children: [
        const SizedBox(height: 10),
        TextFormField(
          controller: _customDescriptionController,
          decoration: _inputDecoration().copyWith(hintText: 'Masukkan deskripsi lainnya'),
          validator: (value) {
            if (_isCustomDescription && (value == null || value.isEmpty)) {
              return 'Masukkan deskripsi';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff0D6EFD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _isLoading ? null : _submitTransaction,
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Tambah', style: GoogleFonts.raleway(fontSize: 18, color: Colors.white)),
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
    );
  }

  void _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String description = _isCustomDescription ? _customDescriptionController.text : _selectedDescription!;

      try {
        await FirebaseFirestore.instance.collection('transactions').add({
          'type': _selectedType,
          'amount': _amountController.numberValue,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
        });

        widget.onTransactionAdded(_selectedType!, _amountController.numberValue, description);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi Ditambahkan ke Firestore!'),
            duration: Duration(seconds: 2),
          ),
        );

        _resetForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan transaksi: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _amountController.updateValue(0);
    _customDescriptionController.clear();
    setState(() {
      _selectedType = null;
      _selectedDescription = null;
      _isCustomDescription = false;
    });
  }
}