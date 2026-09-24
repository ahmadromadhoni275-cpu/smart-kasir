import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart'; // Pastikan file tema.dart dari panduan sebelumnya sudah ada

// Halaman sementara untuk didemonstrasikan di Kerangka
import 'halaman_beranda.dart'; // Ganti dengan import halaman Anda
import 'halaman_kasir.dart';
import 'halaman_transaksi.dart';
import 'halaman_laporan.dart';

class KerangkaNavigasiPremium extends StatefulWidget {
  const KerangkaNavigasiPremium({super.key});

  @override
  State<KerangkaNavigasiPremium> createState() => _KerangkaNavigasiPremiumState();
}

class _KerangkaNavigasiPremiumState extends State<KerangkaNavigasiPremium> {
  int _currentIndex = 0;
  String _userRole = 'kasir'; // Default role
  String _namaPetugas = 'Admin';
  String _namaToko = 'Toko Sukses';

  // Daftar halaman yang akan ditampilkan berdasarkan index Navbar Bawah
  final List<Widget> _halaman = [
    const Center(child: Text('Halaman Dashboard', style: TextStyle(fontSize: 20))), // Index 0
    const Center(child: Text('Halaman Kasir', style: TextStyle(fontSize: 20))),     // Index 1
    const Center(child: Text('Halaman Transaksi', style: TextStyle(fontSize: 20))), // Index 2
    const Center(child: Text('Halaman Laporan', style: TextStyle(fontSize: 20))),   // Index 3
    // Index 4 (Menu) tidak butuh halaman karena akan memunculkan BottomSheet
  ];

  @override
  void initState() {
    super.initState();
    _muatDataUser();
  }

  // Mengambil role dan data user dari memori lokal (SharedPreferences)
  Future<void> _muatDataUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'kasir';
      _namaPetugas = prefs.getString('username') ?? 'Admin';
      _namaToko = prefs.getString('nama_toko') ?? 'Smart Kasir';
    });
  }

  // ==========================================
  // FUNGSI MEMUNCULKAN MENU LAINNYA (BOTTOM SHEET)
  // ==========================================
  void _tampilkanMenuLainnya() {
    bool isAdmin = _userRole == 'admin' || _userRole == 'superadmin';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 15, bottom: 20),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Garis handle atas (Indikator bisa di-swipe turun)
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.bottom(15),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              
              ListTile(
                leading: const Icon(Icons.people_alt, color: AppColors.smartBlue),
                title: const Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan navigasi ke Halaman Pelanggan
                },
              ),
              
              const Divider(thickness: 1, color: AppColors.lightGray),
              
              ListTile(
                leading: const Icon(Icons.settings, color: AppColors.slateGray),
                title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan navigasi ke Halaman Pengaturan
                },
              ),

              // TAMPIL HANYA JIKA ADMIN
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.manage_accounts, color: AppColors.slateGray),
                  title: const Text('Pengguna / Pegawai', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    // Tambahkan navigasi ke Halaman Pengguna
                  },
                ),

              ListTile(
                leading: const Icon(Icons.print, color: AppColors.slateGray),
                title: const Text('Printer Bluetooth', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan navigasi ke Halaman Printer
                },
              ),

              ListTile(
                leading: const Icon(Icons.security, color: AppColors.slateGray),
                title: const Text('Keamanan', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan navigasi ke Halaman Keamanan
                },
              ),

              // TAMPIL HANYA JIKA ADMIN
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.card_membership, color: AppColors.premiumGold),
                  title: const Text('Langganan Sistem', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    // Tambahkan navigasi ke Halaman Langganan
                  },
                ),
              
              const Divider(thickness: 1, color: AppColors.lightGray),

              ListTile(
                leading: const Icon(Icons.help_outline, color: AppColors.slateGray),
                title: const Text('Bantuan / Support', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan navigasi ke Halaman Bantuan
                },
              ),

              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.red),
                title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // Tambahkan fungsi Logout (Hapus SharedPreferences)
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      // ==========================================
      // NAVBAR ATAS (APPBAR)
      // Logo | Search | Notifikasi | Bantuan | Profil
      // ==========================================
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        titleSpacing: 15,
        title: Row(
          children: [
            // 1. LOGO
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.point_of_sale, color: AppColors.white, size: 22),
            ),
            const SizedBox(width: 8),
            // 2. SEARCH BAR (Fleksibel mengisi ruang kosong)
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.darkBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  style: const TextStyle(color: AppColors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Cari produk, transaksi...',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (value) {
                    // Aksi pencarian global
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          // 3. NOTIFIKASI
          IconButton(
            icon: const Badge(
              backgroundColor: AppColors.premiumGold,
              child: Icon(Icons.notifications_none, color: AppColors.white, size: 24),
            ),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () {
              // Navigasi Notifikasi
            },
          ),
          // 4. BANTUAN
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.white, size: 24),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () {
              // Navigasi Bantuan
            },
          ),
          // 5. PROFIL USER
          Padding(
            padding: const EdgeInsets.only(right: 15, left: 5),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.slateGray,
                  child: Icon(Icons.person, size: 18, color: AppColors.white),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_namaPetugas, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white)),
                    Text(_namaToko, style: TextStyle(fontSize: 9, color: AppColors.white.withOpacity(0.7))),
                  ],
                ),
              ],
            ),
          )
        ],
      ),

      body: _halaman[_currentIndex],

      // ==========================================
      // NAVBAR BAWAH (BOTTOM APP BAR)
      // Dashboard | Kasir | Transaksi | Laporan | ⋮ Menu
      // ==========================================
      bottomNavigationBar: Container(
        height: 65,
        decoration: const BoxDecoration(
          color: AppColors.deepNavy,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
            _buildNavItem(icon: Icons.point_of_sale, label: 'Kasir', index: 1),
            _buildNavItem(icon: Icons.receipt_long, label: 'Transaksi', index: 2),
            _buildNavItem(icon: Icons.analytics, label: 'Laporan', index: 3),
            // Menu ke-5 tidak pindah halaman, tapi buka BottomSheet
            _buildNavItem(icon: Icons.more_vert, label: 'Menu', index: 4, isMenu: true),
          ],
        ),
      ),
    );
  }

  // Fungsi pembentuk tombol Navbar Bawah
  Widget _buildNavItem({required IconData icon, required String label, required int index, bool isMenu = false}) {
    bool isSelected = _currentIndex == index && !isMenu; // Menu tidak punya state aktif (selalu slateGray)
    
    return InkWell(
      onTap: () {
        if (isMenu) {
          _tampilkanMenuLainnya(); // Buka pop-up
        } else {
          setState(() => _currentIndex = index); // Pindah halaman
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.teal : AppColors.slateGray,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.teal : AppColors.slateGray,
            ),
          )
        ],
      ),
    );
  }
}
