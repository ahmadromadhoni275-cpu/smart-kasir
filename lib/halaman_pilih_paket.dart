import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'halaman_tagihan_langganan.dart';

class HalamanPilihPaket extends StatefulWidget {
  const HalamanPilihPaket({Key? key}) : super(key: key);

  @override
  _HalamanPilihPaketState createState() => _HalamanPilihPaketState();
}

class _HalamanPilihPaketState extends State<HalamanPilihPaket> {
  final Color navy = const Color(0xFF0F172A);
  final Color gold = const Color(0xFFD4AF37);
  final String baseUrl = 'https://smartkasir.shop/api';

  List<dynamic> listPaket = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final storeId = prefs.getInt('store_id')?.toString() ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/subscriptions/plans'),
        headers: {'Authorization': 'Bearer $token', 'X-Store-Id': storeId},
      );

      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        setState(() {
          listPaket = resData['data'] ?? [];
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Pilih Paket Langganan', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: navy),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listPaket.length,
            itemBuilder: (context, index) {
              final paket = listPaket[index];
              // Highlight paket yang harganya menengah ke atas sebagai prioritas
              bool isHighlighted = paket['name'].toString().toLowerCase().contains('pro');
              
              return _buildPlanCard(
                context, 
                paket['plan_id'].toString(),
                paket['name'], 
                'Rp${paket['price']}', 
                '${paket['duration_days']} Hari', 
                ['Akses Cabang Terbatas', 'Laporan Penjualan'], // API dapat mengembalikan array fitur sebenarnya
                isHighlighted
              );
            },
          ),
    );
  }

  Widget _buildPlanCard(BuildContext context, String planId, String name, String price, String duration, List<String> features, bool isHighlighted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isHighlighted ? navy : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlighted ? gold : Colors.grey.shade300, width: isHighlighted ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHighlighted)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)),
                child: const Text('PALING POPULER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            Text(name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isHighlighted ? Colors.white : navy)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isHighlighted ? gold : Colors.black87)),
                Text(' / $duration', style: TextStyle(fontSize: 14, color: isHighlighted ? Colors.white70 : Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHighlighted ? gold : navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanTagihanLangganan(planId: planId)));
                },
                child: Text('Pilih $name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
