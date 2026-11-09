import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tema.dart';
import 'halaman_otp.dart'; 

class HalamanRegistrasi extends StatefulWidget {
  const HalamanRegistrasi({super.key});

  @override
  State<HalamanRegistrasi> createState() => _HalamanRegistrasiState();
}

class _HalamanRegistrasiState extends State<HalamanRegistrasi> {
  final String domainUrl = 'https://smartkasir.shop/api'; 
  
  final TextEditingController _namaCtrl = TextEditingController();
  final TextEditingController _bisnisCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _referralCtrl = TextEditingController(); 
  
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _prosesDaftar() async {
    if (_namaCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty || _bisnisCtrl.text.isEmpty) {
      _showNotif('Harap lengkapi semua form wajib', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$domainUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _namaCtrl.text,
          'business_name': _bisnisCtrl.text,
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text,
          'password': _passwordCtrl.text,
          'referral_code': _referralCtrl.text.trim(), 
        }),
      );

      final resData = json.decode(response.body);

      if (response.statusCode == 201) {
        _showNotif('Cek OTP Anda: ${resData['dev_otp_code']}', AppColors.greenAccent);
        
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HalamanOTP(email: _emailCtrl.text.trim())));
        }
      } else {
        _showNotif(resData['messages']?['error'] ?? 'Pendaftaran Gagal', AppColors.error);
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

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscureText : false,
        keyboardType: type,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          suffixIcon: isPassword ? IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ) : null,
          filled: true,
          fillColor: AppColors.cardSolid, // Solid agar menonjol dari latar kaca
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.menuActiveStart, width: 1.5)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Stack(
        children: [
          // Background Gradient Crystal UI
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd],
              ),
            ),
          ),
          
          // Ornamen Blob Cahaya
          Positioned(
            top: 50,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(width: 250, height: 250, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.skyBlue)),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(width: 300, height: 300, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.smartBlue)),
            ),
          ),

          // Form Glassmorphism
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 24),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              
                              // IMPLEMENTASI LOGO BARU
                              Image.asset(
                                'assets/images/logo_smart_kasir.png',
                                height: 80, 
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 16),
                              // -------------------------

                              const Text('Buat Akun Baru', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              const SizedBox(height: 8),
                              const Text('Mulai kelola kasir dan inventori bisnis Anda dari sekarang.', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                              const SizedBox(height: 32),

                              _buildTextField('Nama Lengkap', Icons.person_outline, _namaCtrl),
                              _buildTextField('Nama Bisnis/Toko', Icons.storefront_outlined, _bisnisCtrl),
                              _buildTextField('Email', Icons.email_outlined, _emailCtrl, type: TextInputType.emailAddress),
                              _buildTextField('Nomor WhatsApp', Icons.phone_outlined, _phoneCtrl, type: TextInputType.phone),
                              _buildTextField('Buat Password', Icons.lock_outline, _passwordCtrl, isPassword: true),
                              _buildTextField('Kode Referral (Opsional)', Icons.card_giftcard, _referralCtrl),

                              const SizedBox(height: 16),
                              
                              // Tombol Daftar (Crystal Blue)
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
                                  onPressed: _isLoading ? null : _prosesDaftar,
                                  child: _isLoading 
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              
                              const SizedBox(height: 24), // Jarak antara tombol dan link login

                              // LINK LOGIN DI SINI
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Sudah punya akun?',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Karena halaman ini biasanya dibuka dari Halaman Login, 
                                      // cukup gunakan pop() untuk kembali ke layar sebelumnya.
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Masuk di sini',
                                      style: TextStyle(
                                        color: AppColors.smartBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
