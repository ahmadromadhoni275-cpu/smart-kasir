import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart'; // Import tema eksklusif
import 'halaman_pengaturan.dart';
import 'halaman_printer.dart';
import 'halaman_pelanggan.dart';
import 'halaman_produk.dart'; // <-- TAMBAHAN: Import halaman produk
import 'halaman_login.dart';

class HalamanMenu extends StatefulWidget {
  const HalamanMenu({super.key});

  @override
  State<HalamanMenu> createState() => _HalamanMenuState();
}

class _HalamanMenuState extends State<HalamanMenu> {
  String _namaToko = 'Memuat...';
  String _username = 'Admin';
  String _role = 'kasir';

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaToko = prefs.getString('nama_toko') ?? 'Smart Kasir';
      _username = prefs.getString('username') ?? 'Admin';
      _role = prefs.getString('role') ?? 'kasir';
    });
  }

  void _logout() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- HEADER PROFIL ---
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.storefront, color: AppColors.teal, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_namaToko, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 12, color: AppColors.slateGray),
                              const SizedBox(width: 4),
                              Text('$_username ($_role)', style: const TextStyle(fontSize: 13, color: AppColors.slateGray)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- DAFTAR MENU ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Manajemen Toko', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateGray, fontSize: 13)),
                    const SizedBox(height: 10),
                    
                    _buildMenuItem(Icons.store, 'Pengaturan Toko & Pembayaran', AppColors.premiumGold, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanPengaturan()));
                    }),
                    _buildMenuItem(Icons.people, 'Data Pelanggan', AppColors.smartBlue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanPelanggan()));
                    }),
                    
                    // <-- TAMBAHAN: Menu Manajemen Produk -->
                    _buildMenuItem(Icons.inventory_2_outlined, 'Manajemen Produk', AppColors.emerald, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanProduk()));
                    }),
                    
                    const SizedBox(height: 20),
                    const Text('Perangkat & Sistem', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slateGray, fontSize: 13)),
                    const SizedBox(height: 10),
                    
                    _buildMenuItem(Icons.print, 'Pengaturan Printer', AppColors.teal, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanPrinter()));
                    }),

                    const SizedBox(height: 20),
                    _buildMenuItem(Icons.logout, 'Keluar (Logout)', AppColors.red, _logout, isLogout: true),
                    const SizedBox(height: 40),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color color, VoidCallback onTap, {bool isLogout = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent, 
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16), 
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isLogout ? AppColors.red : AppColors.darkText)),
                ),
                if (!isLogout) const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.slateGray),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
