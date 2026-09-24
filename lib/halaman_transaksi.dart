import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'tema.dart'; // Import tema eksklusif

class HalamanTransaksi extends StatefulWidget {
  const HalamanTransaksi({super.key});

  @override
  State<HalamanTransaksi> createState() => _HalamanTransaksiState();
}

class _HalamanTransaksiState extends State<HalamanTransaksi> {
  final String domainUrl = 'https://smartkasir.shop';
  
  List riwayatTransaksi = [];
  bool isLoading = true;
  String _userRole = 'kasir';
  int _tokoId = 1;

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'kasir';
      _tokoId = prefs.getInt('toko_id') ?? 1;
    });
    await _ambilDataTransaksi();
  }

  Future<void> _ambilDataTransaksi() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/riwayatTransaksi/$_tokoId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() {
          riwayatTransaksi = res['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Gagal mengambil riwayat transaksi: $e");
      setState(() => isLoading = false);
    }
  }

  // ==========================================
  // FUNGSI MEMUNCULKAN DETAIL TRANSAKSI
  // ==========================================
  Future<void> _tampilkanDetailTransaksi(Map<String, dynamic> trx) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Format Tanggal
        DateTime tgl = DateTime.tryParse(trx['tanggal'] ?? '') ?? DateTime.now();
        String formatTgl = DateFormat('dd MMM yyyy • HH:mm').format(tgl);
        
        List items = trx['items'] ?? [];
        int total = int.tryParse(trx['total_harga']?.toString() ?? '0') ?? 0;
        int ppn = int.tryParse(trx['ppn_nominal']?.toString() ?? '0') ?? 0;
        int uangBayar = int.tryParse(trx['uang_bayar']?.toString() ?? '0') ?? 0;
        int kembalian = int.tryParse(trx['kembalian']?.toString() ?? '0') ?? 0;
        String tipePesanan = trx['tipe_pesanan'] == 'takeaway' ? 'Takeaway' : 'Dine In';
        String noMeja = trx['no_meja'] ?? '-';
        String pelanggan = trx['nama_pelanggan'] ?? 'Pelanggan Umum';

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.only(top: 15, bottom: 20),
          decoration: const BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 15),
              
              // Header Detail
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Detail Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text('TRX-${trx['id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.emerald, fontSize: 12)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Info Box (Meja, Pelanggan, Tipe Pesanan)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    _buildInfoRow('Tanggal', formatTgl),
                    const Divider(height: 15),
                    _buildInfoRow('Pelanggan', pelanggan),
                    const Divider(height: 15),
                    _buildInfoRow('Tipe Pesanan', '$tipePesanan ${noMeja != '-' ? '(Meja $noMeja)' : ''}'),
                    const Divider(height: 15),
                    _buildInfoRow('Metode Pembayaran', trx['metode_pembayaran']?.toString().toUpperCase() ?? 'TUNAI'),
                  ],
                ),
              ),
              
              const SizedBox(height: 15),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Rincian Barang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slateGray)),
              ),
              const SizedBox(height: 5),

              // List Barang
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    int qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
                    int subtotal = int.tryParse(item['subtotal']?.toString() ?? '0') ?? 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['nama'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText)),
                                const SizedBox(height: 4),
                                Text('$qty x ${_formatRupiah(subtotal ~/ qty)}', style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                              ],
                            ),
                          ),
                          Text(_formatRupiah(subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.smartBlue)),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Total & Pembayaran
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))]),
                child: Column(
                  children: [
                    if (ppn > 0) _buildSummaryRow('PPN Otomatis', _formatRupiah(ppn), isBold: false),
                    const SizedBox(height: 5),
                    _buildSummaryRow('Total Belanja', _formatRupiah(total), isBold: true, color: AppColors.emerald, size: 18),
                    const Divider(height: 20),
                    _buildSummaryRow('Uang Dibayar', _formatRupiah(uangBayar), isBold: false),
                    const SizedBox(height: 5),
                    _buildSummaryRow('Kembalian', _formatRupiah(kembalian), isBold: false, color: AppColors.red),
                    const SizedBox(height: 15),
                    
                    // Tombol Cetak Ulang
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          // Arahkan kembali ke halaman cetak struk dengan parameter trx
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.print, color: AppColors.white, size: 18),
                        label: const Text('Cetak Ulang Struk', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.slateGray, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText, fontSize: 13)),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color color = AppColors.darkText, double size = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? color : AppColors.slateGray, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: size - 2)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: size)),
      ],
    );
  }

  String _formatRupiah(int angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  // ==========================================
  // WIDGET UTAMA
  // ==========================================
  @override
  Widget build(BuildContext context) {
    bool isAdmin = _userRole == 'admin' || _userRole == 'superadmin';

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER HALAMAN
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            color: AppColors.lightGray,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaksi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    SizedBox(height: 4),
                    Text('Riwayat semua transaksi penjualan', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                  ],
                ),
                if (isAdmin)
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.smartBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),

          // 2. HEADER TABEL
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('ID Trans.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slateGray))),
                Expanded(flex: 3, child: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slateGray))),
                Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slateGray))),
                Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slateGray))),
              ],
            ),
          ),

          // 3. DAFTAR TRANSAKSI (Gaya Tabel)
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : riwayatTransaksi.isEmpty
                    ? const Center(child: Text("Belum ada riwayat transaksi.", style: TextStyle(color: AppColors.slateGray)))
                    : RefreshIndicator(
                        onRefresh: _ambilDataTransaksi,
                        color: AppColors.teal,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
                          itemCount: riwayatTransaksi.length,
                          itemBuilder: (context, index) {
                            var trx = riwayatTransaksi[index];
                            int totalHarga = int.tryParse(trx['total_harga']?.toString() ?? '0') ?? 0;
                            String status = trx['status']?.toString().toLowerCase() == 'closed' ? 'Selesai' : 'Selesai'; 
                            
                            DateTime tgl = DateTime.tryParse(trx['tanggal'] ?? '') ?? DateTime.now();
                            String formatTglLengkap = DateFormat('dd MMM yyyy • HH:mm').format(tgl);

                            return InkWell(
                              onTap: () => _tampilkanDetailTransaksi(trx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                                ),
                                child: Row(
                                  children: [
                                    // ID
                                    Expanded(
                                      flex: 2,
                                      child: Text('TRX-${trx['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.darkText)),
                                    ),
                                    // Tanggal & Pelanggan
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(formatTglLengkap, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                                          const SizedBox(height: 3),
                                          Text(trx['nama_pelanggan'] ?? 'Umum', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.smartBlue)),
                                        ],
                                      ),
                                    ),
                                    // Total
                                    Expanded(
                                      flex: 2,
                                      child: Text(_formatRupiah(totalHarga), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.darkText)),
                                    ),
                                    // Status Badge
                                    Expanded(
                                      flex: 2,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                          child: Text(status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emerald)),
                                        ),
                                      ),
                                    ),
                                    // Action Icon
                                    const Icon(Icons.more_vert, size: 16, color: AppColors.slateGray),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
