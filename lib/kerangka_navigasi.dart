import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart';

import 'halaman_beranda.dart';
import 'halaman_kasir.dart';
import 'halaman_produk.dart';
import 'halaman_kategori.dart';
import 'halaman_riwayat_transaksi.dart';
import 'halaman_shift.dart';
import 'halaman_laporan.dart'; 
import 'halaman_pengguna.dart'; 
import 'halaman_metode_pembayaran.dart';
import 'halaman_profil_akun.dart';
import 'halaman_pengaturan_toko.dart'; 
import 'halaman_pilih_cabang.dart';
import 'halaman_langganan_saas.dart';
import 'halaman_referral.dart'; 
import 'halaman_pusat_bantuan.dart';
import 'halaman_notifikasi.dart';
import 'halaman_login.dart'; 

// IMPORT WIDGET BADGE NOTIFIKASI
import 'widgets/notification_badge.dart';

class KerangkaNavigasi extends StatefulWidget {
  const KerangkaNavigasi({super.key});

  @override
  State<KerangkaNavigasi> createState() => _KerangkaNavigasiState();
}

class _KerangkaNavigasiState extends State<KerangkaNavigasi> {
  int _currentIndex = 0;
  String _tokoAktif = 'Toko Utama';
  String _namaPetugas = 'Ahmad Romadhoni';
  String _role = 'KASIR'; 
  bool _isLoading = true;

  late final List<Widget> _halaman = [
    const HalamanBeranda(),             // 0
    const HalamanKasir(),               // 1
    const HalamanProduk(),              // 2
    const HalamanLaporan(),             // 3
    const HalamanRiwayatTransaksi(),    // 4
    const HalamanPengaturanToko(),      // 5
    const HalamanPengguna(),            // 6
    const HalamanKategori(),            // 7
    const HalamanShift(),               // 8
    const HalamanMetodePembayaran(),    // 9
    const HalamanReferral(),            // 10
    const HalamanLanggananSaas(),       // 11
    const HalamanProfilAkun(),          // 12
    const HalamanPusatBantuan(),        // 13
  ];

  @override
  void initState() {
    super.initState();
    _muatDataSesi();
  }

