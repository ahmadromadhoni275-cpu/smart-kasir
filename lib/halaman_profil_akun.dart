import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart';
import 'core/services/profile_service.dart';

import 'halaman_edit_profil_akun.dart';
import 'halaman_ganti_kata_sandi.dart';
import 'halaman_login.dart'; // Aktifkan dan sesuaikan dengan halaman login Anda

class HalamanProfilAkun extends StatefulWidget {
  const HalamanProfilAkun({super.key});

  @override
  State<HalamanProfilAkun> createState() => _HalamanProfilAkunState();
}

class _HalamanProfilAkunState extends State<HalamanProfilAkun> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String _role = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _role = prefs.getString('role') ?? 'KASIR';
      
      final data = await ProfileService.getProfile();
      setState(() => _profileData = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _konfirmasiKeluar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini? Pastikan shift kasir Anda sudah ditutup jika diperlukan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Panggil API Logout untuk menghancurkan token di server
      await ProfileService.logout();
      
      // 2. Hapus sesi lokal
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // 3. Navigasi ke Halaman Login (Hapus semua riwayat routing)
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Akun', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // KARTU IDENTITAS
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40, 
                      backgroundColor: AppColors.primaryEmerald.withOpacity(0.1), 
                      child: Text(
                        (_profileData?['name'] ?? 'U').toString().substring(0, 1).toUpperCase(), 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)
                      )
                    ),
                    const SizedBox(height: 16),
                    Text(_profileData?['name'] ?? 'Nama Pengguna', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    const SizedBox(height: 4),
                    Text(_profileData?['email'] ?? 'Belum ada email', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    Text(_profileData?['phone'] ?? 'Belum ada nomor HP', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text('Peran: $_role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text('Pengaturan Keamanan & Data', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
              ),
              _buildMenuTile(Icons.edit_outlined, 'Edit Profil', 'Ubah nama, email, atau nomor telepon', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanEditProfilAkun(profileData: _profileData))).then((_) => _fetchData());
              }),
              _buildMenuTile(Icons.lock_outline, 'Ganti Kata Sandi', 'Perbarui kata sandi untuk keamanan', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanGantiKataSandi()));
              }),
              
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0, 
                  padding: const EdgeInsets.symmetric(vertical: 16), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade200))
                ),
                onPressed: _konfirmasiKeluar,
                icon: const Icon(Icons.logout),
                label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.navyActive)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
