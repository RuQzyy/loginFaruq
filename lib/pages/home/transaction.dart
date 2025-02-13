import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTransactionPage extends StatefulWidget {
  final Function(String, double, String) onTransactionAdded;

  const AddTransactionPage({super.key, required this.onTransactionAdded});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'Income';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Transaksi',
            style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
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
                // Jenis Transaksi
                Text('Jenis Transaksi', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                DropdownButtonFormField(
                  value: _selectedType,
                  items: ['Income', 'Expense'].map((String type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value.toString();
                    });
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),

                // Jumlah
                Text('Jumlah', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan jumlah';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Deskripsi
                Text('Deskripsi', style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan deskripsi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Tombol Tambah
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0D6EFD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        double amount = double.parse(_amountController.text);
                        String description = _descriptionController.text;

                        widget.onTransactionAdded(_selectedType, amount, description);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaksi Ditambahkan!')),
                        );

                        Navigator.pop(context);
                      }
                    },
                    child: Text('Tambah', style: GoogleFonts.raleway(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
