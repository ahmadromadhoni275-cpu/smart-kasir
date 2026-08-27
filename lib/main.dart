import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Tambahan untuk fungsi Timer/Delay

// --- TAMBAHAN IMPORT FIREBASE & NOTIFIKASI ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Memanggil semua halaman
import 'halaman_login.dart';
import 'halaman_beranda.dart';
import 'halaman_kasir.dart';
import 'halaman_produk.dart';
import 'halaman_pegawai.dart'; 
import 'halaman_pengaturan.dart';

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

    // ===================================================================
    // PERBAIKAN 1: MENGGUNAKAN IKON SILUET (ic_notifikasi)
    // ===================================================================
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notifikasi'); // <--- Diubah di sini
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
              // ===================================================================
              // PERBAIKAN 2: WARNA & IKON SAAT APLIKASI DIBUKA (FOREGROUND)
              // ===================================================================
              icon: 'ic_notifikasi', // <--- Diubah di sini
              color: Colors.blueAccent, // <--- Opsi tambahan agar ikon ada warna latarnya
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
      title: 'Smart Kasir',
      theme: ThemeData(primarySwatch: Colors.blue),
      // PERUBAHAN: Arahkan home ke HalamanSplashLoading terlebih dahulu
      home: HalamanSplashLoading(isLoggedIn: isLoggedIn),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ===================================================================
// HALAMAN SPLASH SCREEN (LOADING)
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
        MaterialPageRoute(builder: (context) => const KerangkaNavigasi()),
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
      backgroundColor: Colors.blueAccent, // Ganti warna ini jika background logo bukan biru
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
            // Indikator Putar
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// KERANGKA NAVIGASI DINAMIS (BERDASARKAN ROLE ADMIN / KASIR)
// ===================================================================
class KerangkaNavigasi extends StatefulWidget {
  const KerangkaNavigasi({super.key});

  @override
  State<KerangkaNavigasi> createState() => _KerangkaNavigasiState();
}

class _KerangkaNavigasiState extends State<KerangkaNavigasi> {
  int _indeksDipilih = 0;
  String _roleUser = 'kasir';
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _cekRolePengguna();
  }

  // Ambil data role dari SharedPreferences saat kerangka dimuat
  Future<void> _cekRolePengguna() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _roleUser = prefs.getString('role') ?? 'kasir';
      _isLoadingRole = false;
    });
  }

  void _ketukTab(int indeks) {
    setState(() {
      _indeksDipilih = indeks;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Jika masih memuat role, tampilkan loading sebentar
    if (_isLoadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Tentukan daftar halaman & navbar berdasarkan apakah dia 'admin' atau 'kasir'
    bool isAdmin = (_roleUser == 'admin');

    // List Halaman: Jika Admin (5 menu), Jika Kasir (3 menu: Beranda, Kasir, Produk)
    final List<Widget> daftarHalaman = isAdmin
        ? [
            const HalamanBeranda(),
            const HalamanKasir(),
            const HalamanProduk(),
            const HalamanPegawai(),
            const HalamanPengaturan(),
          ]
        : [
            const HalamanBeranda(),
            const HalamanKasir(),
            const HalamanProduk(), // Kasir bisa akses produk (untuk lihat & search)
          ];

    // List Item Navbar
    final List<BottomNavigationBarItem> daftarNavbarItem = isAdmin
        ? [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Beranda'),
            const BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
            const BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Produk'),
            const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pegawai'),
            const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
          ]
        : [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Beranda'),
            const BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
            const BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Produk'),
          ];

    // Pastikan index tidak out of bound jika berpindah akun
    if (_indeksDipilih >= daftarHalaman.length) {
      _indeksDipilih = 0;
    }

    return Scaffold(
      body: daftarHalaman[_indeksDipilih],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _indeksDipilih,
        onTap: _ketukTab,
        items: daftarNavbarItem,
      ),
    );
  }
}
