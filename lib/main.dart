import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- TAMBAHAN IMPORT FIREBASE & NOTIFIKASI ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Memanggil semua halaman yang akan dimasukkan ke menu bawah
import 'halaman_login.dart';
import 'halaman_beranda.dart';
import 'halaman_kasir.dart';
import 'halaman_produk.dart';
import 'halaman_pegawai.dart'; // Tambahan halaman pegawai
import 'halaman_pengaturan.dart';

// ===================================================================
// FUNGSI PENANGKAP NOTIFIKASI SAAT APLIKASI DITUTUP (BACKGROUND)
// Wajib diletakkan di luar class atau fungsi main
// ===================================================================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Notifikasi masuk saat aplikasi ditutup: ${message.messageId}");
}

// Inisialisasi plugin notifikasi lokal untuk memunculkan pop-up di layar
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  // Memastikan mesin Flutter sudah siap sebelum membaca memori HP
  WidgetsFlutterBinding.ensureInitialized();

  // ===================================================================
  // MESIN FIREBASE & PERIZINAN NOTIFIKASI
  // ===================================================================
  try {
    // 1. Menghidupkan Firebase
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Mengatur ikon aplikasi untuk notifikasi
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 3. Meminta Izin Notifikasi (Wajib untuk Android 13+ dan iOS)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Izin notifikasi diberikan oleh pengguna.');
      
      // Mengambil FCM Token (Ibarat "Alamat Rumah" HP ini untuk dikirimi pesan)
      String? token = await messaging.getToken();
      debugPrint('====================================');
      debugPrint('FCM TOKEN HP INI: $token');
      debugPrint('====================================');
    } else {
      debugPrint('Izin notifikasi ditolak oleh pengguna.');
    }

    // 4. Penangkap Notifikasi saat Aplikasi Sedang Terbuka (Foreground)
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
              'smart_kasir_channel', // ID Channel bebas
              'Notifikasi Penting', // Nama Channel yang muncul di pengaturan HP
              channelDescription: 'Channel khusus untuk notifikasi transaksi',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  } catch (e) {
    debugPrint('Gagal menghidupkan Firebase: $e');
  }
  // ===================================================================

  // Mengecek memori HP apakah pengguna sudah login sebelumnya
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  // Menjalankan aplikasi dan mengirim status login
  runApp(AplikasiKasir(isLoggedIn: isLoggedIn));
}

class AplikasiKasir extends StatelessWidget {
  final bool isLoggedIn;

  const AplikasiKasir({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kasir',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Jika sudah login, langsung ke KerangkaNavigasi (Menu Bawah). Jika belum, ke halaman Login.
      home: isLoggedIn ? const KerangkaNavigasi() : const HalamanLogin(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ===================================================================
// KERANGKA NAVIGASI (BOTTOM NAVIGATION BAR)
// Menyatukan Beranda, Kasir, Produk, Pegawai, dan Pengaturan
// ===================================================================
class KerangkaNavigasi extends StatefulWidget {
  const KerangkaNavigasi({super.key});

  @override
  State<KerangkaNavigasi> createState() => _KerangkaNavigasiState();
}

class _KerangkaNavigasiState extends State<KerangkaNavigasi> {
  int _indeksDipilih = 0;

  // Daftar halaman yang akan ditampilkan saat tab diklik (Urutan Indeks)
  final List<Widget> _daftarHalaman = [
    const HalamanBeranda(),     // Indeks 0
    const HalamanKasir(),       // Indeks 1
    const HalamanProduk(),      // Indeks 2
    const HalamanPegawai(),     // Indeks 3 - Tambahan halaman pegawai
    const HalamanPengaturan(),  // Indeks 4
  ];

  void _ketukTab(int indeks) {
    setState(() {
      _indeksDipilih = indeks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Menampilkan halaman sesuai dengan menu yang diklik
      body: _daftarHalaman[_indeksDipilih],

      // Menu Navigasi Bawah
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Agar ukuran dan warna stabil
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _indeksDipilih,
        onTap: _ketukTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Kasir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people), // Ikon untuk Pegawai
            label: 'Pegawai',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
