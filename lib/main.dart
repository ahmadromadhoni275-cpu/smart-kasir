import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'tema.dart'; // Menggunakan tema.dart yang sudah ada di proyek Anda
import 'kerangka_navigasi.dart';
// import 'firebase_options.dart'; // Buka komentar ini jika menggunakan FlutterFire CLI
// --- IMPORT HALAMAN UNTUK ROUTING ---
import 'halaman_login.dart';
import 'halaman_beranda.dart';
import 'halaman_notifikasi.dart';
import 'halaman_riwayat_transaksi.dart';
import 'halaman_pusat_bantuan.dart';
import 'halaman_daftar_tiket_bantuan.dart'; // Sesuaikan jika namanya berbeda
import 'halaman_langganan_saas.dart';
import 'halaman_referral.dart';
import 'halaman_shift.dart';
import 'halaman_riwayat_stok.dart';
import 'halaman_profil_akun.dart';
import 'halaman_keamanan.dart';

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
  // Jika Anda menggunakan FlutterFire CLI, ganti dengan baris di bawah ini:
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
  // Buat Navigator Key agar kita bisa pindah halaman secara global (dari notifikasi)
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupFCMListeners();
  }

  // 5. Setup Pendengar Notifikasi (Foreground, Background, dan Terminated)
  void _setupFCMListeners() async {
    // A. KONDISI FOREGROUND (Aplikasi sedang terbuka dan tampil di layar)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Notif diterima: ${message.notification?.title}');
      
      // Munculkan Snackbar peringatan melayang di dalam aplikasi
      if (message.notification != null) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.notification!.title ?? 'Info Baru', 
                    style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  Text(message.notification!.body ?? ''),
                ],
              ),
              backgroundColor: AppColors.primaryEmerald, // Gunakan warna tema Anda
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              // Tambahkan tombol aksi jika ada rute yang dikirim dari server
              action: message.data['action_route'] != null && message.data['action_route'].toString().isNotEmpty
                  ? SnackBarAction(
                      label: 'LIHAT',
                      textColor: Colors.white,
                      onPressed: () {
                        // Tutup snackbar dan pindah halaman
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        navigatorKey.currentState?.pushNamed(message.data['action_route']);
                      },
                    )
                  : null,
            ),
          );
        }
      }
    });

    // B. KONDISI BACKGROUND (Aplikasi di-minimize, lalu notifikasi di HP diklik)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notifikasi diklik dari background!');
      _handleNotificationClick(message);
    });

    // C. KONDISI TERMINATED (Aplikasi ditutup penuh/di-swipe up, lalu notifikasi diklik)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('Aplikasi dibuka dari klik notifikasi saat aplikasi mati!');
      // Beri sedikit jeda agar widget MaterialApp selesai dibangun sebelum pindah halaman
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClick(initialMessage);
      });
    }
  }

  // Fungsi khusus untuk menangani aksi pindah halaman
  void _handleNotificationClick(RemoteMessage message) {
    final route = message.data['action_route'];
    if (route != null && route.toString().isNotEmpty) {
       navigatorKey.currentState?.pushNamed(route.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // <--- Daftarkan GlobalKey di sini
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
      
      // Daftarkan rute global Anda di sini agar fungsi pushNamed() bisa bekerja
            // Daftarkan rute global Anda di sini agar fungsi pushNamed() bisa bekerja
      routes: {
        // Otentikasi & Utama
        '/login': (context) => const HalamanLogin(),
        '/beranda': (context) => const HalamanBeranda(),
        
        // Notifikasi & Bantuan (Sering jadi target Broadcast)
        '/notifikasi': (context) => const HalamanNotifikasi(),
        '/pusat_bantuan': (context) => const HalamanPusatBantuan(),
        '/tiket_bantuan': (context) => const HalamanDaftarTiketBantuan(),
        
        // Transaksi & Laporan
        '/riwayat_transaksi': (context) => const HalamanRiwayatTransaksi(),
        '/shift': (context) => const HalamanShift(),
        '/riwayat_stok': (context) => const HalamanRiwayatStok(),
        
        // Langganan & Referral (Penting untuk tagihan)
        '/langganan': (context) => const HalamanLanggananSaas(),
        '/referral': (context) => const HalamanReferral(),
        
        // Akun & Keamanan
        '/profil': (context) => const HalamanProfilAkun(),
        '/keamanan': (context) => const HalamanKeamanan(),
      },

    );
  }
}
