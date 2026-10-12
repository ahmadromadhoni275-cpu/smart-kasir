import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core/services/return_service.dart';
import 'models/return_model.dart';
import 'tema.dart';

class HalamanFormRetur extends StatefulWidget {
  final int transactionId;
  final String invoiceNumber;

  const HalamanFormRetur({super.key, required this.transactionId, required this.invoiceNumber});

  @override
  State<HalamanFormRetur> createState() => _HalamanFormReturState();
}

class _HalamanFormReturState extends State<HalamanFormRetur> {
  final ReturnService _service = ReturnService();
  final TextEditingController _reasonCtrl = TextEditingController();
  
  List<ReturnItem> _returnableItems = [];
  Map<int, int> _selectedItems = {}; // {transactionItemId : qtyToReturn}
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _refundMethod = 'CASH';

  @override
  void initState() {
    super.initState();
    _fetchReturnableItems();
  }

  Future<void> _fetchReturnableItems() async {
    try {
      final items = await _service.getReturnableItems(widget.transactionId);
      setState(() {
        _returnableItems = items;
        _isLoading = false;
      });
    } catch (e) {
      _showNotif(e.toString(), Colors.red);
      Navigator.pop(context);
    }
  }

  double get _totalRefund {
    double total = 0;
    for (var item in _returnableItems) {
      if (_selectedItems.containsKey(item.transactionItemId)) {
        total += item.price * _selectedItems[item.transactionItemId]!;
      }
    }
    return total;
  }

  Future<void> _submitReturn() async {
    if (_selectedItems.isEmpty) {
      _showNotif('Pilih minimal satu barang', Colors.orange);
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _showNotif('Alasan retur wajib diisi', Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      List<Map<String, dynamic>> itemsPayload = [];
      _selectedItems.forEach((itemId, qty) {
        itemsPayload.add({'transaction_item_id': itemId, 'quantity': qty});
      });

      final payload = {
        'transaction_id': widget.transactionId,
        'reason': _reasonCtrl.text.trim(),
        'refund_method': _refundMethod,
        'items': itemsPayload
      };

      final result = await _service.createReturn(payload);
      _showNotif('Retur berhasil (${result['return_number']})', AppColors.primaryEmerald);
      Navigator.pop(context, true); // Kembali dengan indikator sukses
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), Colors.red);
      setState(() => _isSubmitting = false);
    }
  }

  String _formatCurrency(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);

  void _showNotif(String pesan, Color warna) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan), backgroundColor: warna, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengajuan Retur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.primaryEmerald, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Invoice: ${widget.invoiceNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Pilih Barang Retur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ..._returnableItems.map((item) {
                bool isSelected = _selectedItems.containsKey(item.transactionItemId);
                int qty = _selectedItems[item.transactionItemId] ?? 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppColors.primaryEmerald : Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: AppColors.primaryEmerald,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedItems[item.transactionItemId] = 1;
                              } else {
                                _selectedItems.remove(item.transactionItemId);
                              }
                            });
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${_formatCurrency(item.price)} / unit', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('Maks. Retur: ${item.returnableQuantity}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => setState(() { if (qty > 1) _selectedItems[item.transactionItemId] = qty - 1; else _selectedItems.remove(item.transactionItemId); })),
                              Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryEmerald), onPressed: () => setState(() { if (qty < item.returnableQuantity) _selectedItems[item.transactionItemId] = qty + 1; else _showNotif('Batas maksimal retur', Colors.orange); })),
                            ],
                          )
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              TextField(
                controller: _reasonCtrl,
                decoration: InputDecoration(labelText: 'Alasan Retur', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _refundMethod,
                decoration: InputDecoration(labelText: 'Metode Pengembalian Uang', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: ['CASH', 'TRANSFER', 'EWALLET'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _refundMethod = val!),
              ),
              const SizedBox(height: 100), // Spasi bawah
            ],
          ),
      bottomSheet: _isLoading ? null : Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Pengembalian', style: TextStyle(color: Colors.grey)), Text(_formatCurrency(_totalRefund), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red))]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isSubmitting ? null : _submitReturn,
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text('Proses Retur (${_selectedItems.length} Item)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
