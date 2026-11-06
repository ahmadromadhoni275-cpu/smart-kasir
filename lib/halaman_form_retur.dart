import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/return_service.dart';
import 'models/return_model.dart';
import 'tema.dart';
import 'core/services/return_service.dart';

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
      if (items.isEmpty) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tampilPopupCantik('Tidak Dapat Diretur', 'Seluruh barang pada transaksi ini sudah diretur atau tidak tersedia.', Icons.block, AppColors.error, onTutup: () => Navigator.pop(context));
        });
        return;
      }
      setState(() {
        _returnableItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tampilPopupCantik('Gagal Memuat', e.toString().replaceAll('Exception: ', ''), Icons.error_outline, AppColors.error, onTutup: () => Navigator.pop(context));
      });
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

  void _konfirmasiRetur() {
    if (_selectedItems.isEmpty) {
      _tampilPopupCantik('Pilih Barang', 'Anda harus memilih minimal satu barang untuk diretur.', Icons.warning_amber_rounded, AppColors.warning);
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _tampilPopupCantik('Alasan Kosong', 'Silakan isi alasan pengembalian barang terlebih dahulu.', Icons.warning_amber_rounded, AppColors.warning);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Retur', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        content: Text('Anda yakin ingin meretur ${_selectedItems.length} jenis barang dengan total pengembalian dana sebesar ${_formatCurrency(_totalRefund)}? Stok akan disesuaikan kembali.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              _submitReturn();
            },
            child: const Text('Ya, Proses Retur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  Future<void> _submitReturn() async {
    setState(() => _isSubmitting = true);
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.error)));

    try {
      List<dynamic> itemsPayload = [];
      _selectedItems.forEach((itemId, qty) {
        itemsPayload.add({
          'transaction_item_id': itemId, 
          'quantity': qty,
          'condition': 'GOOD' // Default kembali ke stok
        });
      });

      final payload = {
        'transaction_id': widget.transactionId,
        'reason': _reasonCtrl.text.trim(),
        'refund_method': _refundMethod,
        'items': itemsPayload
      };

      final result = await _service.createReturn(payload);
      
      Navigator.pop(context); // Tutup loading
      _tampilPopupCantik('Retur Berhasil', 'Pengajuan retur berhasil diproses dengan nomor ${result['return_number'] ?? '-'}', Icons.check_circle, AppColors.primaryEmerald, onTutup: () {
        Navigator.pop(context); // Tutup popup
        Navigator.pop(context, true); // Kembali ke list
      });
      
    } catch (e) {
      Navigator.pop(context); // Tutup loading
      _tampilPopupCantik('Retur Gagal', e.toString().replaceAll('Exception: ', ''), Icons.error, AppColors.error);
      setState(() => _isSubmitting = false);
    }
  }

  void _tampilPopupCantik(String judul, String pesan, IconData ikon, Color warna, {VoidCallback? onTutup}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: warna.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: warna.withOpacity(0.1), shape: BoxShape.circle), child: Icon(ikon, color: warna, size: 48)),
              const SizedBox(height: 20),
              Text(judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 12),
              Text(pesan, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: warna, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: onTutup ?? () => Navigator.pop(ctx),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengajuan Retur', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.assignment_return_outlined, color: AppColors.error)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Faktur Pembelian', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                Text(widget.invoiceNumber, style: const TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.w900, fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Pilih Barang Retur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyActive)),
                    const SizedBox(height: 12),
                    ..._returnableItems.map((item) {
                      bool isSelected = _selectedItems.containsKey(item.transactionItemId);
                      int qty = _selectedItems[item.transactionItemId] ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.primaryEmerald : Colors.transparent, width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: AppColors.primaryEmerald,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text('${_formatCurrency(item.price)} / unit', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    Text('Maksimal retur: ${item.returnableQuantity}', style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error), 
                                      onPressed: () => setState(() { 
                                        if (qty > 1) _selectedItems[item.transactionItemId] = qty - 1; 
                                        else _selectedItems.remove(item.transactionItemId); 
                                      })
                                    ),
                                    SizedBox(width: 24, child: Text('$qty', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryEmerald), 
                                      onPressed: () {
                                        setState(() { 
                                          if (qty < item.returnableQuantity) {
                                            _selectedItems[item.transactionItemId] = qty + 1; 
                                          } else {
                                            _tampilPopupCantik('Batas Maksimal', 'Anda tidak dapat meretur lebih dari jumlah yang dibeli.', Icons.info_outline, AppColors.smartBlue);
                                          }
                                        });
                                      }
                                    ),
                                  ],
                                )
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text('Detail Pengembalian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyActive)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Alasan Retur',
                        alignLabelWithHint: true,
                        filled: true, 
                        fillColor: Colors.white, 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryEmerald)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _refundMethod,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.navyActive),
                      decoration: InputDecoration(
                        labelText: 'Metode Pengembalian Uang', 
                        filled: true, 
                        fillColor: Colors.white, 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      items: ['CASH', 'TRANSFER', 'QRIS', 'EWALLET'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (val) => setState(() => _refundMethod = val!),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              
              // Bottom Panel
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -5))]
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          const Text('Total Refund', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)), 
                          Text(_formatCurrency(_totalRefund), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.error))
                        ]
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: _isSubmitting ? null : _konfirmasiRetur,
                          child: Text('Proses Retur (${_selectedItems.length} Item)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
