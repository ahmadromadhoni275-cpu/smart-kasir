import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tema.dart'; // Import tema eksklusif

class HalamanKeamanan extends StatefulWidget {
  const HalamanKeamanan({super.key});

  @override
  State<HalamanKeamanan> createState() => _HalamanKeamananState();
}

class _HalamanKeamananState extends State<HalamanKeamanan> {
  final String domainUrl = 'https://smartkasir.shop';
  
  final TextEditingController _passLamaCtrl = TextEditingController();
  final TextEditingController _passBaruCtrl = TextEditingController();
  final TextEditingController _konfirmasiCtrl = TextEditingController();

  bool _sembunyiLama = true;
  bool _sembunyiBaru = true;
  bool _sembunyiKonfirmasi = true;
  bool isLoading = false;
  
  int _userId = 1;
  bool _gunakanPin = false; // Mock fitur tambahan untuk UI premium

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id') ?? 1;
      _gunakanPin = prefs.getBool('gunakan_pin') ?? false;
    });
  }

  Future<void> _simpanPasswordBaru() async {
    if (_passLamaCtrl.text.isEmpty || _passBaruCtrl.text.isEmpty || _konfirmasiCtrl.text.isEmpty) {
      _tampilkanNotif('Perhatian', 'Semua kolom password wajib diisi!', AppColors.premiumGold);
      return;
    }

    if (_passBaruCtrl.text != _konfirmasiCtrl.text) {
      _tampilkanNotif('Gagal', 'Password baru dan konfirmasi tidak cocok!', AppColors.red);
      return;
    }

    if (_passBaruCtrl.text.length < 6) {
      _tampilkanNotif('Lemah', 'Password baru minimal 6 karakter.', AppColors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Pastikan Anda membuat endpoint /api/ubahPassword di CI4 nantinya
      final response = await http.post(
        Uri.parse('$domainUrl/api/ubahPassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': _userId,
          'password_lama': _passLamaCtrl.text,
          'password_baru': _passBaruCtrl.text,
        }),
      );

      if (response.statusCode == 200) {
        _tampilkanNotif('Berhasil!', 'Password akun Anda berhasil diperbarui.', AppColors.emerald);
        _passLamaCtrl.clear();
        _passBaruCtrl.clear();
        _konfirmasiCtrl.clear();
      } else {
        final res = json.decode(response.body);
        _tampilkanNotif('Gagal', res['message'] ?? 'Password lama salah atau terjadi kesalahan.', AppColors.red);
      }
    } catch (e) {
      _tampilkanNotif('Error', 'Kesalahan jaringan: $e', AppColors.red);
    }

    setState(() => isLoading = false);
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

  // ==========================================
  // WIDGET UTAMA (BODY)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        title: const Text('Keamanan & Privasi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER INFO ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.shield_outlined, size: 50, color: AppColors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text('Amankan Akun Anda', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                  const SizedBox(height: 5),
                  Text('Perbarui kata sandi secara berkala untuk menjaga keamanan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.white.withOpacity(0.7))),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- FORM UBAH PASSWORD ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Ubah Kata Sandi', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
            ),
            const SizedBox(height: 15),
            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordField('Password Lama', _passLamaCtrl, _sembunyiLama, (val) => setState(() => _sembunyiLama = val)),
                  const Divider(height: 30, color: AppColors.lightGray),
                  _buildPasswordField('Password Baru', _passBaruCtrl, _sembunyiBaru, (val) => setState(() => _sembunyiBaru = val)),
                  _buildPasswordField('Konfirmasi Password Baru', _konfirmasiCtrl, _sembunyiKonfirmasi, (val) => setState(() => _sembunyiKonfirmasi = val), isLast: true),
                  
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: isLoading ? null : _simpanPasswordBaru,
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                          : const Text('Simpan Password', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- OTENTIKASI TAMBAHAN (FITUR PREMIUM UI) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Otentikasi Tambahan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
            ),
            const SizedBox(height: 15),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                activeColor: AppColors.emerald,
                title: const Text('Gunakan PIN Akses Kasir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText)),
                subtitle: const Text('Minta PIN setiap kali membuka layar transaksi.', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.dialpad, color: AppColors.smartBlue),
                ),
                value: _gunakanPin,
                onChanged: (val) async {
                  final prefs = await SharedPreferences.getInstance();
                  setState(() => _gunakanPin = val);
                  await prefs.setBool('gunakan_pin', val);
                  if (val) {
                    _tampilkanNotif('Info', 'Fitur PIN akan tersedia di update berikutnya.', AppColors.smartBlue);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isObscure, Function(bool) onToggle, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
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
