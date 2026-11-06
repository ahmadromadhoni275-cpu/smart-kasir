import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'tema.dart';
import 'models/payment_history_model.dart';
import 'core/services/subscription_service.dart';
import 'halaman_detail_tagihan.dart';

class HalamanRiwayatLangganan extends StatefulWidget {
  const HalamanRiwayatLangganan({super.key});

  @override
  State<HalamanRiwayatLangganan> createState() => _HalamanRiwayatLanggananState();
}

class _HalamanRiwayatLanggananState extends State<HalamanRiwayatLangganan> {
  final SubscriptionService _subService = SubscriptionService();
  List<PaymentHistoryModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await _subService.getHistory();
      if (mounted) setState(() => _history = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS': return Colors.green;
      case 'FAILED': return Colors.red;
      case 'PENDING': return Colors.orange;
      default: return AppColors.smartBlue; 
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'SUCCESS': return 'Lunas';
      case 'FAILED': return 'Ditolak';
      case 'PENDING': return 'Menunggu / Diperiksa';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Riwayat Tagihan', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]))),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : _history.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade400), const SizedBox(height: 16), const Text('Belum ada riwayat tagihan', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))]))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 40),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      final Color statusColor = _getStatusColor(item.status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navyActive, fontSize: 15)),
                              Text(_formatRupiah(item.amount), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryEmerald, fontSize: 15)),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('Paket: ${item.planName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(_getStatusText(item.status), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => HalamanDetailTagihan(
                                dataTagihan: {
                                  'invoice_number': item.invoiceNumber,
                                  'amount': item.amount,
                                  'plan_name': item.planName,
                                  'status': item.status,
                                  'payment_expires_at': item.createdAt,
                                  'payment_id': item.paymentId,
                                  'notes': item.notes
                                }
                              )

                            )).then((value) { if (value == true) _fetchHistory(); });
                          },
                        ),
                      );
                    },
                  ),
        ],
      ),
    );
  }
}
