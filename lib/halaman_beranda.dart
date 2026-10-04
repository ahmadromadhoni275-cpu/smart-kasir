import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'tema.dart';
import 'services/api_service.dart';

class HalamanBeranda extends StatefulWidget {
  const HalamanBeranda({super.key});

  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

class _HalamanBerandaState extends State<HalamanBeranda> {
  bool _isLoading = true;
  String _role = 'KASIR';
  Map<String, dynamic> _dataDashboard = {};

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _role = (prefs.getString('role') ?? 'KASIR').toUpperCase();

    try {
      final response = await ApiService.get('dashboard');
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _dataDashboard = jsonResponse['data'];
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat dashboard: $e");
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  // =================================================================
  // WIDGET CARD RINGKASAN ATAS
  // =================================================================
  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.navyActive.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 12, color: subtitle.contains('+') ? AppColors.greenAccent : AppColors.error, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // =================================================================
  // GRID CARDS (Responsif untuk PC & Mobile)
  // =================================================================
  Widget _buildSummarySection() {
    final summary = _dataDashboard['summary'] ?? {};
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cross axis count menyesuaikan lebar layar
        int crossAxisCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 2);
        double childAspectRatio = constraints.maxWidth > 600 ? 1.5 : 1.2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildSummaryCard('Pendapatan', _formatRupiah(summary['sales'] ?? 0), '+12.5% vs kemarin', Icons.account_balance_wallet, AppColors.primaryEmerald),
            _buildSummaryCard('Transaksi', '${summary['transactions'] ?? 0}', '+8.2% vs kemarin', Icons.receipt_long, AppColors.goldPremium),
            
            // Laba hanya muncul untuk OWNER & MANAGER
            if (_role != 'KASIR')
              _buildSummaryCard('Laba Bersih', _formatRupiah(summary['profit'] ?? 0), '+15.3% vs kemarin', Icons.trending_up, AppColors.greenAccent),
            
            _buildSummaryCard('Produk & Stok', '${summary['products'] ?? 0} Produk', '${summary['low_stock'] ?? 0} Stok Menipis', Icons.inventory_2, AppColors.error),
          ],
        );
      },
    );
  }

  // =================================================================
  // WIDGET PRODUK TERLARIS & TRANSAKSI TERBARU (Baris Bawah)
  // =================================================================
  Widget _buildBottomSection(bool isDesktop) {
    List recentTxs = _dataDashboard['recent_transactions'] ?? [];
    List bestProducts = _dataDashboard['best_products'] ?? [];

    Widget txWidget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transaksi Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          if (recentTxs.isEmpty) const Text('Belum ada transaksi', style: TextStyle(color: AppColors.textSecondary)),
          ...recentTxs.map((tx) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: AppColors.primaryEmerald.withOpacity(0.1), child: const Icon(Icons.receipt, color: AppColors.primaryEmerald, size: 18)),
              title: Text(tx['invoice_number'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
              subtitle: Text(tx['payment_method'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatRupiah(double.parse(tx['grand_total'].toString())), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 13)),
                  Text(tx['transaction_status'], style: const TextStyle(color: AppColors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    Widget bestWidget = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏆 Produk Terlaris', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          if (bestProducts.isEmpty) const Text('Belum ada data', style: TextStyle(color: AppColors.textSecondary)),
          ...bestProducts.asMap().entries.map((entry) {
            int idx = entry.key;
            var prod = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text('#${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldPremium, fontSize: 14)),
                  const SizedBox(width: 16),
                  Expanded(child: Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                  Text('${prod['jumlah_terjual']} terjual', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    // Responsivitas: Jika Desktop, bersebelahan. Jika HP, atas bawah.
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: txWidget),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: bestWidget),
        ],
      );
    }
    return Column(
      children: [
        txWidget,
        const SizedBox(height: 16),
        bestWidget,
      ],
    );
  }

  // =================================================================
  // WIDGET SHIFT AKTIF
  // =================================================================
  Widget _buildShiftWidget() {
    var shift = _dataDashboard['active_shift'];
    if (shift == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.error)),
        child: const Text('⚠ Kasir Terkunci. Silakan buka Shift terlebih dahulu di Menu Shift.', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryEmerald)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_open, color: AppColors.primaryEmerald, size: 18),
              SizedBox(width: 8),
              Text('SHIFT AKTIF', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Kasir: ${shift['kasir_name']}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navyActive))),
              Expanded(child: Text('Mulai: ${shift['opened_at'].toString().substring(11, 16)}', style: const TextStyle(color: AppColors.textSecondary))),
              Expanded(child: Text('Modal: ${_formatRupiah(double.parse(shift['opening_cash'].toString()))}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;
        
        return RefreshIndicator(
          color: AppColors.primaryEmerald,
          onRefresh: _muatData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salam & Tanggal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selamat datang kembali 👋', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                        SizedBox(height: 4),
                        Text('Pantau performa bisnis Anda hari ini.', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                    if (isDesktop)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                        child: Text(DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(DateTime.now()), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      )
                  ],
                ),
                const SizedBox(height: 24),

                // Notifikasi Shift (Hanya relevan bagi Manager/Kasir)
                if (_role == 'KASIR' || _role == 'MANAGER') _buildShiftWidget(),

                // 4 Kartu Ringkasan
                _buildSummarySection(),
                
                const SizedBox(height: 24),

                // Bagian Bawah (Transaksi & Produk Terlaris)
                _buildBottomSection(isDesktop),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }
}
