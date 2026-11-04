import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/payment_method_service.dart';

import 'halaman_pengaturan_qris.dart';
import 'halaman_pengaturan_transfer.dart';
import 'halaman_pengaturan_ewallet.dart';

class HalamanMetodePembayaran extends StatefulWidget {
  const HalamanMetodePembayaran({super.key});

  @override
  State<HalamanMetodePembayaran> createState() => _HalamanMetodePembayaranState();
}

class _HalamanMetodePembayaranState extends State<HalamanMetodePembayaran> {
  final PaymentMethodService _service = PaymentMethodService();
  bool _isLoading = true;
  List<dynamic> _methods = [];

  @override
  void initState() {
    super.initState();
    _fetchMethods();
  }

  Future<void> _fetchMethods() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getPaymentMethods();
      setState(() => _methods = data);
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tampilPopupCantik('Gagal Memuat', e.toString().replaceAll('Exception: ', ''), Icons.error_outline, AppColors.error);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _toggleStatus(dynamic method) async {
    final int id = int.parse(method['payment_method_id'].toString());
    final String newStatus = method['status'] == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));
    try {
      await _service.toggleStatus(id, newStatus);
      Navigator.pop(context);
      _fetchMethods();
    } catch (e) {
      Navigator.pop(context);
      _tampilPopupCantik('Gagal', e.toString().replaceAll('Exception: ', ''), Icons.error, AppColors.error);
    }
  }

  Future<void> _hapusMetode(dynamic method) async {
    final int id = int.parse(method['payment_method_id'].toString());
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.error)));
    try {
      await _service.deletePaymentMethod(id);
      Navigator.pop(context);
      _tampilPopupCantik('Berhasil', 'Metode pembayaran berhasil dihapus.', Icons.delete_outline, AppColors.error);
      _fetchMethods();
    } catch (e) {
      Navigator.pop(context);
      _tampilPopupCantik('Gagal Menghapus', e.toString().replaceAll('Exception: ', ''), Icons.error, AppColors.error);
    }
  }

  void _konfirmasiHapus(dynamic method) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Metode?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
        content: Text('Anda yakin ingin menghapus metode pembayaran ${method['name']}? Data yang dihapus tidak akan tampil di kasir lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _hapusMetode(method);
            }, 
            child: const Text('Hapus', style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }

  void _tambahMetode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Tipe Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
            const SizedBox(height: 16),
            _buildSheetMenu(Icons.qr_code_scanner, 'QRIS', 'Terima pembayaran via scan barcode', () => Navigator.pop(context, 'Qris')),
            const SizedBox(height: 12),
            _buildSheetMenu(Icons.account_balance, 'Transfer Bank', 'Terima pembayaran via transfer manual', () => Navigator.pop(context, 'Transfer')),
            const SizedBox(height: 12),
            _buildSheetMenu(Icons.account_balance_wallet, 'E-Wallet', 'OVO, GoPay, DANA, dll', () => Navigator.pop(context, 'Ewallet')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ).then((val) {
      if (val == 'Qris') _navigasi(const HalamanPengaturanQris());
      if (val == 'Transfer') _navigasi(const HalamanPengaturanTransfer());
      if (val == 'Ewallet') _navigasi(const HalamanPengaturanEwallet());
    });
  }

  Widget _buildSheetMenu(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.lightGray, shape: BoxShape.circle), child: Icon(icon, color: AppColors.navyActive)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)), Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))])),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary)
          ],
        ),
      ),
    );
  }

  void _navigasi(Widget halaman) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => halaman)).then((_) => _fetchMethods());
  }

  void _editMetode(dynamic method) {
    if (method['method'] == 'QRIS') _navigasi(HalamanPengaturanQris(data: method));
    if (method['method'] == 'TRANSFER') _navigasi(HalamanPengaturanTransfer(data: method));
    if (method['method'] == 'EWALLET') _navigasi(HalamanPengaturanEwallet(data: method));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Metode Pembayaran', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryEmerald,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Metode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _tambahMetode,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text('Tunai (Bawaan Sistem)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
              ),
              _buildStaticCard(Icons.payments, 'Tunai / Cash', 'Pembayaran tunai langsung di kasir'),
              
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text('Pembayaran Digital Tersimpan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
              ),
              
              if (_methods.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      children: [
                        Icon(Icons.credit_card_off, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('Belum ada metode pembayaran.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              else
                ..._methods.map((m) => _buildDynamicCard(m)).toList(),
                
              const SizedBox(height: 80),
            ],
          ),
    );
  }

  Widget _buildStaticCard(IconData icon, String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryEmerald.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: AppColors.primaryEmerald.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primaryEmerald)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.check_circle, color: AppColors.primaryEmerald),
      ),
    );
  }

  Widget _buildDynamicCard(dynamic method) {
    bool isActive = method['status'] == 'ACTIVE';
    IconData icon = Icons.credit_card;
    if (method['method'] == 'QRIS') icon = Icons.qr_code_scanner;
    if (method['method'] == 'TRANSFER') icon = Icons.account_balance;
    if (method['method'] == 'EWALLET') icon = Icons.account_balance_wallet;

    String details = '';
    if (method['account_number'] != null && method['account_name'] != null) {
      details = '${method['account_number']} a.n ${method['account_name']}';
    } else if (method['method'] == 'QRIS') {
      details = 'QRIS Statis';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppColors.border : Colors.red.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isActive ? AppColors.lightGray : Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: isActive ? AppColors.navyActive : Colors.red)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyActive)),
                      const SizedBox(height: 4),
                      Text(details, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeColor: AppColors.primaryEmerald,
                  onChanged: (val) => _toggleStatus(method),
                )
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.border)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isActive ? AppColors.greenAccent.withOpacity(0.1) : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(isActive ? 'AKTIF' : 'NONAKTIF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppColors.greenAccent : Colors.red)),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _konfirmasiHapus(method),
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  label: const Text('Hapus', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyActive, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                  onPressed: () => _editMetode(method),
                  icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                  label: const Text('Atur', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
