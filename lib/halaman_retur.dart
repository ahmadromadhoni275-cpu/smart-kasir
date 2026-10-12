import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'tema.dart';
import 'core/services/return_service.dart'; // <-- Import Service
import 'models/return_model.dart';         // <-- Import Model

class HalamanRetur extends StatefulWidget {
  final int transactionId;
  final String invoiceNumber;

  const HalamanRetur({super.key, required this.transactionId, required this.invoiceNumber});

  @override
  State<HalamanRetur> createState() => _HalamanReturState();
}

class _HalamanReturState extends State<HalamanRetur> {
  final ReturnService _returnService = ReturnService(); // Inisialisasi Service
  
  bool _isLoading = true;
  bool _isProcessing = false;
  
  // Menggunakan Model ReturnItem, bukan Map dynamic lagi
  List<ReturnItem> _returnableItems = [];
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
      // Memanggil API melalui Service yang sudah rapi
      final items = await _returnService.getReturnableItems(widget.transactionId);
      setState(() {
        _returnableItems = items;
        for (var item in _returnableItems) {
          _selectedQty[item.transactionItemId] = 0; // Default retur = 0
        }
      });
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);
  
  void _showNotif(String pesan, Color warna) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: warna));

  double get _totalRefund {
    double total = 0;
    for (var item in _returnableItems) {
      int itemId = item.transactionItemId;
      int qty = _selectedQty[itemId] ?? 0;
      if (qty > 0) {
        total += (item.price * qty);
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
    for (var item in _returnableItems) {
      int qty = _selectedQty[item.transactionItemId] ?? 0;
      if (qty > 0) {
        itemsPayload.add({
          'transaction_item_id': item.transactionItemId,
          'quantity': qty,
          // Kondisi barang dikembalikan sebagai GOOD secara default agar stok kembali
          'condition': 'GOOD' 
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

      // Mengirim data melalui Service
      final result = await _returnService.createReturn(payload);
      
      Navigator.pop(context, true); // Kembali ke list & refresh
      _showNotif('Retur berhasil (No: ${result['return_number']})', AppColors.greenAccent);
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Form Pengajuan Retur', style: TextStyle(color: AppColors.navyActive, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Invoice: ${widget.invoiceNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                  itemCount: _returnableItems.length,
                  itemBuilder: (ctx, i) {
                    var item = _returnableItems[i];
                    int itemId = item.transactionItemId;
                    int maxQty = item.returnableQuantity;
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
                                    Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Harga Unit: ${_formatRupiah(item.price)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text('Tersedia untuk diretur: $maxQty item', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
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
                child: SafeArea(
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
                          const Text('Total Pengembalian Dana', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
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
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                              : const Text('PROSES RETUR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
    );
  }
}
