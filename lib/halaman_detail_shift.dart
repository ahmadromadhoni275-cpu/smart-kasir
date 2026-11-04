import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'tema.dart';
import 'core/services/api_service.dart';
import 'core/services/printer_service.dart';

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
      // Pastikan endpoint ini me-return format { "data": { "user_name": "...", "opening_cash": ... , "movements": [ ... ] } }
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
    if (mounted) setState(() => _isLoading = false);
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

  void _tampilPopupCantik(String judul, String pesan, IconData ikon, Color warna) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: warna.withOpacity(0.1), shape: BoxShape.circle), child: Icon(ikon, color: warna, size: 48)),
              const SizedBox(height: 20),
              Text(judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 12),
              Text(pesan, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: warna, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () => Navigator.pop(ctx), child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cetakStrukShift() async {
    if (_shift == null) return;
    
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));

    try {
      double opening = double.tryParse(_shift!['opening_cash'].toString()) ?? 0;
      double expected = double.tryParse(_shift!['expected_cash'].toString()) ?? 0;
      double actual = double.tryParse(_shift!['actual_cash'].toString()) ?? 0;
      double diff = double.tryParse(_shift!['difference'].toString()) ?? 0;
      bool isClosed = _shift!['status'] == 'CLOSED';

      Map<String, dynamic> dataLaporan = {
        'periode': 'Shift #${widget.shiftId}',
        'Kasir': _shift!['user_name'] ?? 'Kasir',
        'Status': isClosed ? 'DITUTUP' : 'BERJALAN',
        '-- RINGKASAN KAS --': '',
        'Modal_Awal': opening,
        'Kas_Sistem': expected,
      };

      if (isClosed) {
        dataLaporan['Fisik_Aktual'] = actual;
        dataLaporan['Selisih'] = diff; 
      }

      dataLaporan['-- PERGERAKAN KAS --'] = '';
      
      for (int i = 0; i < _movements.length; i++) {
        var mv = _movements[i];
        String type = mv['type'] ?? 'UNKNOWN';
        String desc = mv['description'] ?? type;
        double amount = double.tryParse(mv['amount'].toString()) ?? 0;
        bool isMinus = ['CASH_OUT', 'WITHDRAWAL', 'REFUND'].contains(type);
        
        String time = '';
        if (mv['created_at'] != null) {
          try {
            time = DateFormat('HH:mm').format(DateTime.parse(mv['created_at']).toLocal());
          } catch (_) {}
        }
        
        String key = '$desc ($time)';
        while (dataLaporan.containsKey(key)) {
          key += ' ';
        }
        dataLaporan[key] = isMinus ? -amount : amount;
      }

      await PrinterService().cetakLaporan(dataLaporan, isClosed ? "STRUK PENUTUPAN SHIFT" : "STRUK CEK SHIFT");
      
      Navigator.pop(context);
      _tampilPopupCantik('Cetak Berhasil', 'Struk riwayat shift berhasil dikirim ke printer bluetooth.', Icons.print, AppColors.primaryEmerald);
    } catch (e) {
      Navigator.pop(context);
      _tampilPopupCantik('Gagal Mencetak', e.toString().replaceAll('Exception: ', ''), Icons.print_disabled, AppColors.error);
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
                        padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 12),
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
                          Color typeColor = _getColorForType(type);

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4, offset: const Offset(0, 2))]
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Icon(_getIconForType(type), color: typeColor, size: 20),
                              ),
                              title: Text(mv['description'] ?? type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                              subtitle: Text(_formatTanggal(mv['created_at']), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              trailing: Text(
                                '${isMinus ? '-' : '+'} ${_formatRupiah(amount)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: typeColor),
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
      bottomNavigationBar: _isLoading || _shift == null ? null : _buildBottomAction(),
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
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryEmerald, Color(0xFF107A4D)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.primaryEmerald.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.person, color: Colors.white, size: 16)),
                  const SizedBox(width: 8),
                  Text(_shift!['user_name'] ?? 'Kasir', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: isClosed ? Colors.white24 : AppColors.greenAccent, borderRadius: BorderRadius.circular(12)),
                child: Text(isClosed ? 'CLOSED' : 'OPEN', style: TextStyle(color: isClosed ? Colors.white70 : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Kas Diharapkan (Sistem)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(_formatRupiah(expected), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24, height: 1)),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Modal Awal', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(_formatRupiah(opening), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          if (isClosed) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fisik Aktual', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(_formatRupiah(actual), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: diff < 0 ? AppColors.error : (diff > 0 ? AppColors.greenAccent : Colors.white24), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Selisih', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(_formatRupiah(diff), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyActive, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            icon: const Icon(Icons.print, color: Colors.white, size: 20),
            label: const Text('Cetak Struk Z-Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            onPressed: _cetakStrukShift,
          ),
        ),
      ),
    );
  }
}
