import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart'; 
import 'halaman_pengaturan.dart';
import 'halaman_printer.dart';
import 'halaman_pelanggan.dart';
import 'halaman_produk.dart';
import 'halaman_login.dart';
import 'halaman_metode_pembayaran.dart';
import 'core/services/shift_service.dart';

class HalamanMenu extends StatefulWidget {
  const HalamanMenu({super.key});

  @override
  State<HalamanMenu> createState() => _HalamanMenuState();
}

class _HalamanMenuState extends State<HalamanMenu> {
  String _namaToko = 'Memuat...';
  String _username = 'Admin';
  String _role = 'kasir';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaToko = prefs.getString('nama_toko') ?? 'Smart Kasir';
      _username = prefs.getString('username') ?? 'Owner';
      _role = (prefs.getString('role') ?? 'KASIR').toUpperCase();
      _isLoading = false;
    });
  }

  // --- 4. PROTEKSI LOGOUT KASIR JIKA SHIFT MASIH AKTIF ---
  void _logout() async {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));

    try {
      final shiftData = await ShiftService().getCurrentShift();
      
      if (mounted) Navigator.pop(context); // Tutup loading

      if (shiftData != null && shiftData.status == 'OPEN') {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Shift Masih Aktif!', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
            content: const Text('Anda tidak bisa keluar akun saat shift belum ditutup. Harap tutup shift Anda terlebih dahulu.', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti', style: TextStyle(color: Colors.grey))),
            ],
          ),
        );
        return; // Hentikan proses logout
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }

    if (!mounted) return;
    
    // Jika tidak ada shift aktif, tampilkan konfirmasi logout reguler
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Konfirmasi Keluar', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HalamanLogin()), (route) => false);
              }
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.cardSolid,
                  boxShadow: [BoxShadow(color: AppColors.shadowBlue, blurRadius: 20, offset: Offset(0, 5))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.storefront, color: AppColors.smartBlue, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_namaToko, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text('$_username ($_role)', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Manajemen Toko', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 12),
                    
                    if (_role == 'OWNER' || _role == 'MANAGER')
                      _buildMenuItem(Icons.storefront, 'Pengaturan Toko', AppColors.goldPremium, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanPengaturan()));
                      }),

                    if (_role == 'OWNER' || _role == 'MANAGER')
                      _buildMenuItem(Icons.payment, 'Metode Pembayaran', AppColors.smartBlue, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanMetodePembayaran()));
                      }),
                    
                    _buildMenuItem(Icons.people_outline, 'Data Pelanggan', AppColors.skyBlue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanPelanggan()));
                    }),
                    
                    if (_role == 'OWNER' || _role == 'MANAGER')
                      _buildMenuItem(Icons.inventory_2_outlined, 'Manajemen Produk', AppColors.primaryEmerald, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanProduk()));
                      }),
                    
                    const SizedBox(height: 24),
                    const Text('Perangkat & Sistem', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 12),
                    
                    _buildMenuItem(Icons.print_outlined, 'Pengaturan Printer', AppColors.navyActive, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanPrinter()));
                    }),

                    const SizedBox(height: 24),
                    _buildMenuItem(Icons.logout, 'Keluar (Logout)', AppColors.error, _logout, isLogout: true),
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
        color: AppColors.cardSolid,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent, 
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16), 
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isLogout ? AppColors.error : AppColors.textPrimary)),
                ),
                if (!isLogout) const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
