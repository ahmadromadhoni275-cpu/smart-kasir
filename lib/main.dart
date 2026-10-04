import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'presentation/layouts/main_layout.dart';

void main() {
  runApp(const SmartKasirApp());
}

class SmartKasirApp extends StatelessWidget {
  const SmartKasirApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', // Pastikan Anda menambahkan font Inter di pubspec.yaml
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryEmerald,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryEmerald),
      ),
      // Memanggil layout utama, isOwner diset true untuk simulasi akun Owner
      home: const MainLayout(isOwner: true), 
    );
  }
}
