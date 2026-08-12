import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'main.dart'; // Memanggil KerangkaNavigasi

class HalamanRegistrasi extends StatefulWidget {
  // Tambahkan parameter opsional untuk menerima kode referal jika dipanggil dari link
  final String? kodeReferalBawaan; 

  const HalamanRegistrasi({super.key, this.kodeReferalBawaan});

  @override
  State<HalamanRegistrasi> createState() => _HalamanRegistrasiState();
}

class _HalamanRegistrasiState extends State<HalamanRegistrasi> {
  // URL Domain telah disesuaikan ke hosting AnymHost Anda
  final String baseUrl = 'https://smartkasir.shop/api';

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _namaTokoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _waController = TextEditingController(); 
  final TextEditingController _referalController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool isLoading = false;
  bool isOtpSent = false; 
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    // Jika ada kode referal bawaan dari parameter, otomatis isikan ke kolom
    if (widget.kodeReferalBawaan != null) {
      _referalController.text = widget.kodeReferalBawaan!;
    }
  }

  // --- 1. FUNGSI KIRIM OTP ---
  Future<void> kirimOtp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email valid wajib diisi untuk menerima OTP!'),
          backgroundColor: Colors.red));
      return;
    }

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty || _namaTokoController.text.isEmpty || _waController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Harap lengkapi Nama Toko, Username, Password, Email, dan No WA terlebih dahulu.'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/kirimOtpEmail'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'email': _emailController.text,
          'jenis': 'pendaftaran'
        }),
      );

      setState(() => isLoading = false);

      if (response.statusCode == 200) {
        setState(() {
          isOtpSent = true; 
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kode OTP telah dikirim. Silakan cek Inbox atau Spam Email Anda!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4)));
        }
      } else {
        final data = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(data['message'] ?? 'Gagal mengirim OTP'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Tidak dapat terhubung ke server.'),
            backgroundColor: Colors.red));
      }
    }
  }

  // --- 2. FUNGSI DAFTAR DAN AUTO-LOGIN ---
  Future<void> prosesDaftar() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Kode OTP wajib diisi!'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registerAdminDanToko'), 
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: json.encode({
          'username': _usernameController.text,
          'password': _passwordController.text,
          'email': _emailController.text,
          'no_wa': _waController.text, 
          'nama_toko': _namaTokoController.text,
          'otp': _otpController.text,
          'referral_input': _referalController.text.isEmpty ? null : _referalController.text,
        }),
      );

      if (response.statusCode == 201) {
        // REGISTRASI BERHASIL -> JALANKAN OTOMATIS LOGIN DI BELAKANG LAYAR
        try {
          final loginResponse = await http.post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
            body: json.encode({
              'username': _usernameController.text,
              'password': _passwordController.text,
            }),
          );

          setState(() => isLoading = false);

          if (loginResponse.statusCode == 200) {
            final data = json.decode(loginResponse.body);
            final user = data['user'];

            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', int.parse(user['id'].toString()));
            await prefs.setInt('toko_id', int.parse(user['toko_id'].toString()));
            await prefs.setString('username', user['username']);
            await prefs.setString('role', user['role']);
            await prefs.setBool('is_logged_in', true);

            // Simpan FCM Token
            try {
              String? fcmToken = await FirebaseMessaging.instance.getToken();
              if (fcmToken != null) {
                await http.post(
                  Uri.parse('$baseUrl/update-fcm-token'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'user_id': user['id'], 'fcm_token': fcmToken}),
                );
              }
            } catch (e) {
              debugPrint("FCM Token error: $e");
            }

            if (mounted) {
              // Arahkan ke Beranda dan Hapus Riwayat Navigasi (Tidak bisa di-back ke halaman daftar)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const KerangkaNavigasi()),
                (Route<dynamic> route) => false,
              );

              // Munculkan notifikasi agar melengkapi pengaturan toko
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Pendaftaran Berhasil! Harap lengkapi informasi toko Anda di Halaman Pengaturan.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 6)));
            }
          } else {
            // Jika login gagal (jarang terjadi), kembalikan ke halaman login
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Pendaftaran Berhasil. Silakan login manual.'),
                  backgroundColor: Colors.green));
              Navigator.pop(context);
            }
          }
        } catch (e) {
          setState(() => isLoading = false);
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } else {
        setState(() => isLoading = false);
        final data = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(data['message'] ?? 'Gagal mendaftar'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Tidak dapat terhubung ke server.'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 40.0),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo2.png', height: 60),
                const SizedBox(height: 10),
                const Text('Pendaftaran Toko Baru',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 5),
                const Text('Gratis Trial 14 Hari', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),

                // Form Input Dasar
                TextField(
                  controller: _namaTokoController,
                  enabled: !isOtpSent,
                  decoration: InputDecoration(
                      labelText: 'Nama Toko Anda',
                      prefixIcon: const Icon(Icons.store),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _usernameController,
                  enabled: !isOtpSent,
                  decoration: InputDecoration(
                      labelText: 'Username Login',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isOtpSent,
                  decoration: InputDecoration(
                      labelText: 'Email Aktif (Untuk OTP)',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _waController,
                  keyboardType: TextInputType.phone,
                  enabled: !isOtpSent,
                  decoration: InputDecoration(
                      labelText: 'No WhatsApp',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  enabled: !isOtpSent,
                  decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 15),
                // Kode Referal (Opsional)
                TextField(
                  controller: _referalController,
                  enabled: !isOtpSent, 
                  decoration: InputDecoration(
                      labelText: 'Kode Referal (Opsional)',
                      prefixIcon: const Icon(Icons.card_giftcard, color: Colors.orange),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 25),

                // ==========================================
                // LOGIKA TOMBOL & INPUT OTP DINAMIS
                // ==========================================
                if (!isOtpSent)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: isLoading ? null : kirimOtp,
                      icon: isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.send, color: Colors.white),
                      label: const Text('Kirim Kode OTP ke Email',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                else
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 10),
                            Expanded(child: Text('Kode OTP berhasil dikirim. Silakan cek email Anda (Termasuk folder Spam).', style: TextStyle(fontSize: 12, color: Colors.green))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                            labelText: 'Masukkan 6 Digit OTP',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          onPressed: isLoading ? null : prosesDaftar,
                          child: isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Verifikasi & Daftar Sekarang',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Masuk di sini',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
