import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; 
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';
import 'halaman_registrasi.dart';
import 'kerangka_navigasi.dart'; 
import 'core/network/api_client.dart'; 
import 'core/services/fcm_service.dart';

class HalamanLogin extends StatefulWidget {
  const HalamanLogin({super.key});

  @override
  State<HalamanLogin> createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
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
      final response = await ApiClient().dio.post(
        '/login',
        data: {
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
        },
      );

      final resData = response.data;

      if (response.statusCode == 200 && resData['status'] == 'success') {
        final data = resData['data'];
        final List stores = data['stores'] ?? [];
        final String token = resData['token'] ?? '';

        if (stores.isEmpty) {
          _showNotif('Anda tidak memiliki akses ke toko mana pun.', AppColors.error);
          setState(() => _isLoading = false);
          return;
        }

        final prefs = await SharedPreferences.getInstance();
        
        await prefs.setString('jwt_token', token);
        await prefs.setInt('user_id', int.parse(data['user_id'].toString()));
        await prefs.setString('username', data['name']);

        await FcmService.registerDeviceToken();

        if (stores.length == 1) {
          final store = stores[0];
          await prefs.setInt('store_id', int.parse(store['store_id'].toString()));
          await prefs.setInt('business_id', int.parse(store['business_id'].toString()));
          await prefs.setString('nama_toko', store['store_name']);
          await prefs.setString('role', store['role']); 
          await prefs.setBool('is_logged_in', true);

          if (mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const KerangkaNavigasi()));
          }
        } else {
          await prefs.setString('daftar_cabang', json.encode(stores));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/pilih_cabang');
          }
        }
      } else {
        _showNotif(resData['message'] ?? 'Login Gagal', AppColors.error);
      }
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String errorMsg = 'Login Gagal';
      
      if (responseData != null && responseData is Map) {
        errorMsg = responseData['message'] ?? 
                  (responseData['messages'] != null ? responseData['messages']['error'] : 'Login Gagal');
      } else {
        errorMsg = e.message ?? 'Koneksi ke server gagal';
      }
      
      _showNotif(errorMsg, AppColors.error);
    } catch (e) {
      _showNotif('Terjadi kesalahan sistem: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      body: Stack(
        children: [
          // 1. Background Gradient Crystal UI
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd],
              ),
            ),
          ),
          
          // 2. Ornamen Blob Cahaya (Agar efek kaca terlihat menonjol)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.skyBlue),
            ).blurred(sigma: 80),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.smartBlue),
            ).blurred(sigma: 100),
          ),

          // 3. Form Glassmorphism
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450), 
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 24, offset: Offset(0, 8))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.glassBorder, width: 1.2),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Logo & Header
                              Center(
                                child: Image.asset(
                                  'assets/images/logo_smart_kasir.png',
                                  height: 100, // Silakan ubah angka ini untuk memperbesar/memperkecil logo
                                  fit: BoxFit.contain,
                                ),
                              ),

                              const SizedBox(height: 24),
                              const Center(
                                  child: Text('Smart Kasir',
                                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                              const SizedBox(height: 8),
                              const Center(
                                  child: Text('Masuk ke akun Anda untuk melanjutkan',
                                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                      textAlign: TextAlign.center)),
                              const SizedBox(height: 32),

                              // Form Email
                              TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Email atau Username',
                                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                                  filled: true,
                                  fillColor: AppColors.cardSolid, // Solid agar mudah dibaca di atas kaca
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.menuActiveStart, width: 1.5)),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Form Password
                              TextField(
                                controller: _passwordCtrl,
                                obscureText: _obscureText,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility,
                                        color: AppColors.textSecondary),
                                    onPressed: () => setState(() => _obscureText = !_obscureText),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.cardSolid,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.menuActiveStart, width: 1.5)),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _showNotif('Fitur Reset Password segera hadir', AppColors.goldPremium),
                                  child: const Text('Lupa Password?',
                                      style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tombol Login (Crystal Blue)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppColors.menuActiveStart, AppColors.menuActiveEnd]),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 12, offset: Offset(0, 5))],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: AppColors.textOnPrimary,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: _isLoading ? null : _prosesLogin,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
                                    onTap: () => Navigator.push(
                                        context, MaterialPageRoute(builder: (context) => const HalamanRegistrasi())),
                                    child: const Text('Daftar sekarang',
                                        style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold)),
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension pembantu untuk membuat blur efek dekoratif di latar belakang
extension BlurExtension on Widget {
  Widget blurred({double sigma = 10}) {
    return ImageFilterWidget(sigma: sigma, child: this);
  }
}

class ImageFilterWidget extends StatelessWidget {
  final double sigma;
  final Widget child;
  const ImageFilterWidget({super.key, required this.sigma, required this.child});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
