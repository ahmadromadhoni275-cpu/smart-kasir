import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'tema.dart'; // Import tema eksklusif

class HalamanBeranda extends StatefulWidget {
  const HalamanBeranda({super.key});

  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

class _HalamanBerandaState extends State<HalamanBeranda> {
  final String domainUrl = 'https://smartkasir.shop';
  bool isLoading = true;
  String namaAdmin = 'Admin';
  String tanggalHariIni = '';

  Map<String, dynamic> metrik = {
    'omzet': 0,
    'total_transaksi': 0,
    'produk_terjual': 0,
    'laba_bersih': 0
  };
  
  List grafikData = [];
  int grafikMax = 1;
  List transaksiTerbaru = [];
  List stokMenipis = [];
  List produkTerlaris = [];

  @override
  void initState() {
    super.initState();
    tanggalHariIni = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());
    _ambilDataDashboard();
  }

  Future<void> _ambilDataDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    int tokoId = prefs.getInt('toko_id') ?? 1;
    setState(() => namaAdmin = prefs.getString('username') ?? 'Admin');

    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/dashboard?toko_id=$tokoId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body)['data'];
        setState(() {
          metrik = res['metrik'];
          grafikData = res['grafik']['data_harian'];
          grafikMax = res['grafik']['nilai_tertinggi'] == 0 ? 1 : res['grafik']['nilai_tertinggi'];
          transaksiTerbaru = res['transaksi_terbaru'];
          stokMenipis = res['stok_menipis'];
          produkTerlaris = res['produk_terlaris'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat dashboard: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatRupiah(int angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : RefreshIndicator(
              onRefresh: _ambilDataDashboard,
              color: AppColors.teal,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER GREETING ---
                    Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    const SizedBox(height: 5),
                    Text('Selamat datang kembali, $namaAdmin 👋', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.smartBlue)),
                    Text(tanggalHariIni, style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                    const SizedBox(height: 25),

                    // --- 4 KOTAK METRIK UTAMA ---
                    Row(
                      children: [
                        Expanded(child: _buildMetrikCard('Total Omzet', _formatRupiah(metrik['omzet']), Icons.account_balance_wallet, AppColors.premiumGold)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildMetrikCard('Total Transaksi', '${metrik['total_transaksi']}', Icons.receipt_long, AppColors.smartBlue)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildMetrikCard('Produk Terjual', '${metrik['produk_terjual']}', Icons.inventory, AppColors.emerald)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildMetrikCard('Laba Bersih', _formatRupiah(metrik['laba_bersih']), Icons.trending_up, AppColors.teal)),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // --- GRAFIK PENJUALAN 7 HARI ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Penjualan 7 Hari Terakhir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                          const SizedBox(height: 25),
                          SizedBox(
                            height: 150,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: grafikData.map((data) {
                                double tinggiTiang = (data['total'] / grafikMax) * 120; // 120 adalah tinggi max container visual
                                if (data['total'] > 0 && tinggiTiang < 10) tinggiTiang = 10; // Minimal tinggi jika ada penjualan
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 15,
                                      height: tinggiTiang,
                                      decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(4)),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(data['hari_singkat'], style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
                                  ],
                                );
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // --- KOLOM DATA TERBARU ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kiri: Transaksi Terbaru
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Transaksi Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText)),
                                const SizedBox(height: 15),
                                ...transaksiTerbaru.map((trx) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('TRX-${trx['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.darkText)),
                                            Text(DateFormat('dd MMM - HH:mm').format(DateTime.parse(trx['tanggal'])), style: const TextStyle(fontSize: 9, color: AppColors.slateGray)),
                                          ],
                                        ),
                                        Text(_formatRupiah(int.parse(trx['total_harga'].toString())), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.smartBlue)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Kanan: Stok Hampir Habis & Terlaris
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Stok Hampir Habis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText)),
                                    const SizedBox(height: 15),
                                    ...stokMenipis.map((stok) {
                                      int jml = int.parse(stok['stok'].toString());
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: Text(stok['nama'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkText))),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: jml == 0 ? AppColors.red.withOpacity(0.1) : AppColors.premiumGold.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                              child: Text('$jml pcs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: jml == 0 ? AppColors.red : AppColors.premiumGold)),
                                            )
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetrikCard(String judul, String nilai, IconData ikon, Color warnaIkon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(judul, style: const TextStyle(fontSize: 11, color: AppColors.slateGray))),
              Icon(ikon, color: warnaIkon, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(nilai, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
        ],
      ),
    );
  }
}
