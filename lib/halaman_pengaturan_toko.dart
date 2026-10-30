import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'tema.dart';
import 'halaman_pilih_cabang.dart';
import 'halaman_profil_toko.dart';
import 'halaman_daftar_cabang.dart';
import 'halaman_pengaturan_printer.dart'; 
import 'core/services/api_service.dart';

class HalamanPengaturanToko extends StatefulWidget {
  const HalamanPengaturanToko({super.key});

  @override
  State<HalamanPengaturanToko> createState() => _HalamanPengaturanTokoState();
}

class _HalamanPengaturanTokoState extends State<HalamanPengaturanToko> {
  bool _enableTableNumber = false;
  bool _enableServices = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 1. Muat Pengaturan dari Lokal & Sinkronkan dengan Server
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableTableNumber = prefs.getBool('enable_table_number') ?? false;
      _enableServices = prefs.getBool('enable_services') ?? false;
    });

    try {
      final res = await ApiService.get('profile/store'); // Asumsi endpoint profil toko
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        setState(() {
          _enableTableNumber = data['enable_table_number'] == 1 || data['enable_table_number'] == true;
          _enableServices = data['enable_services'] == 1 || data['enable_services'] == true;
        });
        await prefs.setBool('enable_table_number', _enableTableNumber);
        await prefs.setBool('enable_services', _enableServices);
      }
    } catch (e) {
      debugPrint("Gagal load pengaturan toko: $e");
    }

    setState(() => _isLoading = false);
  }

  // 2. Simpan Perubahan Saklar ke Database via API
  Future<void> _toggleSetting(String key, bool value) async {
    // Update UI dulu agar responsif
    setState(() {
      if (key == 'enable_table_number') _enableTableNumber = value;
      if (key == 'enable_services') _enableServices = value;
    });

    // Simpan ke lokal
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    // Kirim ke backend (Update tabel stores)
    try {
      final res = await ApiService.post('profile/store/settings', {
        key: value ? 1 : 0
      });
      if (res.statusCode != 200) {
        throw Exception('Gagal menyimpan ke server');
      }
    } catch (e) {
      // Jika gagal, kembalikan posisi saklar
      setState(() {
        if (key == 'enable_table_number') _enableTableNumber = !value;
        if (key == 'enable_services') _enableServices = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan perubahan ke server.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan Bisnis', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Toko Saat Ini', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          _buildMenuTile(
            context, Icons.storefront, 'Profil Toko', 'Ubah nama, alamat, & kontak', 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanProfilToko()))
          ),
          const SizedBox(height: 16),

          // --- FITUR KASIR DINAMIS (ON/OFF) ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Personalisasi Kasir', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          Card(
            elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: AppColors.primaryEmerald,
                  title: const Text('Input Nomor Meja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Tampilkan input nomor meja saat kasir checkout', style: TextStyle(fontSize: 12)),
                  value: _enableTableNumber,
                  onChanged: (val) => _toggleSetting('enable_table_number', val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  activeColor: AppColors.primaryEmerald,
                  title: const Text('Izinkan Jasa Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Izinkan kasir menambahkan jasa di luar katalog', style: TextStyle(fontSize: 12)),
                  value: _enableServices,
                  onChanged: (val) => _toggleSetting('enable_services', val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- TAMBAHAN MENU PRINTER ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Perangkat & Operasional', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          _buildMenuTile(
            context, Icons.print_outlined, 'Pengaturan Printer', 'Kelola koneksi & ukuran kertas struk', 
            () async {
              final prefs = await SharedPreferences.getInstance();
              String activeStoreId = prefs.getInt('store_id')?.toString() ?? "1"; 
              Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanPengaturanPrinter(storeId: activeStoreId)));
            }
          ),
          const SizedBox(height: 16),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Manajemen Cabang', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          _buildMenuTile(
            context, Icons.swap_horiz, 'Pindah Cabang', 'Ganti cabang yang aktif', 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanPilihCabang()))
          ),
          _buildMenuTile(
            context, Icons.add_business, 'Kelola & Tambah Cabang', 'Daftar semua cabang bisnis', 
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanDaftarCabang()))
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.primaryEmerald)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
