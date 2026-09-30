import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart'; 
import 'halaman_beranda.dart';
import 'halaman_kasir.dart';
import 'halaman_transaksi.dart';
import 'halaman_laporan.dart';
import 'halaman_login.dart'; 
import 'halaman_pengaturan.dart'; 
import 'halaman_printer.dart';
import 'halaman_pelanggan.dart';
import 'halaman_langganan.dart'; // Tambahkan import halaman langganan

class KerangkaNavigasiPremium extends StatefulWidget {
  const KerangkaNavigasiPremium({super.key});

  @override
  State<KerangkaNavigasiPremium> createState() => _KerangkaNavigasiPremiumState();
}

class _KerangkaNavigasiPremiumState extends State<KerangkaNavigasiPremium> {
  int _currentIndex = 0;
  String _userRole = 'kasir'; 
  String _namaPetugas = 'Admin';
  String _namaToko = 'Toko Sukses';

  final List<Widget> _halaman = [
    const HalamanBeranda(),
    const HalamanKasir(),
    const HalamanTransaksi(),
    const HalamanLaporan(),
  ];

  @override
  void initState() {
    super.initState();
    _muatDataUser();
  }

  Future<void> _muatDataUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'kasir';
      _namaPetugas = prefs.getString('username') ?? 'Admin';
      _namaToko = prefs.getString('nama_toko') ?? 'Smart Kasir';
    });
  }

  // ==========================================
  // FUNGSI LOGOUT (Dipakai di Navbar Atas & Bottom Sheet)
  // ==========================================
  void _prosesLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.slateGray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Hapus semua sesi
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HalamanLogin()),
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _tampilkanNotifBelumTersedia(String fitur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$fitur segera hadir!', style: const TextStyle(color: AppColors.white)),
      backgroundColor: AppColors.smartBlue,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
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
              Container(
                width: 50, height: 5, margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              ListTile(
                leading: const Icon(Icons.people_alt, color: AppColors.smartBlue),
                title: const Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanPelanggan()));
                },
              ),
              const Divider(thickness: 1, color: AppColors.lightGray),
              ListTile(
                leading: const Icon(Icons.settings, color: AppColors.slateGray),
                title: const Text('Pengaturan Toko', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanPengaturan()));
                },
              ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.manage_accounts, color: AppColors.slateGray),
                  title: const Text('Pengguna / Pegawai', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _tampilkanNotifBelumTersedia('Manajemen Pegawai');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.print, color: AppColors.slateGray),
                title: const Text('Printer Bluetooth', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanPrinter()));
                },
              ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.card_membership, color: AppColors.premiumGold),
                  title: const Text('Langganan Sistem', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanLangganan())); // <-- Arahkan ke Halaman Langganan
                  },
                ),
              const Divider(thickness: 1, color: AppColors.lightGray),
              ListTile(
                leading: const Icon(Icons.help_outline, color: AppColors.slateGray),
                title: const Text('Bantuan / Support', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _tampilkanNotifBelumTersedia('Pusat Bantuan');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.red),
                title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _prosesLogout(); 
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
      // NAVBAR ATAS (APPBAR) AKTIF
      // ==========================================
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        titleSpacing: 15,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.point_of_sale, color: AppColors.white, size: 22),
            ),
            const SizedBox(width: 8),
            // SEARCH BAR AKTIF
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
                    hintText: 'Cari di aplikasi...',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.white54),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (value) {
                    _tampilkanNotifBelumTersedia('Pencarian global "$value"');
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          // TOMBOL NOTIFIKASI AKTIF
          IconButton(
            icon: const Badge(
              backgroundColor: AppColors.premiumGold,
              child: Icon(Icons.notifications_none, color: AppColors.white, size: 24),
            ),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () {
              _tampilkanNotifBelumTersedia('Notifikasi');
            },
          ),
          // TOMBOL BANTUAN AKTIF
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.white, size: 24),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () {
              _tampilkanNotifBelumTersedia('Pusat Bantuan');
            },
          ),
          // PROFIL USER (BISA DI-KLIK UNTUK LOGOUT/PROFIL)
          InkWell(
            onTap: _prosesLogout, 
            child: Padding(
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
            ),
          )
        ],
      ),

      body: _halaman[_currentIndex],

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
            _buildNavItem(icon: Icons.more_vert, label: 'Menu', index: 4, isMenu: true),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, bool isMenu = false}) {
    bool isSelected = _currentIndex == index && !isMenu;
    return InkWell(
      onTap: () {
        if (isMenu) {
          _tampilkanMenuLainnya(); 
        } else {
          setState(() => _currentIndex = index); 
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? AppColors.teal : AppColors.slateGray, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.teal : AppColors.slateGray)),
        ],
      ),
    );
  }
}
