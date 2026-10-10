import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'tema.dart';
import 'services/api_service.dart';

class HalamanDetailRetur extends StatefulWidget {
  final int returnId;
  const HalamanDetailRetur({super.key, required this.returnId});

  @override
  State<HalamanDetailRetur> createState() => _HalamanDetailReturState();
}

class _HalamanDetailReturState extends State<HalamanDetailRetur> {
  bool _isLoading = true;
  Map<String, dynamic>? _ret;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _muatDetail();
  }

  Future<void> _muatDetail() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('returns/${widget.returnId}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _ret = data['return'];
          _items = data['items'];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);
  String _formatTgl(String tgl) => DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(DateTime.parse(tgl).toLocal());

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_ret == null) return const Scaffold(body: Center(child: Text('Data tidak ditemukan')));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Retur', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, iconTheme: const IconThemeData(color: AppColors.navyActive), elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INFO RETUR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_ret!['return_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.navyActive.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('● ${_ret!['status']}', style: const TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_formatTgl(_ret!['created_at']), style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. INFO TRANSAKSI ASAL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TRANSAKSI ASAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Invoice'), Text(_ret!['invoice_number'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kasir'), Text(_ret!['cashier_name'])]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Shift'), Text(_ret!['shift_id'] ?? '-')]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. ITEM RETUR
            const Text('  ITEM RETUR', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: _items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(_formatRupiah(double.parse(item['amount'])), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('Qty retur: ${item['quantity']} × ${_formatRupiah(double.parse(item['price']))}', style: const TextStyle(fontSize: 12)),
                        if (item['reason'] != null)
                          Text('Alasan: ${item['reason']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.error)),
                        const Divider(),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // 4. REFUND INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL REFUND', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(_formatRupiah(double.parse(_ret!['total_amount'])), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.error)),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Metode'), Text(_ret!['refund_method'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Status Refund'), 
                    Text(
                      _ret!['refund_status'], 
                      style: TextStyle(fontWeight: FontWeight.bold, color: _ret!['refund_status'] == 'COMPLETED' ? AppColors.greenAccent : Colors.orange)
                    )
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. TOMBOL CETAK BUKTI
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  // TODO: Panggil fungsi Cetak Struk Bukti Retur
                }, 
                icon: const Icon(Icons.print, color: AppColors.navyActive), 
                label: const Text('CETAK BUKTI RETUR', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold))
              ),
            )
          ],
        ),
      ),
    );
  }
}
