import 'package:flutter/material.dart';

class AppColors {
  static const Color deepNavy = Color(0xFF0B2A43);    // Navbar atas & bawah, sidebar
  static const Color darkBlue = Color(0xFF123E5C);    // Background elemen navigasi
  static const Color smartBlue = Color(0xFF1685B8);   // Tombol, link, elemen aktif
  static const Color teal = Color(0xFF13B8A6);        // Tombol utama & identitas
  static const Color emerald = Color(0xFF10B981);     // Status berhasil, kenaikan omzet
  static const Color premiumGold = Color(0xFFF2B84B); // Aksen premium & highlight
  static const Color white = Color(0xFFFFFFFF);       // Card & background utama
  static const Color lightGray = Color(0xFFF4F7FA);   // Background halaman
  static const Color slateGray = Color(0xFF64748B);   // Teks sekunder
  static const Color darkText = Color(0xFF14212B);    // Teks utama
  static const Color red = Color(0xFFEF4444);         // Hapus, refund, stok habis
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.teal,
      scaffoldBackgroundColor: AppColors.lightGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.white),
        titleTextStyle: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      fontFamily: 'Inter', // Sangat disarankan menginstal package google_fonts dan menggunakan font Inter/Poppins
    );
  }
}
