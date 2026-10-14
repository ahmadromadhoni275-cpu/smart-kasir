import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/payment_method_service.dart';

// Import halaman pengaturan
import 'halaman_pengaturan_qris.dart';
import 'halaman_pengaturan_transfer.dart';
import 'halaman_pengaturan_ewallet.dart';

class HalamanMetodePembayaran extends StatefulWidget {
  const HalamanMetodePembayaran({super.key});

  @override
  State<HalamanMetodePembayaran> createState() => _HalamanMetodePembayaranState();
}

class _HalamanMetodePembayaranState extends State<HalamanMetodePembayaran> {
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
      // Data dinamis dari backend (QRIS, TRANSFER, EWALLET)
      final data = await PaymentMethodService.getPaymentMethods();
      setState(() => _methods = data);
    } catch (e) {
      // Tampilkan error (jika API belum siap, list akan kosong)
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          children: [
            const Text('Tambah Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.primaryEmerald),
              title: const Text('QRIS'),
              onTap: () => Navigator.popAndPushNamed(context, 'Qris'), // Kita handle di bawah
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.blue),
              title: const Text('Transfer Bank'),
              onTap: () => Navigator.popAndPushNamed(context, 'Transfer'),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
              title: const Text('E-Wallet'),
              onTap: () => Navigator.popAndPushNamed(context, 'Ewallet'),
            ),
          ],
        ),
      ),
    ).then((val) {
      if (val == 'Qris') _navigasi(const HalamanPengaturanQris());
      if (val == 'Transfer') _navigasi(const HalamanPengaturanTransfer());
      if (val == 'Ewallet') _navigasi(const HalamanPengaturanEwallet());
    });
  }

  void _navigasi(Widget halaman) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => halaman)).then((_) => _fetchMethods());
  }

  void _editMetode(dynamic method) {
    if (method['type'] == 'QRIS') _navigasi(HalamanPengaturanQris(data: method));
    if (method['type'] == 'TRANSFER') _navigasi(HalamanPengaturanTransfer(data: method));
    if (method['type'] == 'EWALLET') _navigasi(HalamanPengaturanEwallet(data: method));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Metode Pembayaran', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryEmerald,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Metode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text('Pembayaran Digital Tersimpan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
              ),
              
              if (_methods.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('Belum ada metode pembayaran digital yang ditambahkan.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else
                ..._methods.map((m) => _buildDynamicCard(m)).toList(),
            ],
          ),
    );
  }

  Widget _buildStaticCard(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.primaryEmerald.withOpacity(0.5))),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primaryEmerald)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.check_circle, color: AppColors.primaryEmerald),
      ),
    );
  }

  Widget _buildDynamicCard(dynamic method) {
    bool isActive = method['status'] == 'ACTIVE';
    IconData icon = Icons.credit_card;
    if (method['type'] == 'QRIS') icon = Icons.qr_code_scanner;
    if (method['type'] == 'TRANSFER') icon = Icons.account_balance;
    if (method['type'] == 'EWALLET') icon = Icons.account_balance_wallet;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.navyActive)),
        title: Text(method['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(method['details'] ?? '', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(isActive ? 'Aktif' : 'Nonaktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red)),
          ],
        ),
        trailing: OutlinedButton(
          onPressed: () => _editMetode(method),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.navyActive, side: const BorderSide(color: AppColors.border)),
          child: const Text('Atur', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
