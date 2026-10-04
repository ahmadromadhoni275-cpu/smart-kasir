import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tema.dart';
import 'halaman_otp.dart'; // <-- Import halaman OTP

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
  final TextEditingController _referralCtrl = TextEditingController(); // <-- Controller Referral
  
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
          'referral_code': _referralCtrl.text.trim(), // <-- Kirim ke server
        }),
      );

      final resData = json.decode(response.body);

      if (response.statusCode == 201) {
        // Tampilkan OTP di notif HANYA UNTUK TESTING. Di production, OTP dikirim via WA/Email.
        _showNotif('Cek OTP Anda: ${resData['dev_otp_code']}', AppColors.greenAccent);
        
        if (mounted) {
          // Arahkan ke halaman verifikasi OTP
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

  Widget _buildTextField(String label, String hint, IconData icon, TextEditingController controller, {bool isPassword = false, TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
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
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
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
                    const Text('Buat Akun Baru', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text('Mulai kelola kasir dan inventori bisnis Anda dari sekarang.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 32),

                    _buildTextField('Nama Lengkap', 'Masukkan nama Anda', Icons.person_outline, _namaCtrl),
                    _buildTextField('Nama Bisnis/Toko', 'Misal: Kedai Kopi Senja', Icons.storefront_outlined, _bisnisCtrl),
                    _buildTextField('Email', 'nama@email.com', Icons.email_outlined, _emailCtrl, type: TextInputType.emailAddress),
                    _buildTextField('Nomor WhatsApp', '0812xxxxxx', Icons.phone_outlined, _phoneCtrl, type: TextInputType.phone),
                    _buildTextField('Password', 'Buat password aman', Icons.lock_outline, _passwordCtrl, isPassword: true),
                    
                    // Input Referral Code Opsional
                    _buildTextField('Kode Referral (Opsional)', 'Masukkan kode undangan', Icons.card_giftcard, _referralCtrl),

                    const SizedBox(height: 16),
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
                        onPressed: _isLoading ? null : _prosesDaftar,
                        child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
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
