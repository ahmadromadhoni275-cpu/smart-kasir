import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'halaman_pilih_paket.dart';

class HalamanLanggananSaas extends StatefulWidget {
  const HalamanLanggananSaas({Key? key}) : super(key: key);

  @override
  _HalamanLanggananSaasState createState() => _HalamanLanggananSaasState();
}

class _HalamanLanggananSaasState extends State<HalamanLanggananSaas> {
  final Color navy = const Color(0xFF0F172A);
  final Color gold = const Color(0xFFD4AF37);
  final Color emerald = const Color(0xFF10B981);
  
  bool isLoading = true;
  Map<String, dynamic> dataLangganan = {};
  final String baseUrl = 'https://smartkasir.shop/api'; // Sesuaikan URL API Anda

  @override
  void initState() {
    super.initState();
    fetchCurrentSubscription();
  }

  Future<void> fetchCurrentSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final storeId = prefs.getInt('store_id')?.toString() ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/current'), // Endpoint backend Anda
        headers: {
          'Authorization': 'Bearer $token',
          'X-Store-Id': storeId,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        setState(() {
          dataLangganan = resData['data'] ?? {};
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Ambil data (atau gunakan dummy jika API belum siap sepenuhnya)
    String namaPaket = dataLangganan['plan_name'] ?? 'Smart Kasir Pro';
    String masaAktif = dataLangganan['expired_at'] ?? '31 Okt 2026';
    String status = dataLangganan['status'] ?? 'Aktif';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text('Langganan Smart Kasir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: navy,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: navy.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Paket bisnis saat ini', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: emerald.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: emerald)),
                        child: Text(status.toUpperCase(), style: TextStyle(color: emerald, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(namaPaket, style: TextStyle(color: gold, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('Masa aktif hingga', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text(masaAktif, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanPilihPaket()));
                },
                child: const Text('Perpanjang / Ubah Paket', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
