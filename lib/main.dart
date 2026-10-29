import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';
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

// 1. Handler Notifikasi Background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Notifikasi background masuk: ${message.messageId}");
}

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
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
              backgroundColor: AppColors.primaryEmerald,
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
        primaryColor: AppColors.primaryEmerald,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryEmerald),
      ),

      // CEK OTENTIKASI SECARA DINAMIS SAAT APLIKASI DIBUKA
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
      },
    );
  }
}

// =================================================================
// WIDGET PENGECEK STATUS LOGIN (AUTH CHECKER)
// =================================================================
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final String? token = prefs.getString('jwt_token');

    // Wajib bernilai true DAN token JWT tidak boleh kosong
    return isLoggedIn && token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        // Tampilan loading melayang saat memeriksa session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryEmerald),
            ),
          );
        }

        // Jika terverifikasi sudah login, buka KerangkaNavigasi
        if (snapshot.hasData && snapshot.data == true) {
          return const KerangkaNavigasi();
        }

        // Jika belum login / session habis, paksa ke HalamanLogin
        return const HalamanLogin();
      },
    );
  }
}
