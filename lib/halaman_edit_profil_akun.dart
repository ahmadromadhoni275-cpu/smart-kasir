import 'dart:ui';
import 'package:flutter/material.dart';

import 'tema.dart';
import 'models/profile_model.dart';
import 'core/services/profile_service.dart';

class HalamanEditProfilAkun extends StatefulWidget {
  final ProfileModel? profileData;
  const HalamanEditProfilAkun({super.key, this.profileData});

  @override
  State<HalamanEditProfilAkun> createState() => _HalamanEditProfilAkunState();
}

class _HalamanEditProfilAkunState extends State<HalamanEditProfilAkun> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.profileData != null) {
      _nameCtrl.text = widget.profileData!.name;
      _emailCtrl.text = widget.profileData!.email;
      _phoneCtrl.text = widget.profileData!.phone;
    }
  }

  void _showNotif(String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ProfileService.updateProfile({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(children: [Icon(Icons.check_circle, color: AppColors.primaryEmerald), SizedBox(width: 8), Text('Berhasil', style: TextStyle(color: AppColors.primaryEmerald))]),
            content: const Text('Profil akun Anda berhasil diperbarui.'),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  Navigator.pop(ctx); // Tutup dialog
                  Navigator.pop(context, true); // Kembali ke profil
                },
                child: const Text('Oke', style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        );
      }
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
        title: const Text('Edit Profil', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
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
          
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 24, left: 16, right: 16, bottom: 40),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))]),
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
                            Text('Informasi Pribadi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.navyActive)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nama Lengkap *', 
                            filled: true, fillColor: Colors.white.withOpacity(0.8), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                            prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary)
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Alamat Email', 
                            filled: true, fillColor: Colors.white.withOpacity(0.8), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary)
                          ),
                          validator: (val) {
                            if (val != null && val.isNotEmpty && !val.contains('@')) return 'Format email tidak valid';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Nomor Telepon / WhatsApp', 
                            filled: true, fillColor: Colors.white.withOpacity(0.8), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary)
                          ),
                          validator: (val) {
                            if (val != null && val.isNotEmpty && !RegExp(r'^[0-9+]+$').hasMatch(val)) return 'Hanya boleh berisi angka';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // CATATAN KEBIJAKAN
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.smartBlue.withOpacity(0.2))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.smartBlue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text('Jika Anda mengubah Email atau Nomor Telepon, Anda mungkin diminta untuk melakukan verifikasi ulang saat login berikutnya demi keamanan.', style: TextStyle(fontSize: 11, color: Colors.blue.shade900, height: 1.4))),
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
                              : const Text('SIMPAN PERUBAHAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
