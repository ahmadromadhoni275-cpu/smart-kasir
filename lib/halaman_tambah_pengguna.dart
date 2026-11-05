import 'dart:ui';
import 'package:flutter/material.dart';

import 'tema.dart';
import 'core/services/user_service.dart';

class HalamanTambahPengguna extends StatefulWidget {
  const HalamanTambahPengguna({super.key});

  @override
  State<HalamanTambahPengguna> createState() => _HalamanTambahPenggunaState();
}

class _HalamanTambahPenggunaState extends State<HalamanTambahPengguna> {
  final UserService _userService = UserService();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  String _selectedRole = 'KASIR';
  bool _isLoading = false;

  void _showNotif(String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: warna,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    }
  }

  Future<void> _simpan() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      _showNotif('Nama dan Email wajib diisi!', Colors.orange.shade700);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _userService.inviteUser({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': _selectedRole,
      });
      _showNotif('Berhasil menambahkan karyawan!', AppColors.primaryEmerald);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tambah Karyawan Baru', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Stack(
        children: [
          // Background Gradient (Crystal UI)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd],
              ),
            ),
          ),
          
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 24, left: 16, right: 16, bottom: 40),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                  boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_pin, color: AppColors.navyActive, size: 20),
                            SizedBox(width: 8),
                            Text('Data Profil Karyawan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap', 
                            filled: true, fillColor: Colors.white.withOpacity(0.8), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                            prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary)
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Alamat Email', 
                            hintText: 'email@contoh.com', 
                            filled: true, fillColor: Colors.white.withOpacity(0.8), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary)
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        const Row(
                          children: [
                            Icon(Icons.admin_panel_settings, color: AppColors.navyActive, size: 20),
                            SizedBox(width: 8),
                            Text('Hak Akses & Peran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            filled: true, fillColor: Colors.white.withOpacity(0.8), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                            prefixIcon: const Icon(Icons.work_outline, color: AppColors.textSecondary)
                          ),
                          items: const [
                            DropdownMenuItem(value: 'KASIR', child: Text('Kasir (Transaksi & Shift)')),
                            DropdownMenuItem(value: 'MANAGER', child: Text('Manajer (Laporan & Produk)')),
                            DropdownMenuItem(value: 'OWNER', child: Text('Pemilik (Akses Penuh)')),
                          ],
                          onChanged: (val) => setState(() => _selectedRole = val!),
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.smartBlue.withOpacity(0.3))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.smartBlue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Karyawan baru akan mendapatkan kata sandi default yang dikirim ke email, atau dapat menggunakan sandi SmartKasir123! untuk login pertama kali.', style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.4))),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity, height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryEmerald, 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4, shadowColor: AppColors.primaryEmerald.withOpacity(0.5)
                            ),
                            onPressed: _isLoading ? null : _simpan,
                            child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                              : const Text('UNDANG KARYAWAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
