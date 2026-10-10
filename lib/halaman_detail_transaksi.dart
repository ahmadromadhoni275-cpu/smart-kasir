import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'tema.dart';
import 'services/api_service.dart';
import 'halaman_retur.dart';
import 'halaman_struk.dart'; // Untuk Preview Cetak

class HalamanDetailTransaksi extends StatefulWidget {
  final int transactionId;
  const HalamanDetailTransaksi({super.key, required this.transactionId});

  @override
  State<HalamanDetailTransaksi> createState() => _HalamanDetailTransaksiState();
}

class _HalamanDetailTransaksiState extends State<HalamanDetailTransaksi> {
  bool _isLoading = true;
  Map<String, dynamic>? _trx;
  List<dynamic> _items = [];
  Map<String, dynamic>? _payment;

  @override
  void initState() {
    super.initState();
    _muatDetail();
  }

  Future<void> _muatDetail() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('transactions/${widget.transactionId}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _trx = data['transaction'];
          _items = data['items'];
          _payment = data['payment'];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);
  String _formatTgl(String tgl) => DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(DateTime.parse(tgl).toLocal());

  void _batalkanTransaksi() {
    TextEditingController alasanCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Transaksi?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_trx!['invoice_number'], style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_formatRupiah(double.parse(_trx!['grand_total']))),
            const SizedBox(height: 16),
            TextField(controller: alasanCtrl, decoration: const InputDecoration(labelText: 'Alasan Pembatalan', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tidak')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final res = await ApiService.post('transactions/${widget.transactionId}/cancel', {'reason': alasanCtrl.text});
              if (res.statusCode == 200) {
                _muatDetail(); // Refresh data menjadi CANCELED
              }
              setState(() => _isLoading = false);
            },
            child: const Text('Batalkan', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_trx == null) return const Scaffold(body: Center(child: Text('Data tidak ditemukan')));

    bool isCanceled = _trx!['transaction_status'] == 'CANCELED';
    bool enableTable = _trx!['enable_table_number'] == '1';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, iconTheme: const IconThemeData(color: AppColors.navyActive), elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_trx!['invoice_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: isCanceled ? AppColors.error : AppColors.greenAccent, borderRadius: BorderRadius.circular(8)),
                        child: Text(isCanceled ? 'CANCELED' : _trx!['payment_status'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_formatTgl(_trx!['created_at']), style: const TextStyle(color: AppColors.textSecondary)),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kasir:'), Text(_trx!['cashier_name'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Shift:'), Text(_trx!['shift_id'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  if (enableTable && _trx!['table_id'] != null) ...[
                    const Divider(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('No. Meja:'), Text(_trx!['table_id'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryEmerald))]),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. ITEMS
            const Text('  ITEM PESANAN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: _items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (item['order_type'] != null)
                                Text(item['order_type'].toString().replaceAll('_', ' '), style: const TextStyle(fontSize: 10, color: AppColors.primaryEmerald, fontWeight: FontWeight.bold)),
                              if (item['note'] != null && item['note'] != '')
                                Text('Catatan: ${item['note']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${item['quantity']} × ${_formatRupiah(double.parse(item['price']))}', style: const TextStyle(fontSize: 12)),
                            Text(_formatRupiah(double.parse(item['subtotal'])), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // 3. PEMBAYARAN & SUMMARY
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text(_formatRupiah(double.parse(_trx!['subtotal'])))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon'), Text(_formatRupiah(double.parse(_trx!['discount'])))]),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(_formatRupiah(double.parse(_trx!['grand_total'])), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navyActive))]),
                  
                  if (_payment != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        children: [
                          const Text('INFORMASI PEMBAYARAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Metode'), Text(_payment!['method'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                          if (_payment!['method'] == 'CASH') ...[
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Dibayar'), Text(_formatRupiah(double.parse(_payment!['amount'])))]),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold)), Text(_formatRupiah(double.parse(_payment!['amount']) - double.parse(_trx!['grand_total'])), style: const TextStyle(fontWeight: FontWeight.bold))]),
                          ] else ...[
                            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Status'), Text('LUNAS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.greenAccent))]),
                          ]
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. TOMBOL AKSI
            if (!isCanceled) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () {
                        // TODO: Buka HalamanStruk untuk Preview / Cetak Bluetooth
                      }, 
                      icon: const Icon(Icons.print, color: AppColors.navyActive), label: const Text('CETAK', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold))
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        // Buka Halaman Retur yang dibuat di chat sebelumnya
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanRetur(transactionId: widget.transactionId, invoiceNumber: _trx!['invoice_number'])));
                        if (result == true) _muatDetail(); // Refresh jika retur sukses
                      }, 
                      icon: const Icon(Icons.keyboard_return, color: Colors.white), label: const Text('RETUR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _batalkanTransaksi,
                  child: const Text('❌ BATALKAN TRANSAKSI', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
