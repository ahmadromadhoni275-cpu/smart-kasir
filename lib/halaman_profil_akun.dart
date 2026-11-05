import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';
import 'models/profile_model.dart';
import 'core/services/profile_service.dart';
import 'halaman_edit_profil_akun.dart';
import 'halaman_ganti_kata_sandi.dart';
import 'halaman_daftar_tiket_bantuan.dart'; 

class HalamanProfilAkun extends StatefulWidget {
  const HalamanProfilAkun({super.key});

  @override
  State<HalamanProfilAkun> createState() => _HalamanProfilAkunState();
}

class _HalamanProfilAkunState extends State<HalamanProfilAkun> {
  bool _isLoading = true;
  ProfileModel? _profileData;
  String _role = 'KASIR';

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
      if (mounted) setState(() => _profileData = data);
    } catch (e) {
      debugPrint("Error load profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _konfirmasiKeluar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 8),
            Text('Keluar Aplikasi', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navyActive)),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar? Pastikan shift kasir Anda sudah ditutup.', style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        showDialog(
          context: context, 
          barrierDismissible: false, 
          builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        );
      }
      
      await ProfileService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil Akun', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd])),
          ),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 40),
                children: [
                  // --- KARTU IDENTITAS ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primaryEmerald.withOpacity(0.3), width: 2)),
                              child: CircleAvatar(
                                radius: 45, 
                                backgroundColor: AppColors.primaryEmerald.withOpacity(0.15), 
                                child: Text(
                                  (_profileData?.name ?? 'U').substring(0, 1).toUpperCase(), 
                                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.primaryEmerald)
                                )
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(_profileData?.name ?? 'Nama Pengguna', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navyActive)),
                            const SizedBox(height: 8),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(_profileData?.email ?? '-', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(_profileData?.phone ?? '-', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.smartBlue.withOpacity(0.3))),
                              child: Text('Akses: $_role', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.smartBlue)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- SECTION PENGATURAN ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text('Pengaturan & Keamanan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  _buildGlassMenu(Icons.edit_outlined, 'Edit Profil', 'Ubah nama, email, atau kontak', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanEditProfilAkun(profileData: _profileData))).then((_) => _fetchData());
                  }),
                  _buildGlassMenu(Icons.lock_outline, 'Ganti Kata Sandi', 'Perbarui sandi untuk keamanan ekstra', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanGantiKataSandi()));
                  }),
                  
                  const SizedBox(height: 16),

                  // --- SECTION BANTUAN ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text('Bantuan & Dukungan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                  ),
                  _buildGlassMenu(Icons.headset_mic_outlined, 'Tiket Bantuan Saya', 'Pantau status kendala operasional', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanDaftarTiket()));
                  }),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.7), 
                        foregroundColor: AppColors.error, 
                        elevation: 0, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 1.5))
                      ),
                      onPressed: _konfirmasiKeluar,
                      icon: const Icon(Icons.logout),
                      label: const Text('KELUAR DARI AKUN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  )
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildGlassMenu(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(color: AppColors.navyActive.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), 
              child: Icon(icon, color: AppColors.navyActive)
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
