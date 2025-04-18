import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'history_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  double? _convertedResult;

  final List<String> _currencies = ['USD', 'IDR', 'EUR', 'JPY', 'GBP'];

  Future<void> convertCurrency() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah yang valid')),
      );
      return;
    }

    final url =
        'https://v6.exchangerate-api.com/v6/211bbe73a50a4a028bc4042a/latest/$_fromCurrency';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['result'] == 'success') {
        final rate = data['conversion_rates'][_toCurrency];
        if (rate != null) {
          setState(() {
            _convertedResult = amount * rate;
            _resultController.text =
                _convertedResult!.toStringAsFixed(2) + ' $_toCurrency';
          });
        } else {
          throw Exception('Rate tidak ditemukan');
        }
      } else {
        throw Exception('Terjadi kesalahan saat memproses data');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> saveConversion() async {
    if (_convertedResult == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    await FirebaseFirestore.instance.collection('conversion_history').add({
      'amount': amount,
      'from': _fromCurrency,
      'to': _toCurrency,
      'result': _convertedResult,
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hasil konversi disimpan ke history')),
    );
  }

  Widget _buildDropdown(String value, void Function(String?) onChanged) {
    return DropdownButton<String>(
      value: value,
      borderRadius: BorderRadius.circular(12),
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      items: _currencies
          .map((currency) => DropdownMenuItem(
                value: currency,
                child: Text(currency),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6CBA7C); // Soft green
    const bgColor = Color(0xFFF4F4F4);
    const cardColor = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Convert Mata Uang'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: cardColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah',
                    filled: true,
                    fillColor: bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(_fromCurrency, (value) {
                        setState(() {
                          _fromCurrency = value!;
                        });
                      }),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.compare_arrows),
                    ),
                    Expanded(
                      child: _buildDropdown(_toCurrency, (value) {
                        setState(() {
                          _toCurrency = value!;
                        });
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: convertCurrency,
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Konversi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  readOnly: true,
                  controller: _resultController,
                  decoration: InputDecoration(
                    labelText: 'Hasil Konversi',
                    filled: true,
                    fillColor: bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: saveConversion,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Simpan ke History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Convert',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            );
          }
        },
      ),
    );
  }
}
