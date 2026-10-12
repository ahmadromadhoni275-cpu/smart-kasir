import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core/services/return_service.dart';
import 'tema.dart';

class HalamanDetailRetur extends StatefulWidget {
  final int returnId;
  const HalamanDetailRetur({super.key, required this.returnId});

  @override
  State<HalamanDetailRetur> createState() => _HalamanDetailReturState();
}

class _HalamanDetailReturState extends State<HalamanDetailRetur> {
  final ReturnService _service = ReturnService();
  bool _isLoading = true;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _service.getReturnDetail(widget.returnId);
      setState(() {
        _detail = data;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      Navigator.pop(context);
    }
  }

  String _formatCurrency(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(backgroundColor: const Color(0xFF1E293B)), body: const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));
    }

    final retur = _detail!['return'];
    final items = _detail!['items'] as List;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Retur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(retur['return_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)), child: Text(retur['refund_status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700))),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Invoice Asal', style: TextStyle(color: Colors.grey)), Text(retur['invoice_number'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tanggal', style: TextStyle(color: Colors.grey)), Text(retur['created_at'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kasir', style: TextStyle(color: Colors.grey)), Text(retur['cashier_name'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Metode Refund', style: TextStyle(color: Colors.grey)), Text(retur['refund_method'], style: const TextStyle(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Alasan', style: TextStyle(color: Colors.grey)), Text(retur['reason'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Barang Dikembalikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...items.map((item) {
              double amount = double.tryParse(item['amount'].toString()) ?? 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${item['quantity']} item', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(_formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Refund', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_formatCurrency(double.tryParse(retur['total_amount'].toString()) ?? 0), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
