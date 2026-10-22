import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'tema.dart';
import 'core/services/api_service.dart';

class HalamanDetailShift extends StatefulWidget {
  final int shiftId;
  const HalamanDetailShift({super.key, required this.shiftId});

  @override
  State<HalamanDetailShift> createState() => _HalamanDetailShiftState();
}

class _HalamanDetailShiftState extends State<HalamanDetailShift> {
  bool _isLoading = true;
  Map<String, dynamic>? _shift;
  List<dynamic> _movements = [];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('shifts/${widget.shiftId}');
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        setState(() {
          _shift = resData['data'];
          _movements = _shift?['movements'] ?? [];
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  String _formatTanggal(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    DateTime date = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(date);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'OPENING': return Icons.play_circle_fill;
      case 'SALE': return Icons.point_of_sale;
      case 'CASH_IN': return Icons.arrow_downward;
      case 'CASH_OUT': return Icons.arrow_upward;
      case 'WITHDRAWAL': return Icons.account_balance_wallet;
      case 'REFUND': return Icons.assignment_return;
      default: return Icons.sync_alt;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'OPENING':
      case 'SALE':
      case 'CASH_IN': return AppColors.greenAccent;
      case 'CASH_OUT':
      case 'WITHDRAWAL':
      case 'REFUND': return AppColors.error;
      default: return AppColors.navyActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text('Detail Shift #${widget.shiftId}', style: const TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _shift == null
              ? const Center(child: Text('Data tidak ditemukan', style: TextStyle(color: AppColors.error)))
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeaderKas()),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
                        child: Text('Riwayat Pergerakan Kas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final mv = _movements[index];
                          String type = mv['type'] ?? 'UNKNOWN';
                          double amount = double.tryParse(mv['amount'].toString()) ?? 0;
                          bool isMinus = ['CASH_OUT', 'WITHDRAWAL', 'REFUND'].contains(type);

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getColorForType(type).withOpacity(0.1),
                                child: Icon(_getIconForType(type), color: _getColorForType(type), size: 20),
                              ),
                              title: Text(mv['description'] ?? type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: Text(_formatTanggal(mv['created_at']), style: const TextStyle(fontSize: 12)),
                              trailing: Text(
                                '${isMinus ? '-' : '+'} ${_formatRupiah(amount)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: _getColorForType(type)),
                              ),
                            ),
                          );
                        },
                        childCount: _movements.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
    );
  }

  Widget _buildHeaderKas() {
    double opening = double.tryParse(_shift!['opening_cash'].toString()) ?? 0;
    double expected = double.tryParse(_shift!['expected_cash'].toString()) ?? 0;
    double actual = double.tryParse(_shift!['actual_cash'].toString()) ?? 0;
    double diff = double.tryParse(_shift!['difference'].toString()) ?? 0;
    bool isClosed = _shift!['status'] == 'CLOSED';

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyActive,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.navyActive.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_shift!['user_name'] ?? 'Kasir', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: isClosed ? Colors.white24 : AppColors.greenAccent, borderRadius: BorderRadius.circular(12)),
                child: Text(isClosed ? 'CLOSED' : 'OPEN', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Kas Diharapkan (Sistem)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(_formatRupiah(expected), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24)),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Modal Awal', style: TextStyle(color: Colors.white70)),
              Text(_formatRupiah(opening), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          if (isClosed) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fisik Aktual', style: TextStyle(color: Colors.white70)),
                Text(_formatRupiah(actual), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Selisih', style: TextStyle(color: Colors.white70)),
                Text(_formatRupiah(diff), style: TextStyle(color: diff < 0 ? AppColors.error : (diff > 0 ? AppColors.greenAccent : Colors.white), fontWeight: FontWeight.bold)),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
