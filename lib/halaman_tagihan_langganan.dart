import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HalamanTagihanLangganan extends StatefulWidget {
  final String planId;

  const HalamanTagihanLangganan({Key? key, required this.planId}) : super(key: key);

  @override
  _HalamanTagihanLanggananState createState() => _HalamanTagihanLanggananState();
}

class _HalamanTagihanLanggananState extends State<HalamanTagihanLangganan> {
  final Color navy = const Color(0xFF0F172A);
  final Color gold = const Color(0xFFD4AF37);
  final String baseUrl = 'https://smartkasir.shop/api';
  
  bool isLoadingData = true;
  bool isProcessingPayment = false;
  Map<String, dynamic> dataCheckout = {};

  @override
  void initState() {
    super.initState();
    fetchCheckoutInfo();
  }

  Future<void> fetchCheckoutInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final storeId = prefs.getInt('store_id')?.toString() ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/checkout-info/${widget.planId}'),
        headers: {'Authorization': 'Bearer $token', 'X-Store-Id': storeId},
      );

      if (response.statusCode == 200) {
        setState(() {
          dataCheckout = json.decode(response.body)['data'];
          isLoadingData = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingData = false);
    }
  }

  Future<void> prosesBuatTagihan() async {
    setState(() => isProcessingPayment = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final storeId = prefs.getInt('store_id')?.toString() ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/subscriptions/create-payment'),
        headers: {
          'Authorization': 'Bearer $token', 
          'X-Store-Id': storeId,
          'Content-Type': 'application/json'
        },
        body: json.encode({'plan_id': widget.planId}),
      );

      setState(() => isProcessingPayment = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tagihan berhasil dibuat. Silakan transfer.'), backgroundColor: Colors.green));
        Navigator.pop(context); // Kembali atau ke Halaman Upload Bukti
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat tagihan.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      setState(() => isProcessingPayment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final plan = dataCheckout['plan_details'] ?? {};
    final paymentInfo = dataCheckout['payment_info'] ?? {};
    final instruksiManual = paymentInfo['manual_instructions'] ?? 'Menunggu instruksi admin...';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: navy,
        title: const Text('Detail Tagihan', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // RINCIAN PAKET
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rincian Pembelian', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paket ${plan['name']}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy)),
                      Text('Rp${plan['price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Rp${plan['price']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: gold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // INSTRUKSI PEMBAYARAN DARI DATABASE SUPERADMIN
            const Text('Instruksi Pembayaran Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: navy.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: navy.withOpacity(0.2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: navy),
                      const SizedBox(width: 10),
                      Text('Transfer Bank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    instruksiManual, // <-- Nilai dinamis langsung dari Superadmin Settings
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isProcessingPayment ? null : prosesBuatTagihan,
                child: isProcessingPayment 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Buat Tagihan & Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
