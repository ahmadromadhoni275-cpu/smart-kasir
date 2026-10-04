import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tema.dart';
import 'halaman_login.dart';

class HalamanOTP extends StatefulWidget {
  final String email;
  const HalamanOTP({super.key, required this.email});

  @override
  State<HalamanOTP> createState() => _HalamanOTPState();
}

class _HalamanOTPState extends State<HalamanOTP> {
  final String domainUrl = 'https://smartkasir.shop/api'; 
  final TextEditingController _otpCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifikasiOTP() async {
    if (_otpCtrl.text.isEmpty || _otpCtrl.text.length < 6) {
      _showNotif('Masukkan 6 digit kode OTP yang valid', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$domainUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': widget.email,
          'otp_code': _otpCtrl.text.trim(),
        }),
      );

      final resData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showNotif('Verifikasi berhasil! Silakan Login.', AppColors.greenAccent);
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HalamanLogin()),
            (route) => false,
          );
        }
      } else {
        _showNotif(resData['messages']?['error'] ?? 'OTP Salah', AppColors.error);
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
              constraints: const BoxConstraints(maxWidth: 400),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.goldPremium.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.goldPremium),
                    ),
                    const SizedBox(height: 24),
                    const Text('Verifikasi Akun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Text('Masukkan 6 digit kode OTP yang telah dikirimkan ke email:\n${widget.email}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold, color: AppColors.navyActive),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "000000",
                        hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.3)),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 32),

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
                        onPressed: _isLoading ? null : _verifikasiOTP,
                        child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Verifikasi OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
