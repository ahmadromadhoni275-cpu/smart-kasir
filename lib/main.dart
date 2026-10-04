import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'presentation/layouts/main_layout.dart';

// TODO: Import file-file halaman Anda di sini
// import 'halaman_login.dart';
// import 'halaman_pilih_cabang.dart';

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
      
      // ========================================================
      // SISTEM ROUTING SMART KASIR
      // ========================================================
      // Untuk sementara, jika Anda masih mendevelop UI dan belum mau lewat login, 
      // biarkan 'home' aktif dan comment 'initialRoute' & 'routes'.
      
      home: const MainLayout(isOwner: true), 
      
      /*
      initialRoute: '/login', // Aplikasi akan pertama kali membuka halaman login
      routes: {
        '/login': (context) => const HalamanLogin(),
        
        // Halaman ini akan dipanggil otomatis oleh HalamanLogin jika cabang > 1
        '/pilih_cabang': (context) => const HalamanPilihCabang(),
        
        // '/home' ini memanggil Kerangka/Layout Utama Anda
        '/home': (context) => const MainLayout(isOwner: true), 
      },
      */
    );
  }
}
