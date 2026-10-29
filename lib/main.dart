import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'tema.dart'; // Menggunakan tema.dart yang sudah ada di proyek Anda
import 'kerangka_navigasi.dart';

// 1. Handler untuk notifikasi saat aplikasi berjalan di background / ditutup
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase diinisialisasi di isolate background
  await Firebase.initializeApp();
  debugPrint("Notifikasi background masuk: ${message.messageId}");
}

Future<void> main() async {
  // 2. Wajib dipanggil sebelum inisialisasi Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. Inisialisasi Firebase
  // Jika Anda menggunakan FlutterFire CLI, tambahkan opsi seperti ini:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  // 4. Daftarkan background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const SmartKasirApp());
}

class SmartKasirApp extends StatefulWidget {
  const SmartKasirApp({super.key});

  @override
  State<SmartKasirApp> createState() => _SmartKasirAppState();
}

class _SmartKasirAppState extends State<SmartKasirApp> {
  
  @override
  void initState() {
    super.initState();
    _setupForegroundNotification();
  }

  // 5. Handler untuk notifikasi saat aplikasi sedang terbuka (Foreground)
  void _setupForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Notifikasi foreground diterima: ${message.notification?.title}');
      
      // Jika ingin memunculkan alert/snackbar secara global saat aplikasi dibuka, 
      // logikanya bisa ditambahkan di sini.
      if (message.notification != null) {
        debugPrint('Isi pesan: ${message.notification?.body}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter', 
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryEmerald,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryEmerald),
      ),
      
      // Halaman pertama kali aplikasi dibuka
      home: const KerangkaNavigasi(),
    );
  }
}
