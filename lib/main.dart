import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    // Sintaks versi 17.0.0
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
        // Sintaks versi 17.0.0
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
              icon: '@mipmap/ic_launcher',
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
      home: isLoggedIn ? const KerangkaNavigasi() : const HalamanLogin(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ===================================================================
// KERANGKA NAVIGASI (BOTTOM NAVIGATION BAR)
// ===================================================================
class KerangkaNavigasi extends StatefulWidget {
  const KerangkaNavigasi({super.key});
  @override
  State<KerangkaNavigasi> createState() => _KerangkaNavigasiState();
}

class _KerangkaNavigasiState extends State<KerangkaNavigasi> {
  int _indeksDipilih = 0;

  final List<Widget> _daftarHalaman = [
    const HalamanBeranda(),      
    const HalamanKasir(),        
    const HalamanProduk(),       
    const HalamanPegawai(),      
    const HalamanPengaturan(),   
  ];

  void _ketukTab(int indeks) {
    setState(() {
      _indeksDipilih = indeks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _daftarHalaman[_indeksDipilih],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, 
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _indeksDipilih,
        onTap: _ketukTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Kasir'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Produk'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pegawai'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}
