import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';
import 'dart:ui';
import 'kerangka_navigasi.dart';
import 'halaman_login.dart';
import 'halaman_notifikasi.dart';
import 'halaman_riwayat_transaksi.dart';
import 'halaman_pusat_bantuan.dart';
import 'halaman_daftar_tiket_bantuan.dart';
import 'halaman_langganan_saas.dart';
import 'halaman_referral.dart';
import 'halaman_shift.dart';
import 'halaman_riwayat_stok.dart';
import 'halaman_profil_akun.dart';
import 'halaman_keamanan.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'halaman_pilih_cabang.dart';

// Import Helper Pemaksaan Izin yang baru kita buat
import 'core/utils/permission_helper.dart';

// 1. Handler Notifikasi Background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Notifikasi background masuk: ${message.messageId}");
}

// 2. Kunci Navigasi Global (diletakkan di luar agar bisa diakses oleh interceptor & background)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp();
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
    _setupFCMListeners();
  }

  void _setupFCMListeners() async {
    // A. Foreground Notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(message.notification!.body ?? ''),
                ],
              ),
              backgroundColor: AppColors.smartBlue, 
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: message.data['action_route'] != null &&
                      message.data['action_route'].toString().isNotEmpty
                  ? SnackBarAction(
                      label: 'LIHAT',
                      textColor: Colors.white,
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        navigatorKey.currentState
                            ?.pushNamed(message.data['action_route']);
                      },
                    )
                  : null,
            ),
          );
        }
      }
    });

    // B. Background Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });

    // C. Terminated Click
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationClick(initialMessage);
      });
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final route = message.data['action_route'];
    if (route != null && route.toString().isNotEmpty) {
      navigatorKey.currentState?.pushNamed(route.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Smart Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.smartBlue, 
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.smartBlue),
      ),

      // CEK OTENTIKASI & IZIN SECARA DINAMIS SAAT APLIKASI DIBUKA
      home: const AuthChecker(),

      routes: {
        '/login': (context) => const HalamanLogin(),
        '/notifikasi': (context) => const HalamanNotifikasi(),
        '/pusat_bantuan': (context) => const HalamanPusatBantuan(),
        '/tiket_bantuan': (context) => const HalamanDaftarTiket(),
        '/riwayat_transaksi': (context) => const HalamanRiwayatTransaksi(),
        '/shift': (context) => const HalamanShift(),
        '/riwayat_stok': (context) => const HalamanRiwayatStok(),
        '/langganan': (context) => const HalamanLanggananSaas(),
        '/referral': (context) => const HalamanReferral(),
        '/profil': (context) => const HalamanProfilAkun(),
        '/keamanan': (context) => const HalamanKeamanan(),
        '/pilih_cabang': (context) => const HalamanPilihCabang(),
      },
    );
  }
}

// =================================================================
// WIDGET PENGECEK STATUS LOGIN & IZIN PERANGKAT (AUTH CHECKER)
// =================================================================
class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  
  @override
  void initState() {
    super.initState();
    // Meminta dan memeriksa izin perangkat (Bluetooth & Lokasi) saat layar ini dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionHelper.checkAndRequestPermissions(context);
    });
  }

  Future<dynamic> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? token = prefs.getString('jwt_token');
    final int storeId = prefs.getInt('store_id') ?? 0;

    // Jeda buatan (1.5 detik) agar pengguna bisa melihat layar loading yang cantik
    await Future.delayed(const Duration(milliseconds: 1500));

    return {
      'is_logged_in': isLoggedIn && token != null && token.isNotEmpty,
      'has_store_selected': storeId > 0, 
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // =======================================================
          // TAMPILAN LOADING / SPLASH SCREEN (CRYSTAL GLASS UI)
          // =======================================================
          return Scaffold(
            body: Stack(
              children: [
                // 1. Background Gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd],
                    ),
                  ),
                ),
                
                // 2. Ornamen Blob Cahaya
                Positioned(
                  top: -100,
                  right: -50,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(width: 300, height: 300, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.skyBlue)),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -100,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(width: 300, height: 300, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.smartBlue)),
                  ),
                ),

                // 3. Logo dan Loading
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo_smart_kasir.png',
                        height: 120, // Sedikit lebih besar dari halaman login
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(color: AppColors.smartBlue, strokeWidth: 3),
                      const SizedBox(height: 16),
                      const Text(
                        'Memuat Sistem...', 
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data as Map<dynamic, dynamic>?;
        final bool isLoggedIn = data?['is_logged_in'] ?? false;
        final bool hasStoreSelected = data?['has_store_selected'] ?? false;

        if (isLoggedIn) {
          if (!hasStoreSelected) {
            return const HalamanPilihCabang();
          }
          return const KerangkaNavigasi();
        }

        return const HalamanLogin();
      },
    );
  }
}