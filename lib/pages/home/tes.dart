import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class AddTransactionPage extends StatefulWidget {
  final Function(String, double, String) onTransactionAdded;

  const AddTransactionPage({super.key, required this.onTransactionAdded});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  final MoneyMaskedTextController _amountController =
      MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'Rp ',
    precision: 0,
  );

  String? _selectedType;
  String? _selectedDescription;
  bool _isCustomDescription = false;
  final TextEditingController _customDescriptionController =
      TextEditingController();

  final List<String> _descriptions = [
    'Makan',
    'Gaji',
    'Transport',
    'Uang Semester',
    'Shopping',
    'Lainnya'
  ];

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
                _buildTitle('Jenis Transaksi'),
                DropdownButtonFormField(
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
                  validator: (value) =>
                      value == null ? 'Pilih jenis transaksi' : null,
                ),
                const SizedBox(height: 15),

                _buildTitle('Jumlah'),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(),
                  validator: (value) {
                    if (_amountController.numberValue <= 0) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                _buildTitle('Deskripsi'),
                DropdownButtonFormField(
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
                  validator: (value) =>
                      value == null ? 'Pilih deskripsi' : null,
                ),
                if (_isCustomDescription) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customDescriptionController,
                    decoration: _inputDecoration().copyWith(
                        hintText: 'Masukkan deskripsi lainnya'),
                    validator: (value) {
                      if (_isCustomDescription && (value == null || value.isEmpty)) {
                        return 'Masukkan deskripsi';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0D6EFD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final String description = _isCustomDescription
                            ? _customDescriptionController.text
                            : _selectedDescription!;

                        widget.onTransactionAdded(
                          _selectedType!,
                          _amountController.numberValue,
                          description,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transaksi Ditambahkan!'),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        Future.delayed(const Duration(seconds: 1), () {
                          Navigator.pop(context);
                        });

                        _formKey.currentState!.reset();
                        _amountController.updateValue(0);
                        setState(() {
                          _selectedType = null;
                          _selectedDescription = null;
                          _isCustomDescription = false;
                        });
                      }
                    },
                    child: Text('Tambah',
                        style: GoogleFonts.raleway(
                            fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
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
    return const InputDecoration(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
