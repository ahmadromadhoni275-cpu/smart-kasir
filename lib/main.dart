import 'package:flutter/material.dart';
import 'tema.dart'; // Menggunakan tema.dart yang sudah ada di proyek Anda
import 'kerangka_navigasi_utama.dart'; // Menghubungkan ke kerangka navigasi

void main() {
  runApp(const SmartKasirApp());
}

class SmartKasirApp extends StatelessWidget {
  const SmartKasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', // Pastikan font Inter terdaftar di pubspec.yaml atau gunakan default
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryEmerald,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryEmerald),
      ),
      
      // Halaman pertama kali aplikasi dibuka
      home: const KerangkaNavigasiUtama(),
    );
  }
}
