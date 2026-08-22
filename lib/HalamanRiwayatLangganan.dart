import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class HalamanRiwayatLangganan extends StatefulWidget {
  const HalamanRiwayatLangganan({super.key});

  @override
  State<HalamanRiwayatLangganan> createState() => _HalamanRiwayatLanggananState();
}

class _HalamanRiwayatLanggananState extends State<HalamanRiwayatLangganan> {
  final String domainUrl = 'https://smartkasir.shop';
  List riwayat = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    int tokoId = prefs.getInt('toko_id') ?? 1;

    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/riwayatLangganan?toko_id=$tokoId'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          riwayat = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String _formatRp(dynamic angka) {
    int nilai = int.tryParse(angka.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(nilai);
  }

  String _formatTanggal(String tanggal) {
    DateTime dt = DateTime.parse(tanggal);
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  Widget _buildStatusChip(String status) {
    Color warnaBg;
    Color warnaTeks;
    String teksStatus;
    IconData ikon;

    if (status == 'approved') {
      warnaBg = Colors.green.shade100;
      warnaTeks = Colors.green.shade800;
      teksStatus = 'Berhasil';
      ikon = Icons.check_circle;
    } else if (status == 'rejected') {
      warnaBg = Colors.red.shade100;
      warnaTeks = Colors.red.shade800;
      teksStatus = 'Ditolak';
      ikon = Icons.cancel;
    } else {
      warnaBg = Colors.orange.shade100;
      warnaTeks = Colors.orange.shade800;
      teksStatus = 'Menunggu';
      ikon = Icons.access_time_filled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: warnaBg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: warnaTeks),
          const SizedBox(width: 5),
          Text(teksStatus, style: TextStyle(color: warnaTeks, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Riwayat Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : riwayat.isEmpty
              ? const Center(child: Text('Belum ada riwayat langganan.'))
              : RefreshIndicator(
                  onRefresh: _muatRiwayat,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: riwayat.length,
                    itemBuilder: (context, index) {
                      var item = riwayat[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey.shade300)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatTanggal(item['created_at']), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  _buildStatusChip(item['status']),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Paket Perpanjangan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${item['durasi_hari']} Hari', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Nominal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(_formatRp(item['nominal']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
                                    ],
                                  ),
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
