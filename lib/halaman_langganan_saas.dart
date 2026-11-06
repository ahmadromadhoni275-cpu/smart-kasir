import 'dart:ui';
import 'package:flutter/material.dart';
import 'tema.dart';
import 'models/subscription_model.dart';
import 'core/services/subscription_service.dart';
import 'halaman_pilih_paket.dart';
import 'halaman_riwayat_langganan.dart';

class HalamanLanggananSaas extends StatefulWidget {
  const HalamanLanggananSaas({super.key});

  @override
  State<HalamanLanggananSaas> createState() => _HalamanLanggananSaasState();
}

class _HalamanLanggananSaasState extends State<HalamanLanggananSaas> {
  final SubscriptionService _subService = SubscriptionService();
  SubscriptionModel? _currentSub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentSubscription();
  }

  Future<void> _fetchCurrentSubscription() async {
    setState(() => _isLoading = true);
    try {
      final data = await _subService.getCurrentSubscription();
      if (mounted) setState(() => _currentSub = data);
    } catch (e) {
      debugPrint("Gagal load langganan: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Langganan & Lisensi', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.navyActive),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanRiwayatLangganan())),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]))),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKartuLangganan(),
                    const SizedBox(height: 24),
                    _buildKartuBatasPenggunaan(),
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPremium, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4, shadowColor: AppColors.goldPremium.withOpacity(0.4)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanPilihPaket())).then((_) => _fetchCurrentSubscription()),
                        icon: const Icon(Icons.upgrade, color: Colors.white),
                        label: const Text('PERPANJANG / UPGRADE PAKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildKartuLangganan() {
    bool isAktif = _currentSub?.status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navyActive, Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.navyActive.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Paket Bisnis Saat Ini', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: isAktif ? AppColors.primaryEmerald.withOpacity(0.2) : AppColors.error.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: isAktif ? AppColors.primaryEmerald : AppColors.error)),
                child: Text(isAktif ? 'AKTIF' : 'KEDALUWARSA', style: TextStyle(color: isAktif ? AppColors.primaryEmerald : AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_currentSub?.planName ?? 'Belum Ada Lisensi', style: const TextStyle(color: AppColors.goldPremium, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          const Text('Masa Aktif Berakhir Pada', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(_currentSub?.expiredAt ?? '-', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKartuBatasPenggunaan() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune, color: AppColors.navyActive, size: 20),
                  SizedBox(width: 8),
                  Text('Kapasitas Sistem Anda', style: TextStyle(color: AppColors.navyActive, fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 24),
              _buildLimitRow(Icons.storefront, 'Maksimal Cabang', '${_currentSub?.maxStores ?? 0} Toko'),
              const Divider(height: 24),
              _buildLimitRow(Icons.group, 'Maksimal Akun Kasir', '${_currentSub?.maxUsers ?? 0} Pengguna'),
              const Divider(height: 24),
              _buildLimitRow(Icons.inventory_2, 'Maksimal Item Produk', '${_currentSub?.maxProducts ?? 0} Item'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLimitRow(IconData icon, String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.textSecondary, size: 18)),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 13)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryEmerald, fontSize: 14)),
      ],
    );
  }
}
