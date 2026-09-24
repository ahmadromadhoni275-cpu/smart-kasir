import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Tambahan untuk fungsi Timer/Delay

// --- TAMBAHAN IMPORT FIREBASE & NOTIFIKASI ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- IMPORT FILE PREMIUM & HALAMAN UTAMA ---
import 'halaman_login.dart';
import 'tema.dart'; // Tema warna premium eksklusif
import 'kerangka_navigasi.dart'; // Kerangka navigasi premium yang baru

// ===================================================================
// FUNGSI PENANGKAP NOTIFIKASI SAAT APLIKASI DITUTUP (BACKGROUND)
// ===================================================================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Notifikasi masuk saat aplikasi ditutup: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ===================================================================
  // MESIN FIREBASE & PERIZINAN NOTIFIKASI
  // ===================================================================
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // MENGGUNAKAN IKON SILUET (ic_notifikasi)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notifikasi');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Izin notifikasi diberikan.');
      String? token = await messaging.getToken();
      debugPrint('FCM TOKEN HP INI: $token');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'smart_kasir_channel',
              'Notifikasi Penting',
              channelDescription: 'Channel khusus untuk notifikasi transaksi',
              importance: Importance.max,
              priority: Priority.high,
              // WARNA & IKON SAAT APLIKASI DIBUKA (FOREGROUND)
              icon: 'ic_notifikasi',
              color: AppColors.teal, // Menggunakan warna teal premium
            ),
          ),
        );
      }
    });
  } catch (e) {
    debugPrint('Gagal menghidupkan Firebase: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(AplikasiKasir(isLoggedIn: isLoggedIn));
}

class AplikasiKasir extends StatelessWidget {
  final bool isLoggedIn;
  const AplikasiKasir({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kasir Premium',
      // ===================================================================
      // MENGGUNAKAN TEMA PREMIUM DARI tema.dart
      // ===================================================================
      theme: AppTheme.lightTheme,
      home: HalamanSplashLoading(isLoggedIn: isLoggedIn),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ===================================================================
// HALAMAN SPLASH SCREEN (LOADING) PREMIUM
// ===================================================================
class HalamanSplashLoading extends StatefulWidget {
  final bool isLoggedIn;
  const HalamanSplashLoading({super.key, required this.isLoggedIn});

  @override
  State<HalamanSplashLoading> createState() => _HalamanSplashLoadingState();
}

class _HalamanSplashLoadingState extends State<HalamanSplashLoading> {
  @override
  void initState() {
    super.initState();
    _mulaiLoading();
  }

  // Fungsi untuk memberi jeda animasi loading lalu pindah halaman
  void _mulaiLoading() async {
    await Future.delayed(const Duration(seconds: 3)); // Waktu loading 3 detik
    if (!mounted) return;

    // Pindah halaman berdasarkan status login
    if (widget.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        // ARAHKAN KE KERANGKA NAVIGASI PREMIUM YANG BARU
        MaterialPageRoute(builder: (context) => const KerangkaNavigasiPremium()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HalamanLogin()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double lebarLayar = MediaQuery.of(context).size.width;

    return Scaffold(
      // MENGGUNAKAN WARNA DEEP NAVY AGAR KESAN PREMIUM TERASA DARI AWAL
      backgroundColor: AppColors.deepNavy, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gambar Logo Loading
            Image.asset(
              'assets/logo_loading.png',
              width: lebarLayar * 0.45, // Ukuran logo 45% dari layar agar proporsional
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40), // Jarak antara logo dan loading
            // Indikator Putar Elegan
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal), // Aksen Teal
                strokeWidth: 3.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Catatan: Class KerangkaNavigasi yang lama sudah dihapus karena kita
// sudah beralih menggunakan file kerangka_navigasi.dart sepenuhnya.
