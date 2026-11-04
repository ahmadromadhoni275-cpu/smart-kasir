import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core/services/return_service.dart';
import 'models/return_model.dart';
import 'tema.dart';
import 'halaman_detail_retur.dart';

class HalamanRiwayatRetur extends StatefulWidget {
  const HalamanRiwayatRetur({super.key});

  @override
  State<HalamanRiwayatRetur> createState() => _HalamanRiwayatReturState();
}

class _HalamanRiwayatReturState extends State<HalamanRiwayatRetur> {
  final ReturnService _service = ReturnService();
  bool _isLoading = true;
  List<ReturnData> _returns = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getReturns(search: _searchQuery);
      setState(() => _returns = data);
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tampilPopupCantik('Gagal Memuat', e.toString().replaceAll('Exception: ', ''), Icons.error_outline, AppColors.error);
      });
    } finally {
      setState(() => _isLoading = false);
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

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);
  String _formatTgl(String tgl) {
    try {
      return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(DateTime.parse(tgl).toLocal());
    } catch (e) { return tgl; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Retur', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, 
        iconTheme: const IconThemeData(color: AppColors.navyActive), 
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
            child: TextField(
              onSubmitted: (val) { setState(() => _searchQuery = val); _muatRiwayat(); },
              decoration: InputDecoration(
                hintText: 'Cari No. Retur atau Invoice...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true, 
                fillColor: AppColors.lightGray,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _returns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard_return, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Belum ada riwayat retur.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryEmerald,
                      onRefresh: _muatRiwayat,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _returns.length,
                        itemBuilder: (ctx, i) {
                          var ret = _returns[i];
                          bool isCompleted = ret.status == 'COMPLETED';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanDetailRetur(returnId: ret.returnId)));
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
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                              child: const Icon(Icons.keyboard_return, size: 16, color: AppColors.error),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(ret.returnNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: isCompleted ? AppColors.greenAccent.withOpacity(0.1) : AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                          child: Text(
                                            ret.status, 
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? AppColors.greenAccent : AppColors.warning)
                                          ),
                                        )
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(height: 1, color: AppColors.border),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('INV: ${ret.invoiceNumber}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Text('${_formatTgl(ret.createdAt)} • ${ret.cashierName}', style: const TextStyle(fontSize: 12, color: AppColors.navyActive)),
                                            const SizedBox(height: 4),
                                            Text('${ret.itemCount} item diretur (Via ${ret.refundMethod})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.smartBlue)),
                                          ],
                                        ),
                                        Text(_formatRupiah(ret.totalAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.error)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          )
        ],
      ),
    );
  }
}
