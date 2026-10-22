import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'halaman_detail_tagihan.dart';

class HalamanRiwayatLangganan extends StatefulWidget {
  const HalamanRiwayatLangganan({Key? key}) : super(key: key);

  @override
  _HalamanRiwayatLanggananState createState() => _HalamanRiwayatLanggananState();
}

class _HalamanRiwayatLanggananState extends State<HalamanRiwayatLangganan> {
  final Color navy = const Color(0xFF0F172A);
  final String baseUrl = 'https://smartkasir.shop/api';
  
  List<dynamic> listRiwayat = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final storeId = prefs.getInt('store_id')?.toString() ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/history'),
        headers: {'Authorization': 'Bearer $token', 'X-Store-Id': storeId},
      );

      if (response.statusCode == 200) {
        setState(() {
          listRiwayat = json.decode(response.body)['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Fungsi untuk mendapatkan warna berdasarkan status API
  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS': return Colors.green; 
      case 'FAILED': return Colors.red;    
      case 'PENDING': return Colors.orange; // Menggabungkan PENDING & UNDER_REVIEW
      default: return Colors.blue; 
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'SUCCESS': return 'Lunas & Aktif';
      case 'FAILED': return 'Ditolak';
      case 'PENDING': return 'Menunggu / Diperiksa';
      default: return 'Menunggu Pembayaran';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text('Riwayat Tagihan', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : listRiwayat.isEmpty
              ? const Center(child: Text('Belum ada riwayat tagihan.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listRiwayat.length,
                  itemBuilder: (context, index) {
                    final item = listRiwayat[index];
                    final statusColor = _getStatusColor(item['status']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['invoice_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Rp${item['amount']}', style: TextStyle(fontWeight: FontWeight.bold, color: navy)),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Paket: ${item['plan_name'] ?? '-'}'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(_getStatusText(item['status']), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => HalamanDetailTagihan(dataTagihan: item)
                          )).then((value) {
                            if (value == true) fetchHistory(); // Refresh jika ada perubahan bukti
                          });
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
