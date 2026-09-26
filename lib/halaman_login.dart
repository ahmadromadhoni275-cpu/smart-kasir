import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'tema.dart'; // Import tema eksklusif
import 'kerangka_navigasi.dart'; // Halaman utama setelah login sukses
import 'halaman_registrasi.dart'; // Menuju halaman daftar

class HalamanLogin extends StatefulWidget {
  const HalamanLogin({super.key});

  @override
  State<HalamanLogin> createState() => _HalamanLoginState();
}

class _HalamanLoginState extends State<HalamanLogin> {
  final String domainUrl = 'https://smartkasir.shop';

  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  Future<void> _prosesLogin() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _tampilkanNotif('Peringatan', 'Username dan Password wajib diisi!', AppColors.premiumGold);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$domainUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameCtrl.text.trim().replaceAll(' ', ''),
          'password': _passwordCtrl.text,
        }),
      );

      final resData = json.decode(response.body);

      if (response.statusCode == 200) {
        var userData = resData['data'];
        
        // Simpan sesi penting ke SharedPreferences (Multi-Admin Multi-Toko)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', int.parse(userData['id'].toString()));
        await prefs.setInt('toko_id', int.parse(userData['toko_id'].toString()));
        await prefs.setString('username', userData['username'] ?? 'Admin');
        await prefs.setString('role', userData['role'] ?? 'kasir');
        await prefs.setString('nama_toko', userData['nama_toko'] ?? 'Smart Kasir');

        _tampilkanNotif('Login Berhasil!', 'Selamat datang kembali, ${userData['username']} 👋', AppColors.emerald);

        // Arahkan ke Kerangka Navigasi Utama
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const KerangkaNavigasiPremium()),
          );
        }
      } else {
        _tampilkanNotif('Login Gagal', resData['message'] ?? 'Username atau password salah.', AppColors.red);
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
            // --- HEADER DEEP NAVY DENGAN GRADASI ---
            Stack(
              children: [
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.deepNavy,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.storefront, color: AppColors.teal, size: 36),
                        ),
                        const SizedBox(height: 20),
                        const Text('Selamat Datang\nDi Smart Kasir', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.white, height: 1.2)),
                        const SizedBox(height: 10),
                        Text('Masuk untuk mengelola kasir dan laporan toko Anda.', style: TextStyle(fontSize: 13, color: AppColors.white.withOpacity(0.8))),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- KARTU FORMULIR LOGIN ---
            Transform.translate(
              offset: const Offset(0, -50),
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
                    const Text('Silakan Masuk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkText)),
                    const SizedBox(height: 5),
                    const Text('Masukkan akun admin atau kasir Anda.', style: TextStyle(color: AppColors.slateGray, fontSize: 12)),
                    const SizedBox(height: 25),

                    _buildPremiumTextField('Username', Icons.person, _usernameCtrl),
                    const SizedBox(height: 15),
                    _buildPasswordField('Kata Sandi', _passwordCtrl, _isObscure, (val) => setState(() => _isObscure = val)),

                    const SizedBox(height: 30),

                    // Tombol Masuk
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _prosesLogin,
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                            : const Text('Masuk Aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Pindah ke Registrasi
            Transform.translate(
              offset: const Offset(0, -25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum punya toko? ", style: TextStyle(color: AppColors.slateGray, fontSize: 13)),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HalamanRegistrasi()),
                      );
                    },
                    child: const Text("Daftar Bisnis Baru", style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildPremiumTextField(String label, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.slateGray, size: 20),
            filled: true,
            fillColor: AppColors.lightGray,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isObscure, Function(bool) onToggle) {
    return Column(
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
    );
  }
}
