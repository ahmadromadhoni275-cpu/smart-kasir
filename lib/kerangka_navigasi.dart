import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart';

// TODO: Import Halaman Anda
// import 'halaman_beranda.dart';
// import 'halaman_kasir.dart';
// import 'halaman_produk.dart';
// import 'halaman_laporan.dart';
// import 'halaman_transaksi.dart';
// ... dll

class KerangkaNavigasiUtama extends StatefulWidget {
  const KerangkaNavigasiUtama({super.key});

  @override
  State<KerangkaNavigasiUtama> createState() => _KerangkaNavigasiUtamaState();
}

class _KerangkaNavigasiUtamaState extends State<KerangkaNavigasiUtama> {
  int _currentIndex = 0;
  String _tokoAktif = 'Toko Utama';
  String _namaPetugas = 'User';
  String _role = 'KASIR'; // Default Role

  final List<String> _daftarToko = ['Toko Utama', 'Cabang Pakisaji'];

  // =========================================================
  // INDEKS HALAMAN UNIVERSAL (Total 13 Halaman)
  // =========================================================
  final List<Widget> _halaman = [
    const Center(child: Text('0: Dashboard (Home)')),     
    const Center(child: Text('1: Kasir POS')),            
    const Center(child: Text('2: Manajemen Produk')),     
    const Center(child: Text('3: Laporan Bisnis')),       
    const Center(child: Text('4: Riwayat Transaksi')),    
    const Center(child: Text('5: Manajemen Cabang')),     
    const Center(child: Text('6: Karyawan')),             
    const Center(child: Text('7: Pengaturan')),           
    const Center(child: Text('8: Shift Kasir')),          
    const Center(child: Text('9: Metode Pembayaran')),    
    const Center(child: Text('10: Referral')),            
    const Center(child: Text('11: Langganan SaaS')),      
    const Center(child: Text('12: Profil Kasir')),        
  ];

  @override
  void initState() {
    super.initState();
    _muatDataSesi();
  }

