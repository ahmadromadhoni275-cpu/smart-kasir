import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tema.dart'; // Import tema eksklusif
import 'halaman_login.dart'; // Arahkan kembali ke login setelah sukses

class HalamanRegistrasi extends StatefulWidget {
  const HalamanRegistrasi({super.key});

  @override
  State<HalamanRegistrasi> createState() => _HalamanRegistrasiState();
}

class _HalamanRegistrasiState extends State<HalamanRegistrasi> {
  final String domainUrl = 'https://smartkasir.shop';

  final TextEditingController _tokoCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _waCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _konfirmasiCtrl = TextEditingController();
  final TextEditingController _referralCtrl = TextEditingController();

  bool _isObscure = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  Future<void> _prosesDaftar() async {
    // Validasi form dasar
    if (_tokoCtrl.text.isEmpty || _usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _tampilkanNotif('Data Belum Lengkap', 'Nama Toko, Username, dan Password wajib diisi.', AppColors.premiumGold);
      return;
    }

    if (_passwordCtrl.text != _konfirmasiCtrl.text) {
      _tampilkanNotif('Password Tidak Cocok', 'Pastikan konfirmasi password sama persis.', AppColors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$domainUrl/api/registrasi'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama_toko': _tokoCtrl.text,
          'username': _usernameCtrl.text.replaceAll(' ', ''), // Hapus spasi untuk username
          'no_wa': _waCtrl.text,
          'email': _emailCtrl.text,
          'password': _passwordCtrl.text,
          'referral_code': _referralCtrl.text.trim().toUpperCase(),
        }),
      );

      final resData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _tampilkanNotif('Berhasil!', resData['message'] ?? 'Registrasi berhasil.', AppColors.emerald);
        
        // Jeda sebentar lalu arahkan ke halaman login
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HalamanLogin()));
        }
      } else {
        _tampilkanNotif('Pendaftaran Gagal', resData['message'] ?? 'Terjadi kesalahan.', AppColors.red);
      }
    } catch (e) {
      _tampilkanNotif('Error Jaringan', 'Gagal menghubungi server: $e', AppColors.red);
    }

    setState(() => _isLoading = false);
  }

  void _tampilkanNotif(String judul, String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(warna == AppColors.emerald ? Icons.check_circle : Icons.error_outline, color: AppColors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
                  Text(pesan, style: const TextStyle(fontSize: 12, color: AppColors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER DEEP NAVY ---
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.deepNavy,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_back, color: AppColors.white, size: 20),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Mulai Bisnis Anda', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.white)),
                        const SizedBox(height: 5),
                        Text('Daftarkan toko Anda dan nikmati fitur Smart Kasir Pro secara gratis (Trial).', style: TextStyle(fontSize: 13, color: AppColors.white.withOpacity(0.8), height: 1.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- KARTU FORMULIR REGISTRASI ---
            Transform.translate(
              offset: const Offset(0, -60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                    const SizedBox(height: 15),
                    _buildPremiumTextField('Nama Bisnis / Toko', Icons.store, _tokoCtrl),
                    
                    const Divider(height: 30, color: AppColors.lightGray),
                    
                    const Text('Data Pemilik (Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                    const SizedBox(height: 15),
                    _buildPremiumTextField('Username (Tanpa Spasi)', Icons.person, _usernameCtrl),
                    _buildPremiumTextField('Nomor WhatsApp', Icons.phone, _waCtrl, isNumber: true),
                    _buildPremiumTextField('Email Bisnis (Opsional)', Icons.email, _emailCtrl, isEmail: true),
                    
                    const SizedBox(height: 5),
                    _buildPasswordField('Kata Sandi', _passwordCtrl, _isObscure, (val) => setState(() => _isObscure = val)),
                    _buildPasswordField('Konfirmasi Kata Sandi', _konfirmasiCtrl, _isObscureConfirm, (val) => setState(() => _isObscureConfirm = val)),
                    
                    const Divider(height: 30, color: AppColors.lightGray),
                    
                    const Text('Program Referral', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                    const SizedBox(height: 15),
                    _buildPremiumTextField('Kode Referral (Opsional)', Icons.group_add, _referralCtrl, hint: 'Contoh: REF123', isLast: true),

                    const SizedBox(height: 30),
                    
                    // Tombol Daftar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _prosesDaftar,
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                            : const Text('Daftar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer Text
            Transform.translate(
              offset: const Offset(0, -40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Sudah mendaftarkan toko? ", style: TextStyle(color: AppColors.slateGray, fontSize: 13)),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Masuk di sini", style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTextField(String label, IconData icon, TextEditingController controller, {String hint = '', bool isNumber = false, bool isEmail = false, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.slateGray, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              filled: true,
              fillColor: AppColors.lightGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isObscure, Function(bool) onToggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isObscure,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.slateGray, size: 20),
              suffixIcon: IconButton(
                icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: AppColors.smartBlue, size: 20),
                onPressed: () => onToggle(!isObscure),
              ),
              filled: true,
              fillColor: AppColors.lightGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
