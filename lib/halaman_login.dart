import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';
import 'halaman_registrasi.dart';
import 'halaman_beranda.dart'; 

class HalamanLogin extends StatefulWidget {
  const HalamanLogin({super.key});

  @override
  State<HalamanLogin> createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
  // Ganti dengan URL API Anda (Codespaces URL atau domain)
  final String domainUrl = 'https://smartkasir.shop/api'; 
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _prosesLogin() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showNotif('Email dan Password wajib diisi', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$domainUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
        }),
      );

      final resData = json.decode(response.body);

      if (response.statusCode == 200) {
        final data = resData['data'];
        final List stores = data['stores'] ?? [];
        final String token = resData['token'] ?? '';

        if (stores.isEmpty) {
          _showNotif('Anda tidak memiliki akses ke toko mana pun.', AppColors.error);
          setState(() => _isLoading = false);
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        
        // 1. SIMPAN IDENTITAS UNIVERSAL & JWT TOKEN
        await prefs.setString('jwt_token', token);
        await prefs.setInt('user_id', int.parse(data['user_id'].toString()));
        await prefs.setString('username', data['name']);

        // 2. CEK JUMLAH CABANG UNTUK ROUTING
        if (stores.length == 1) {
          // ALUR AUTO (Hanya punya 1 cabang)
          final store = stores[0];
          await prefs.setInt('store_id', int.parse(store['store_id'].toString()));
          await prefs.setInt('business_id', int.parse(store['business_id'].toString()));
          await prefs.setString('nama_toko', store['store_name']);
          await prefs.setString('role', store['role']); // OWNER, MANAGER, KASIR
          await prefs.setBool('is_logged_in', true);

          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HalamanBeranda()));
          }
        } else {
          // ALUR PILIH CABANG (> 1 Cabang)
          await prefs.setString('daftar_cabang', json.encode(stores));
          
          if (mounted) {
            // Arahkan ke halaman pilih cabang
            // Pastikan Anda sudah mendaftarkan '/pilih_cabang' di routes MaterialApp (main.dart)
            Navigator.pushReplacementNamed(context, '/pilih_cabang');
          }
        }
      } else {
        // Tangkap pesan error dari CI4 (baik format custom resData['message'] maupun bawaan CI4 resData['messages']['error'])
        String errorMsg = resData['message'] ?? (resData['messages'] != null ? resData['messages']['error'] : 'Login Gagal');
        _showNotif(errorMsg, AppColors.error);
      }
    } catch (e) {
      _showNotif('Koneksi ke server gagal', AppColors.error);
    }

    setState(() => _isLoading = false);
  }

  void _showNotif(String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesan, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450), // Maksimal lebar untuk Web/Tablet
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: AppColors.navyActive.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo & Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.point_of_sale, size: 40, color: AppColors.primaryEmerald),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(child: Text('Masuk ke Smart Kasir', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                    const SizedBox(height: 8),
                    const Center(child: Text('Kelola bisnis Anda dengan mudah dan cerdas', style: TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                    const SizedBox(height: 32),

                    // Form Email
                    const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'nama@email.com',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Password
                    const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscureText,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Masukkan password',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () { _showNotif('Fitur Reset Password segera hadir', AppColors.goldPremium); },
                        child: const Text('Lupa Password?', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tombol Login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _prosesLogin,
                        child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Navigasi ke Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Belum punya akun? ', style: TextStyle(color: AppColors.textSecondary)),
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanRegistrasi())),
                          child: const Text('Daftar Sekarang', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
