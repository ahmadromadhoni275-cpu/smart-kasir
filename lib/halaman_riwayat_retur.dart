import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'tema.dart';
import 'services/api_service.dart';
import 'halaman_detail_retur.dart';

class HalamanRiwayatRetur extends StatefulWidget {
  const HalamanRiwayatRetur({super.key});

  @override
  State<HalamanRiwayatRetur> createState() => _HalamanRiwayatReturState();
}

class _HalamanRiwayatReturState extends State<HalamanRiwayatRetur> {
  bool _isLoading = true;
  List<dynamic> _returns = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('returns?search=$_searchQuery');
      if (response.statusCode == 200) {
        setState(() {
          _returns = json.decode(response.body)['data'];
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
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
        title: const Text('Riwayat Retur', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, iconTheme: const IconThemeData(color: AppColors.navyActive), elevation: 1,
      ),
      body: Column(
        children: [
          // 1. PENCARIAN & FILTER
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onSubmitted: (val) { setState(() => _searchQuery = val); _muatRiwayat(); },
                  decoration: InputDecoration(
                    hintText: '🔍 Cari no. retur / invoice...',
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
                      ActionChip(label: const Text('📅 Hari Ini ▼'), onPressed: (){}),
                      const SizedBox(width: 8),
                      ActionChip(label: const Text('Retur: Semua ▼'), onPressed: (){}),
                      const SizedBox(width: 8),
                      ActionChip(label: const Text('Refund: Semua ▼'), onPressed: (){}),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // 2. DAFTAR RETUR
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _returns.isEmpty
                  ? const Center(child: Text('Tidak ada riwayat retur.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _returns.length,
                      itemBuilder: (ctx, i) {
                        var ret = _returns[i];
                        bool isCompleted = ret['status'] == 'COMPLETED';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanDetailRetur(returnId: int.parse(ret['return_id'].toString()))));
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.keyboard_return, size: 16, color: AppColors.textSecondary),
                                          const SizedBox(width: 8),
                                          Text(ret['return_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                                        ],
                                      ),
                                      Text(
                                        isCompleted ? 'COMPLETED' : ret['status'], 
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? AppColors.greenAccent : AppColors.error)
                                      )
                                    ],
                                  ),
                                  const Divider(),
                                  Text(ret['invoice_number'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  Text('${_formatTgl(ret['created_at'])} • ${ret['cashier_name']}', style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Text('${ret['item_count']} item', style: const TextStyle(fontSize: 12)),
                                  Text('Refund: ${ret['refund_method']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_formatRupiah(double.parse(ret['total_amount'])), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary)
                                    ],
                                  )
                                ],
                              ),
                            ),
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
