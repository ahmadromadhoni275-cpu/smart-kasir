import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'halaman_struk.dart';

class HalamanRiwayat extends StatefulWidget {
  const HalamanRiwayat({super.key});

  @override
  State<HalamanRiwayat> createState() => _HalamanRiwayatState();
}

class _HalamanRiwayatState extends State<HalamanRiwayat> {
  // URL telah disesuaikan ke hosting Anda
  final String baseUrl = 'https://smartkasir.shop/api';
  bool isLoading = true;
  List riwayatData = [];

  // ==========================================
  // VARIABEL FILTER BULAN & TAHUN
  // ==========================================
  int selectedBulan = DateTime.now().month;
  int selectedTahun = DateTime.now().year;

  final List<Map<String, dynamic>> listBulan = [
    {'id': 1, 'nama': 'Januari'},
    {'id': 2, 'nama': 'Februari'},
    {'id': 3, 'nama': 'Maret'},
    {'id': 4, 'nama': 'April'},
    {'id': 5, 'nama': 'Mei'},
    {'id': 6, 'nama': 'Juni'},
    {'id': 7, 'nama': 'Juli'},
    {'id': 8, 'nama': 'Agustus'},
    {'id': 9, 'nama': 'September'},
    {'id': 10, 'nama': 'Oktober'},
    {'id': 11, 'nama': 'November'},
    {'id': 12, 'nama': 'Desember'},
  ];

  // Membuat daftar tahun dari 2023 hingga 2 tahun ke depan dari tahun ini
  List<int> get listTahun {
    int tahunSekarang = DateTime.now().year;
    List<int> tahun = [];
    // Contoh: Mulai dari tahun 2023 sampai (tahun ini + 2)
    for (int i = 2023; i <= tahunSekarang + 2; i++) {
      tahun.add(i);
    }
    return tahun;
  }
  // ==========================================

  @override
  void initState() {
    super.initState();
    _ambilRiwayatTransaksi();
  }

  Future<void> _ambilRiwayatTransaksi() async {
    final prefs = await SharedPreferences.getInstance();
    int idTokoAktif = prefs.getInt('toko_id') ?? 1;

    try {
      final url = Uri.parse('$baseUrl/riwayatTransaksi/$idTokoAktif');
      final response =
          await http.get(url, headers: {'ngrok-skip-browser-warning': 'true'});

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() {
          riwayatData = res['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error tarik riwayat: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatRp(dynamic angka) {
    int nilai = int.tryParse(angka.toString()) ?? 0;
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(nilai);
  }

  @override
  Widget build(BuildContext context) {
    // ==============================================================
    // LOGIKA PENYARINGAN (FILTER) DATA SESUAI BULAN & TAHUN DIPILIH
    // ==============================================================
    List dataTersaring = riwayatData.where((trx) {
      if (trx['tanggal'] == null) return false;
      try {
        DateTime tglTransaksi = DateTime.parse(trx['tanggal'].toString());
        return tglTransaksi.month == selectedBulan &&
               tglTransaksi.year == selectedTahun;
      } catch (e) {
        return false;
      }
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Riwayat Transaksi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- BAGIAN HEADER FILTER (Seperti M-Banking) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 3)
                )
              ]
            ),
            child: Row(
              children: [
                // Dropdown Bulan
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedBulan,
                    decoration: InputDecoration(
                      labelText: 'Pilih Bulan',
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      prefixIcon: const Icon(Icons.calendar_month, color: Colors.blueAccent),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    items: listBulan.map((b) {
                      return DropdownMenuItem<int>(
                        value: b['id'],
                        child: Text(b['nama'], style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedBulan = val!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Dropdown Tahun
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedTahun,
                    decoration: InputDecoration(
                      labelText: 'Pilih Tahun',
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    items: listTahun.map((t) {
                      return DropdownMenuItem<int>(
                        value: t,
                        child: Text(t.toString(), style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedTahun = val!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // --- DAFTAR RIWAYAT TRANSAKSI ---
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : dataTersaring.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            const Text('Belum ada transaksi di bulan ini.',
                                style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _ambilRiwayatTransaksi,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(15),
                          itemCount: dataTersaring.length,
                          itemBuilder: (context, index) {
                            var trx = dataTersaring[index];

                            String noStruk = 'INV-${trx['id']}';
                            String tanggal = trx['tanggal']?.toString() ?? '-';
                            int total = int.tryParse(trx['total_harga']?.toString() ?? '0') ?? 0;
                            int ppn = int.tryParse(trx['ppn_nominal']?.toString() ?? '0') ?? 0;
                            int uangBayar = int.tryParse(trx['uang_bayar']?.toString() ?? '0') ?? 0;
                            int kembalian = int.tryParse(trx['kembalian']?.toString() ?? '0') ?? 0;
                            String metode = trx['metode_pembayaran']?.toString() ?? 'Tunai';
                            List items = trx['items'] ?? [];

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Ikon
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.blue[50],
                                      child: const Icon(Icons.receipt,
                                          color: Colors.blueAccent, size: 22),
                                    ),
                                    const SizedBox(width: 15),

                                    // Detail Struk
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(noStruk,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15)),
                                          const SizedBox(height: 4),
                                          Text(tanggal,
                                              style: const TextStyle(
                                                  fontSize: 12, color: Colors.grey)),
                                          Text('Metode: $metode',
                                              style: const TextStyle(
                                                  fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),

                                    // Harga & Tombol
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_formatRp(total),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                fontSize: 14)),
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () {
                                            int hitungSubtotal = 0;
                                            int hitungJasa = 0;

                                            // MAPPING ULANG DATA AGAR AMAN DITERIMA HALAMAN STRUK
                                            List<Map<String, dynamic>> keranjangCetak = [];

                                            for (var item in items) {
                                              int sub = int.tryParse(item['subtotal']?.toString() ?? '0') ?? 0;
                                              // Antisipasi jika API mereturn 'product_id' atau 'id'
                                              int idProd = int.tryParse(item['product_id']?.toString() ?? item['id']?.toString() ?? '0') ?? 0;

                                              if (idProd == 0) {
                                                hitungJasa += sub;
                                              } else {
                                                hitungSubtotal += sub;
                                              }

                                              // Pastikan keys sesuai dengan yang di-parsing oleh HalamanStruk
                                              keranjangCetak.add({
                                                'id': idProd,
                                                'nama': item['nama'] ?? item['product_name'] ?? 'Produk',
                                                'harga': int.tryParse(item['harga_satuan']?.toString() ?? item['harga']?.toString() ?? '0') ?? 0,
                                                'qty': int.tryParse(item['qty']?.toString() ?? '1') ?? 1,
                                                'subtotal': sub,
                                              });
                                            }

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => HalamanStruk(
                                                  keranjang: keranjangCetak,
                                                  totalBelanja: total,
                                                  subtotal: hitungSubtotal,
                                                  ppnNominal: ppn,
                                                  biayaJasa: hitungJasa,
                                                  uangDiterima: uangBayar,
                                                  uangKembalian: kembalian,
                                                  noStruk: noStruk,
                                                  tanggal: tanggal,
                                                  metodePembayaran: metode,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                                color: Colors.blue[50],
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            child: const Text('Cetak Ulang',
                                                style: TextStyle(
                                                    color: Colors.blueAccent,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12)),
                                          ),
                                        )
                                      ],
                                    ),
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
