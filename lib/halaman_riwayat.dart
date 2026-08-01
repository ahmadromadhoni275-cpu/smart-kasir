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
  // URL telah disesuaikan ke hosting AnymHost Anda
  final String baseUrl = 'https://smartkasir.shop/api';
  
  bool isLoading = true;
  List riwayatData = [];

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Riwayat Transaksi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : riwayatData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text('Belum ada riwayat transaksi.',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _ambilRiwayatTransaksi,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: riwayatData.length,
                    itemBuilder: (context, index) {
                      var trx = riwayatData[index];

                      String noStruk = 'INV-${trx['id']}';
                      String tanggal = trx['tanggal']?.toString() ?? '-';
                      int total =
                          int.tryParse(trx['total_harga']?.toString() ?? '0') ??
                              0;
                      int ppn =
                          int.tryParse(trx['ppn_nominal']?.toString() ?? '0') ??
                              0;
                      int uangBayar =
                          int.tryParse(trx['uang_bayar']?.toString() ?? '0') ??
                              0;
                      int kembalian =
                          int.tryParse(trx['kembalian']?.toString() ?? '0') ??
                              0;
                      String metode =
                          trx['metode_pembayaran']?.toString() ?? 'Tunai';
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
                                      List<Map<String, dynamic>>
                                          keranjangCetak = [];

                                      for (var item in items) {
                                        int sub = int.tryParse(
                                                item['subtotal']?.toString() ??
                                                    '0') ??
                                            0;
                                        // Antisipasi jika API mereturn 'product_id' atau 'id'
                                        int idProd = int.tryParse(
                                                item['product_id']
                                                        ?.toString() ??
                                                    item['id']?.toString() ??
                                                    '0') ??
                                            0;

                                        if (idProd == 0) {
                                          hitungJasa += sub;
                                        } else {
                                          hitungSubtotal += sub;
                                        }

                                        // Pastikan keys sesuai dengan yang di-parsing oleh HalamanStruk
                                        keranjangCetak.add({
                                          'id': idProd,
                                          'nama': item['nama'] ??
                                              item['product_name'] ??
                                              'Produk',
                                          'harga': int.tryParse(
                                                  item['harga_satuan']
                                                          ?.toString() ??
                                                      item['harga']
                                                          ?.toString() ??
                                                      '0') ??
                                              0,
                                          'qty': int.tryParse(
                                                  item['qty']?.toString() ??
                                                      '1') ??
                                              1,
                                          'subtotal': sub,
                                        });
                                      }

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HalamanStruk(
                                            keranjang:
                                                keranjangCetak, // Gunakan keranjang yang sudah di-mapping
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
    );
  }
}
