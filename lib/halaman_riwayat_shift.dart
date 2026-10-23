import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'tema.dart';
import 'core/services/api_service.dart';
import 'halaman_detail_shift.dart';

class HalamanRiwayatShift extends StatefulWidget {
  const HalamanRiwayatShift({super.key});

  @override
  State<HalamanRiwayatShift> createState() => _HalamanRiwayatShiftState();
}

class _HalamanRiwayatShiftState extends State<HalamanRiwayatShift> {
  bool _isLoading = true;
  List<dynamic> _riwayatShifts = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final response = await ApiService.get('shifts');
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        setState(() {
          _riwayatShifts = resData['data'] ?? [];
        });
      } else {
        setState(() => _errorMessage = 'Gagal memuat riwayat shift.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan jaringan.');
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);
  
  String _formatTanggal(String dateStr) {
    if (dateStr.isEmpty) return '-';
    DateTime date = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Riwayat Shift', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: AppColors.error)))
              : _riwayatShifts.isEmpty
                  ? const Center(child: Text('Belum ada riwayat shift.', style: TextStyle(color: AppColors.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _fetchRiwayat,
                      color: AppColors.primaryEmerald,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _riwayatShifts.length,
                        itemBuilder: (context, index) {
                          final shift = _riwayatShifts[index];
                          bool isClosed = shift['status'] == 'CLOSED';
                          double expected = double.tryParse(shift['expected_cash'].toString()) ?? 0;
                          double actual = double.tryParse(shift['actual_cash'].toString()) ?? 0;
                          double diff = double.tryParse(shift['difference'].toString()) ?? 0;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanDetailShift(shiftId: int.parse(shift['shift_id'].toString()))));
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
                                            CircleAvatar(radius: 14, backgroundColor: AppColors.lightGray, child: const Icon(Icons.person, size: 16, color: AppColors.navyActive)),
                                            const SizedBox(width: 8),
                                            Text(shift['user_name'] ?? 'Kasir', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: isClosed ? AppColors.lightGray : AppColors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                          child: Text(isClosed ? 'CLOSED' : 'OPEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isClosed ? AppColors.textSecondary : AppColors.greenAccent)),
                                        )
                                      ],
                                    ),
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                    
                                    Row(
                                      children: [
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Mulai', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)), Text(_formatTanggal(shift['opened_at']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))])),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Selesai', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)), Text(isClosed ? _formatTanggal(shift['closed_at']) : 'Berjalan', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))])),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Expected Cash', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              Text(_formatRupiah(expected), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                                            ],
                                          ),
                                          if (isClosed)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text('Selisih', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                Text(_formatRupiah(diff), style: TextStyle(fontWeight: FontWeight.bold, color: diff < 0 ? AppColors.error : (diff > 0 ? AppColors.greenAccent : AppColors.navyActive))),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
