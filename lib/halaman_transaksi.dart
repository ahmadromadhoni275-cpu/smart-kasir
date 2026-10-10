import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'tema.dart';
import 'services/api_service.dart';
import 'halaman_detail_transaksi.dart';
import 'halaman_riwayat_retur.dart'; // Uncomment jika sudah buat

class HalamanTransaksi extends StatefulWidget {
  const HalamanTransaksi({super.key});

  @override
  State<HalamanTransaksi> createState() => _HalamanTransaksiState();
}

class _HalamanTransaksiState extends State<HalamanTransaksi> {
  bool _isLoading = true;
  List<dynamic> _transactions = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _muatTransaksi();
  }

  Future<void> _muatTransaksi() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('transactions?search=$_searchQuery');
      if (response.statusCode == 200) {
        setState(() {
          _transactions = json.decode(response.body)['data'];
        });
      }
    } catch (e) {
      debugPrint("Error loading transactions: $e");
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);
  String _formatTgl(String tgl) => DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(DateTime.parse(tgl).toLocal());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Daftar Transaksi', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        elevation: 1,
        actions: [
          TextButton.icon(
            onPressed: () {
              // Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanRiwayatRetur()));
            },
            icon: const Icon(Icons.history, color: AppColors.primaryEmerald),
            label: const Text('Riwayat Retur', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          // PENCARIAN & FILTER
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val);
                    _muatTransaksi();
                  },
                  decoration: InputDecoration(
                    hintText: '🔍 Cari invoice / nama produk / kasir...',
                    filled: true, fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(label: const Text('Hari Ini'), onPressed: (){}),
                      const SizedBox(width: 8),
                      ActionChip(label: const Text('Semua Bayar'), onPressed: (){}),
                      const SizedBox(width: 8),
                      ActionChip(label: const Text('Semua Status'), onPressed: (){}),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // LIST TRANSAKSI
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _transactions.isEmpty
                  ? const Center(child: Text('Tidak ada transaksi ditemukan.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length,
                      itemBuilder: (ctx, i) {
                        var trx = _transactions[i];
                        bool isPaid = trx['payment_status'] == 'PAID';
                        bool isCanceled = trx['transaction_status'] == 'CANCELED';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(trx['invoice_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCanceled ? AppColors.error.withOpacity(0.1) : (isPaid ? AppColors.greenAccent.withOpacity(0.1) : Colors.orange.withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Text(
                                    isCanceled ? 'CANCELED' : trx['payment_status'], 
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCanceled ? AppColors.error : (isPaid ? AppColors.greenAccent : Colors.orange))
                                  ),
                                )
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text('${_formatTgl(trx['created_at'])}', style: const TextStyle(fontSize: 12)),
                                Text('Kasir: ${trx['cashier_name']} • Shift: ${trx['shift_id'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total: ${_formatRupiah(double.parse(trx['grand_total']))}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                                    const Text('Lihat Detail →', style: TextStyle(color: AppColors.primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold))
                                  ],
                                )
                              ],
                            ),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanDetailTransaksi(transactionId: int.parse(trx['transaction_id'].toString()))))
                                  .then((_) => _muatTransaksi()); // Refresh saat kembali
                            },
                          ),
                        );
                      },
                    ),
          )
        ],
      ),
    );
  }
}
