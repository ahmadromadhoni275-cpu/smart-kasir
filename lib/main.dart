import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Memanggil semua halaman yang akan dimasukkan ke menu bawah
import 'halaman_login.dart';
import 'halaman_beranda.dart';
import 'halaman_kasir.dart';
import 'halaman_produk.dart';
import 'halaman_pegawai.dart'; // Tambahan halaman pegawai
import 'halaman_pengaturan.dart';

void main() async {
  // Memastikan mesin Flutter sudah siap sebelum membaca memori HP
  WidgetsFlutterBinding.ensureInitialized();

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
    const HalamanBeranda(),   // Indeks 0
    const HalamanKasir(),     // Indeks 1
    const HalamanProduk(),    // Indeks 2
    const HalamanPegawai(),   // Indeks 3 - Tambahan halaman pegawai
    const HalamanPengaturan(),// Indeks 4
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
