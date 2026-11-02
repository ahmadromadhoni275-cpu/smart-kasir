import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart';

// --- IMPORT SEMUA HALAMAN YANG SUDAH DIBUAT ---
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

class KerangkaNavigasi extends StatefulWidget {
  const KerangkaNavigasi({super.key});

  @override
  State<KerangkaNavigasi> createState() => _KerangkaNavigasiState();
}

class _KerangkaNavigasiState extends State<KerangkaNavigasi> {
  int _currentIndex = 0;
  String _tokoAktif = 'Toko Utama';
  String _namaPetugas = 'User';
  String _role = 'KASIR'; // Default Role

  late final List<Widget> _halaman = [
    const HalamanBeranda(), 
    const HalamanKasir(),                                 
    const HalamanProduk(),                                
    const HalamanLaporan(),                               
    const HalamanRiwayatTransaksi(),                      
    const HalamanPengaturanToko(),                        
    const HalamanPengguna(),                              
    const HalamanKategori(),                              
    const HalamanShift(),                                 
    const HalamanMetodePembayaran(),                      
    const HalamanReferral(),                              
    const HalamanLanggananSaas(),                         
    const HalamanProfilAkun(),                            
  ];

  @override
  void initState() {
    super.initState();
    _muatDataSesi();
  }

  Future<void> _muatDataSesi() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaPetugas = prefs.getString('username') ?? 'Ahmad Romadhoni';
      _tokoAktif = prefs.getString('nama_toko') ?? 'Toko Maju Jaya';
      _role = (prefs.getString('role') ?? 'Admin').toUpperCase(); 
    });
  }

  void _gantiHalaman(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _prosesLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Bersihkan semua sesi
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HalamanLogin()),
        (route) => false,
      );
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
              decoration: const BoxDecoration(
                color: AppColors.cardSolid, 
              ),
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
                  
                  if (_role == 'OWNER')
                    _buildMobileMenuItem(Icons.storefront, 'Pengaturan Toko & Cabang', 5),
                    
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
        backgroundColor: Colors.transparent, // Transparan untuk efek Crystal
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
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanPusatBantuan()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.navyActive),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _halaman[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSolid,
          boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: bottomNavIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.smartBlue, // Ganti ke biru Crystal
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
  // 2. LAYOUT DESKTOP (CRYSTAL UI)
  // =========================================================
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Stack(
        children: [
          // Background Utama
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd],
              ),
            ),
          ),
          
          Row(
            children: [
              // ===============================================
              // SIDEBAR KIRI (GLASSMORPHISM)
              // ===============================================
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
                        // BAGIAN ATAS: LOGO
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
                        
                        // BAGIAN TENGAH: MENU
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _buildSidebarItem(Icons.home_filled, 'Dashboard', 0),
                              _buildSidebarItem(Icons.receipt_long, 'Transaksi', 4),
                              if (_role == 'OWNER' || _role == 'MANAGER') ...[
                                _buildSidebarItem(Icons.inventory_2, 'Produk', 2),
                                _buildSidebarItem(Icons.inventory, 'Stok', 8), // Sesuaikan index jika ada halaman khusus stok
                              ],
                              if (_role == 'OWNER' || _role == 'MANAGER') _buildSidebarItem(Icons.analytics, 'Laporan', 3), 
                              _buildSidebarItem(Icons.person_outline, 'Pengguna', 6),
                              if (_role == 'OWNER') _buildSidebarItem(Icons.settings, 'Pengaturan Toko', 5), 
                              if (_role == 'OWNER') _buildSidebarItem(Icons.diamond_outlined, 'Langganan', 11),
                              _buildSidebarItem(Icons.help_outline, 'Bantuan', 7), // Arahkan ke pusat bantuan
                            ],
                          ),
                        ),

                        // BAGIAN BAWAH: PREMIUM CARD & PROFIL CARD
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Kartu Premium
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSolid,
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [AppColors.menuActiveStart, AppColors.menuActiveEnd]),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                                          minimumSize: const Size(double.infinity, 32), padding: EdgeInsets.zero
                                        ),
                                        onPressed: () {},
                                        child: const Text('Perpanjang →', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Kartu Profil Logout
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardSolid,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          radius: 16,
                                          backgroundImage: NetworkImage('https://i.pravatar.cc/100'), // Ganti dengan foto profil asli jika ada
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_namaPetugas, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyActive), overflow: TextOverflow.ellipsis),
                                              Text(_role, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                      ],
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
              
              // ===============================================
              // KONTEN KANAN (HEADER & BODY)
              // ===============================================
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
                          // Search Bar (Hanya Dummy UI)
                          Container(
                            width: 300,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardSolid,
                              borderRadius: BorderRadius.circular(30),
                            ),
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
                              // Icon Notif
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_outlined, color: AppColors.navyActive),
                                    onPressed: () {},
                                  ),
                                  Positioned(
                                    top: 8, right: 8,
                                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                  )
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Selector Toko Header
                              _buildStoreSelector(isDesktop: true),
                            ],
                          )
                        ],
                      ),
                    ),
                    
                    // BODY KONTEN
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24)),
                        child: Container(
                          // Agar halaman yang dipanggil memiliki latar yang sesuai dengan gradient di belakangnya
                          color: Colors.transparent, 
                          child: _halaman[_currentIndex],
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

  // Desain Item Sidebar Kapsul
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

  // Desain Selector Toko di Kanan Atas
  Widget _buildStoreSelector({bool isDesktop = false}) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanPilihCabang())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDesktop ? AppColors.cardSolid : Colors.transparent, 
          borderRadius: BorderRadius.circular(20)
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _tokoAktif, 
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)
              ),
            ),
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
