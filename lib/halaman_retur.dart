import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'tema.dart';
import 'services/api_service.dart';

class HalamanRetur extends StatefulWidget {
  final int transactionId;
  final String invoiceNumber;

  const HalamanRetur({super.key, required this.transactionId, required this.invoiceNumber});

  @override
  State<HalamanRetur> createState() => _HalamanReturState();
}

class _HalamanReturState extends State<HalamanRetur> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<dynamic> _items = [];
  Map<int, int> _selectedQty = {}; // Menyimpan {transaction_item_id: qty_diretur}

  String _refundMethod = 'CASH';
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    try {
      final response = await ApiService.get('transactions/${widget.transactionId}/returnable-items');
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _items = data['items'];
          for (var item in _items) {
            _selectedQty[item['transaction_item_id']] = 0; // Default retur = 0
          }
        });
      }
    } catch (e) {
      _showNotif('Gagal memuat data retur', AppColors.error);
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);
  void _showNotif(String pesan, Color warna) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan), backgroundColor: warna));

  double get _totalRefund {
    double total = 0;
    for (var item in _items) {
      int itemId = item['transaction_item_id'];
      int qty = _selectedQty[itemId] ?? 0;
      if (qty > 0) {
        double price = double.parse(item['price'].toString());
        total += (price * qty);
      }
    }
    return total;
  }

  void _prosesRetur() async {
    if (_totalRefund <= 0) {
      _showNotif('Pilih minimal 1 item untuk diretur', AppColors.error);
      return;
    }
    if (_reasonCtrl.text.isEmpty) {
      _showNotif('Alasan retur wajib diisi', AppColors.error);
      return;
    }

    setState(() => _isProcessing = true);

    List<Map<String, dynamic>> itemsPayload = [];
    for (var item in _items) {
      int qty = _selectedQty[item['transaction_item_id']] ?? 0;
      if (qty > 0) {
        itemsPayload.add({
          'transaction_item_id': item['transaction_item_id'],
          'quantity': qty,
          'reason': _reasonCtrl.text
        });
      }
    }

    try {
      final payload = {
        'transaction_id': widget.transactionId,
        'reason': _reasonCtrl.text,
        'refund_method': _refundMethod,
        'items': itemsPayload
      };

      final response = await ApiService.post('returns', payload);
      final resData = json.decode(response.body);

      if (response.statusCode == 201) {
        Navigator.pop(context, true); // Kembali ke list & refresh
        _showNotif('Retur berhasil (No: ${resData['data']['return_number']})', AppColors.greenAccent);
      } else {
        _showNotif(resData['message'] ?? 'Gagal memproses retur', AppColors.error);
      }
    } catch (e) {
      _showNotif('Terjadi kesalahan jaringan', AppColors.error);
    }
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Retur Transaksi', style: TextStyle(color: AppColors.navyActive, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.invoiceNumber, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 1,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) {
                    var item = _items[i];
                    int itemId = item['transaction_item_id'];
                    int maxQty = item['returnable_quantity'];
                    int curQty = _selectedQty[itemId] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: curQty > 0 ? AppColors.primaryEmerald : AppColors.border)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(curQty > 0 ? Icons.check_box : Icons.check_box_outline_blank, color: curQty > 0 ? AppColors.primaryEmerald : AppColors.textSecondary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Terjual: ${item['sold_quantity']} | Diretur sblmnya: ${item['returned_quantity']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text('Tersedia untuk retur: $maxQty', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                              ],
                            ),
                          ),
                          
                          // Qty Control
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                                onPressed: () => setState(() { if (curQty > 0) _selectedQty[itemId] = curQty - 1; }),
                              ),
                              Text('$curQty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryEmerald),
                                onPressed: () => setState(() { if (curQty < maxQty) _selectedQty[itemId] = curQty + 1; }),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Panel Form & Konfirmasi
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _reasonCtrl,
                      decoration: InputDecoration(labelText: 'Alasan Retur', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _refundMethod,
                      decoration: InputDecoration(labelText: 'Metode Refund', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                      items: ['CASH', 'QRIS', 'TRANSFER'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (val) => setState(() => _refundMethod = val!),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Refund', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        Text(_formatRupiah(_totalRefund), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.error)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _isProcessing ? null : _prosesRetur,
                        child: _isProcessing 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('PROSES RETUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
    );
  }
}