  Future<void> _muatDataSesi() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaPetugas = prefs.getString('username') ?? 'Ahmad Romadhoni';
      _tokoAktif = prefs.getString('nama_toko') ?? 'Smart Kasir';
      _role = (prefs.getString('role') ?? 'KASIR').toUpperCase(); 
      _isLoading = false;
    });
  }

  void _gantiHalaman(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _pilihCabangDanMuatUlang() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanPilihCabang()));
    if (result == true) {
      _currentIndex = 0; 
      _muatDataSesi();
    }
  }

  Future<void> _prosesLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HalamanLogin()), (route) => false);
    }
  }

  // =========================================================
  // BOTTOM SHEET "MENU LAINNYA" (UNTUK MOBILE)
  // =========================================================
  void _tampilkanMenuLainnyaMobile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(color: AppColors.cardSolid),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 16),
                  const Text('Menu Lainnya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  
                  if (_role == 'OWNER' || _role == 'MANAGER') ...[
                    _buildMobileMenuItem(Icons.receipt_long, 'Transaksi', 4),
                    _buildMobileMenuItem(Icons.swap_horiz, 'Shift Kasir', 8),
                    _buildMobileMenuItem(Icons.category_outlined, 'Kategori Produk', 7),
                  ],
                  if (_role == 'OWNER') _buildMobileMenuItem(Icons.storefront, 'Pengaturan Toko & Cabang', 5),
                  if (_role == 'OWNER' || _role == 'MANAGER') ...[
                    _buildMobileMenuItem(Icons.people_outline, 'Karyawan & Akses', 6),
                    _buildMobileMenuItem(Icons.payment, 'Metode Pembayaran', 9),
                  ],
                  if (_role == 'OWNER') ...[
                    _buildMobileMenuItem(Icons.card_giftcard, 'Referral', 10),
                    _buildMobileMenuItem(Icons.diamond_outlined, 'Langganan', 11),
                  ],
                  if (_role == 'KASIR') ...[
                    _buildMobileMenuItem(Icons.inventory_2_outlined, 'Lihat Produk', 2),
                    _buildMobileMenuItem(Icons.category_outlined, 'Kategori Produk', 7),
                  ],
                  _buildMobileMenuItem(Icons.person_outline, 'Profil Akun', 12),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileMenuItem(IconData icon, String title, int indexTarget) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      onTap: () {
        Navigator.pop(context);
        _gantiHalaman(indexTarget);
      },
    );
  }

  // =========================================================
  // 1. LAYOUT MOBILE
  // =========================================================
  Widget _buildMobileLayout() {
    int bottomNavIndex = 4;
    
    if (_role == 'KASIR') {
      if (_currentIndex == 0) bottomNavIndex = 0;
      else if (_currentIndex == 1) bottomNavIndex = 1;
      else if (_currentIndex == 4) bottomNavIndex = 2; 
      else if (_currentIndex == 8) bottomNavIndex = 3; 
    } else {
      if (_currentIndex == 0) bottomNavIndex = 0;
      else if (_currentIndex == 1) bottomNavIndex = 1;
      else if (_currentIndex == 2) bottomNavIndex = 2;
      else if (_currentIndex == 3) bottomNavIndex = 3;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: AppColors.card.withOpacity(0.8)),
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/logo_smart_kasir.png', height: 32),
            const SizedBox(width: 12),
            Expanded(child: _buildStoreSelector(isDesktop: false)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: AppColors.navyActive),
            onPressed: () => _gantiHalaman(13), // Ke Pusat Bantuan
          ),
          
          // IMPLEMENTASI NOTIFICATION BADGE UNTUK MOBILE
          const NotificationBadge(),
          
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _halaman[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSolid,
          boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: bottomNavIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.smartBlue,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          onTap: (index) {
            if (index == 4) {
              _tampilkanMenuLainnyaMobile();
              return;
            }
            if (_role == 'KASIR') {
              if (index == 0) _gantiHalaman(0); 
              if (index == 1) _gantiHalaman(1); 
              if (index == 2) _gantiHalaman(4); 
              if (index == 3) _gantiHalaman(8); 
            } else {
              if (index == 0) _gantiHalaman(0); 
              if (index == 1) _gantiHalaman(1); 
              if (index == 2) _gantiHalaman(2); 
              if (index == 3) _gantiHalaman(3); 
            }
          },
          items: _role == 'KASIR' 
          ? const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Kasir'),
              BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Transaksi'),
              BottomNavigationBarItem(icon: Icon(Icons.swap_horiz_outlined), activeIcon: Icon(Icons.swap_horiz), label: 'Shift'),
              BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Lainnya'),
            ]
          : const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: 'Kasir'),
              BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Produk'),
              BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Laporan'),
              BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Lainnya'),
            ],
        ),
      ),
    );
  }

  // =========================================================
  // 2. LAYOUT DESKTOP (CRYSTAL UI) Sesuai Referensi Visual
  // =========================================================
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]),
            ),
          ),
          Row(
            children: [
              // SIDEBAR KIRI
              Container(
                width: 260,
                margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.glassBorder, width: 1.2),
                  boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Column(
                      children: [
                        // LOGO
                        Padding(
                          padding: const EdgeInsets.only(top: 32, bottom: 24),
                          child: Column(
                            children: [
                              Image.asset('assets/images/logo_smart_kasir.png', height: 60),
                              const SizedBox(height: 12),
                              const Text('Smart Kasir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const Text('Mudah • Cepat • Aman', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        
                        // MENU UTAMA 
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _buildSidebarItem(Icons.home_filled, 'Dashboard', 0),
                              if (_role == 'OWNER' || _role == 'MANAGER' || _role == 'KASIR') 
                                _buildSidebarItem(Icons.receipt_long, 'Transaksi', 4),
                              if (_role == 'OWNER' || _role == 'MANAGER') 
                                _buildSidebarItem(Icons.view_list_rounded, 'Stok', 2),
                              if (_role == 'OWNER' || _role == 'MANAGER') 
                                _buildSidebarItem(Icons.insert_chart_rounded, 'Laporan', 3), 
                              if (_role == 'OWNER' || _role == 'MANAGER') 
                                _buildSidebarItem(Icons.person_outline, 'Pengguna', 6),
                              if (_role == 'OWNER') 
                                _buildSidebarItem(Icons.settings_outlined, 'Pengaturan Toko', 5), 
                              if (_role == 'OWNER' || _role == 'MANAGER') 
                                _buildSidebarItem(Icons.payment, 'Metode Pembayaran', 9),
                              if (_role == 'OWNER') 
                                _buildSidebarItem(Icons.workspace_premium_outlined, 'Langganan', 11),
                              _buildSidebarItem(Icons.help_outline, 'Bantuan', 13), 
                            ],
                          ),
                        ),

                        // PREMIUM CARD & PROFIL CARD
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (_role == 'OWNER') 
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppColors.cardSolid, borderRadius: BorderRadius.circular(16)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.workspace_premium, color: AppColors.goldPremium, size: 18),
                                          SizedBox(width: 8),
                                          Text('Premium Member', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text('Masa Aktif\n30 Sep 2026', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 12),
                                      Container(
                                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.smartBlue, AppColors.skyBlue]), borderRadius: BorderRadius.circular(8)),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size(double.infinity, 32), padding: EdgeInsets.zero),
                                          onPressed: () => _gantiHalaman(11),
                                          child: const Text('Perpanjang →', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              
                              // Kartu Profil & Logout
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppColors.cardSolid, borderRadius: BorderRadius.circular(16)),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () => _gantiHalaman(12),
                                      child: Row(
                                        children: [
                                          const CircleAvatar(
                                            radius: 16,
                                            backgroundImage: NetworkImage('https://i.pravatar.cc/100'), 
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(_namaPetugas, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyActive), overflow: TextOverflow.ellipsis),
                                                Text(_role == 'OWNER' ? 'Admin ▾' : 'Kasir ▾', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: _prosesLogout,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('→ Logout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              
              // KONTEN KANAN
              Expanded(
                child: Column(
                  children: [
                    // HEADER DESKTOP
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 300,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: AppColors.cardSolid, borderRadius: BorderRadius.circular(30)),
                            child: const Row(
                              children: [
                                Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                                SizedBox(width: 8),
                                Text('Cari produk, transaksi... Ctrl+K', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              
                              // IMPLEMENTASI NOTIFICATION BADGE UNTUK DESKTOP
                              const NotificationBadge(),
                              
                              const SizedBox(width: 16),
                              _buildStoreSelector(isDesktop: true),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    // BODY
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24)),
                        child: Container(
                          color: Colors.transparent, 
                          child: _isLoading ? const Center(child: CircularProgressIndicator()) : _halaman[_currentIndex],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int indexTarget) {
    bool isSelected = _currentIndex == indexTarget;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _gantiHalaman(indexTarget),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: isSelected ? const LinearGradient(colors: [AppColors.menuActiveStart, AppColors.menuActiveEnd]) : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [const BoxShadow(color: AppColors.shadowBlue, blurRadius: 10, offset: Offset(0, 4))] : [],
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? Colors.white : AppColors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreSelector({bool isDesktop = false}) {
    return InkWell(
      onTap: _pilihCabangDanMuatUlang, 
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isDesktop ? AppColors.cardSolid : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Flexible(child: Text(_tokoAktif, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 18)
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) => constraints.maxWidth > 800 ? _buildDesktopLayout() : _buildMobileLayout());
  }
}