  Future<void> _muatDataSesi() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaPetugas = prefs.getString('username') ?? 'User';
      _tokoAktif = prefs.getString('nama_toko') ?? 'Toko Utama';
      // Pastikan format uppercase agar sesuai kondisi (OWNER, MANAGER, KASIR)
      _role = (prefs.getString('role') ?? 'KASIR').toUpperCase(); 
    });
  }

  void _gantiHalaman(int index) {
    setState(() {
      _currentIndex = index;
    });
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
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              const Text('Menu Lainnya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              
              // MENU DINAMIS BERDASARKAN ROLE
              if (_role == 'OWNER' || _role == 'MANAGER') ...[
                _buildMobileMenuItem(Icons.receipt_long, 'Transaksi', 4),
                _buildMobileMenuItem(Icons.swap_horiz, 'Shift Kasir', 8),
              ],
              
              if (_role == 'OWNER')
                _buildMobileMenuItem(Icons.storefront, 'Cabang', 5),
                
              if (_role == 'OWNER' || _role == 'MANAGER') ...[
                _buildMobileMenuItem(Icons.people_outline, 'Karyawan', 6),
                _buildMobileMenuItem(Icons.payment, 'Pembayaran', 9),
              ],
              
              if (_role == 'OWNER') ...[
                _buildMobileMenuItem(Icons.card_giftcard, 'Referral', 10),
                _buildMobileMenuItem(Icons.diamond_outlined, 'Langganan', 11),
              ],

              if (_role == 'KASIR') ...[
                _buildMobileMenuItem(Icons.inventory_2_outlined, 'Lihat Produk', 2),
                _buildMobileMenuItem(Icons.person_outline, 'Profil', 12),
              ],
              
              _buildMobileMenuItem(Icons.settings_outlined, 'Pengaturan', 7),
              const SizedBox(height: 24),
            ],
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
  // 1. LAYOUT MOBILE DENGAN BOTTOM NAVBAR DINAMIS
  // =========================================================
  Widget _buildMobileLayout() {
    // Tentukan item mana yang nyala di Bottom Navbar
    int bottomNavIndex = 4; // Default ke 'Lainnya'
    
    if (_role == 'KASIR') {
      if (_currentIndex == 0) bottomNavIndex = 0;
      else if (_currentIndex == 1) bottomNavIndex = 1;
      else if (_currentIndex == 4) bottomNavIndex = 2; // Transaksi ada di slot 3
      else if (_currentIndex == 8) bottomNavIndex = 3; // Shift ada di slot 4
    } else {
      if (_currentIndex == 0) bottomNavIndex = 0;
      else if (_currentIndex == 1) bottomNavIndex = 1;
      else if (_currentIndex == 2) bottomNavIndex = 2;
      else if (_currentIndex == 3) bottomNavIndex = 3;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        titleSpacing: 16,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppColors.border, height: 1)),
        title: Row(
          children: [
            const Icon(Icons.point_of_sale, color: AppColors.primaryEmerald, size: 28),
            const SizedBox(width: 12),
            _buildStoreSelector(isDesktop: false),
          ],
        ),
      ),
      body: _halaman[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border, width: 1))),
        child: BottomNavigationBar(
          currentIndex: bottomNavIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.card,
          selectedItemColor: AppColors.primaryEmerald,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          onTap: (index) {
            if (index == 4) {
              _tampilkanMenuLainnyaMobile();
              return;
            }
            
            // Logika tap bottom nav dinamis
            if (_role == 'KASIR') {
              if (index == 0) _gantiHalaman(0); // Home
              if (index == 1) _gantiHalaman(1); // Kasir
              if (index == 2) _gantiHalaman(4); // Transaksi
              if (index == 3) _gantiHalaman(8); // Shift
            } else {
              if (index == 0) _gantiHalaman(0); // Home
              if (index == 1) _gantiHalaman(1); // Kasir
              if (index == 2) _gantiHalaman(2); // Produk
              if (index == 3) _gantiHalaman(3); // Laporan
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
  // 2. LAYOUT DESKTOP DENGAN SIDEBAR DINAMIS
  // =========================================================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: AppColors.card,
              border: Border(right: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primaryEmerald, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.point_of_sale, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('SMART KASIR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive, letterSpacing: 1)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 8, top: 8),
                        child: Text('MENU UTAMA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                      ),
                      
                      _buildSidebarItem(Icons.dashboard, 'Dashboard', 0),
                      _buildSidebarItem(Icons.shopping_cart, 'Kasir', 1),
                      
                      if (_role == 'OWNER' || _role == 'MANAGER') 
                        _buildSidebarItem(Icons.inventory_2, 'Produk', 2),
                        
                      if (_role == 'KASIR')
                        _buildSidebarItem(Icons.inventory_2, 'Lihat Produk', 2),

                      _buildSidebarItem(Icons.receipt_long, 'Transaksi', 4),
                      
                      if (_role == 'OWNER' || _role == 'MANAGER') 
                        _buildSidebarItem(Icons.analytics, 'Laporan', 3),
                        
                      _buildSidebarItem(Icons.swap_horiz, 'Shift Kasir', 8),

                      const Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 8, top: 24),
                        child: Text('MANAJEMEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                      ),
                      
                      if (_role == 'OWNER') 
                        _buildSidebarItem(Icons.storefront, 'Cabang', 5),
                        
                      if (_role == 'OWNER' || _role == 'MANAGER') ...[
                        _buildSidebarItem(Icons.people_outline, 'Karyawan', 6),
                        _buildSidebarItem(Icons.payment, 'Pembayaran', 9),
                      ],
                      
                      if (_role == 'OWNER') ...[
                        _buildSidebarItem(Icons.card_giftcard, 'Referral', 10),
                        _buildSidebarItem(Icons.diamond_outlined, 'Langganan', 11),
                      ],
                      
                      if (_role == 'KASIR')
                        _buildSidebarItem(Icons.person, 'Profil', 12),
                        
                      _buildSidebarItem(Icons.settings_outlined, 'Pengaturan', 7),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStoreSelector(isDesktop: true),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryEmerald.withOpacity(0.1),
                            child: const Icon(Icons.person, size: 20, color: AppColors.primaryEmerald),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_namaPetugas, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                              Text(_role, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(child: _halaman[_currentIndex])
              ],
            ),
          )
        ],
      ),
    );
  }

  // WIDGET BANTUAN (TIDAK BERUBAH)
  Widget _buildStoreSelector({bool isDesktop = false}) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      onSelected: (val) {
        if (val != 'tambah') setState(() => _tokoAktif = val);
      },
      itemBuilder: (ctx) => [
        ..._daftarToko.map((toko) => PopupMenuItem(value: toko, child: Text(toko))),
        if (_role == 'OWNER') ...[
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'tambah', child: Text('+ Tambah Cabang', style: TextStyle(color: AppColors.textSecondary))),
        ]
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isDesktop ? AppColors.background : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          const Icon(Icons.storefront, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(_tokoAktif, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, int indexTarget) {
    bool isSelected = _currentIndex == indexTarget;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _gantiHalaman(indexTarget),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isSelected ? AppColors.navyActive : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) => constraints.maxWidth > 800 ? _buildDesktopLayout() : _buildMobileLayout());
  }
}
