import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/return_service.dart';
import 'core/services/printer_service.dart'; 
import 'models/return_model.dart';
import 'models/return_item_model.dart';
import 'tema.dart';

class HalamanDetailRetur extends StatefulWidget {
  final int returnId;
  const HalamanDetailRetur({super.key, required this.returnId});

  @override
  State<HalamanDetailRetur> createState() => _HalamanDetailReturState();
}

class _HalamanDetailReturState extends State<HalamanDetailRetur> {
  final ReturnService _service = ReturnService();
  bool _isLoading = true;
  
  ReturnData? _returnMaster;
  List<ReturnItemDetail> _returnItems = [];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _service.getReturnDetail(widget.returnId);
      setState(() {
        _returnMaster = ReturnData.fromJson(data['return']);
        _returnItems = (data['items'] as List).map((i) => ReturnItemDetail.fromJson(i)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tampilPopupCantik('Gagal Memuat', e.toString().replaceAll('Exception: ', ''), Icons.error_outline, AppColors.error, onTutup: () => Navigator.pop(context));
      });
    }
  }

  void _tampilPopupCantik(String judul, String pesan, IconData ikon, Color warna, {VoidCallback? onTutup}) {
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
              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: warna, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: onTutup ?? () => Navigator.pop(ctx), child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);

  Future<void> _cetakStrukRetur() async {
    if (_returnMaster == null) return;
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));

    try {
      Map<String, dynamic> dataLaporan = {
        'No_Retur': _returnMaster!.returnNumber,
        'No_Invoice': _returnMaster!.invoiceNumber,
        'Tanggal': _returnMaster!.createdAt,
        'Kasir': _returnMaster!.cashierName,
        'Metode_Refund': _returnMaster!.refundMethod,
        'Alasan': _returnMaster!.reason ?? '-',
        '-- BARANG DIRETUR --': '',
      };

      for (var item in _returnItems) {
        dataLaporan['${item.productName} (x${item.quantity})'] = item.amount;
      }

      dataLaporan['-- TOTAL --'] = '';
      dataLaporan['TOTAL REFUND'] = _returnMaster!.totalAmount;

      await PrinterService().cetakLaporan(dataLaporan, "BUKTI RETUR & REFUND");
      
      Navigator.pop(context);
      _tampilPopupCantik('Cetak Berhasil', 'Bukti retur berhasil dikirim ke printer bluetooth.', Icons.print, AppColors.primaryEmerald);
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
        title: const Text('Detail Retur', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 1,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : _returnMaster == null
          ? const Center(child: Text('Data tidak ditemukan', style: TextStyle(color: AppColors.textSecondary)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.assignment_return, color: AppColors.error, size: 40)),
                              const SizedBox(height: 12),
                              Text(_returnMaster!.returnNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                              const SizedBox(height: 4),
                              Text(_returnMaster!.createdAt, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: _returnMaster!.status == 'COMPLETED' ? AppColors.greenAccent.withOpacity(0.1) : AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  _returnMaster!.status,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _returnMaster!.status == 'COMPLETED' ? AppColors.greenAccent : AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(thickness: 1, color: AppColors.border),
                        ),
                        
                        _buildInfoRow('Invoice Asal', _returnMaster!.invoiceNumber, isBold: true),
                        _buildInfoRow('Kasir', _returnMaster!.cashierName),
                        _buildInfoRow('Metode Refund', _returnMaster!.refundMethod, isBold: true),
                        _buildInfoRow('Alasan Retur', _returnMaster!.reason ?? '-'),
                        
                        const SizedBox(height: 24),
                        const Text('Daftar Barang', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 16)),
                        const SizedBox(height: 12),
                        
                        ..._returnItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navyActive)),
                                    const SizedBox(height: 4),
                                    Text('${item.quantity} x ${_formatCurrency(item.price)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text(_formatCurrency(item.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                            ],
                          ),
                        )),
                        
                        const Divider(height: 32, color: AppColors.border),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL REFUND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                              Text(_formatCurrency(_returnMaster!.totalAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _isLoading || _returnMaster == null ? null : _buildBottomAction(),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.navyActive)),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -5))]),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('Cetak Bukti Retur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: _cetakStrukRetur,
          ),
        ),
      ),
    );
  }
}
