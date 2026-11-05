import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';
import 'models/store_setting_model.dart';
import 'core/services/store_setting_service.dart';
import 'halaman_pilih_cabang.dart';
import 'halaman_profil_toko.dart';
import 'halaman_daftar_cabang.dart';
import 'halaman_pengaturan_printer.dart'; 
import 'halaman_metode_pembayaran.dart';

class HalamanPengaturanToko extends StatefulWidget {
  const HalamanPengaturanToko({super.key});

  @override
  State<HalamanPengaturanToko> createState() => _HalamanPengaturanTokoState();
}

class _HalamanPengaturanTokoState extends State<HalamanPengaturanToko> {
  bool _isLoading = true;
  StoreSettingModel _settings = StoreSettingModel(
    enableProducts: true, enableServices: false, enableTableNumber: false, enableOrderType: false
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final data = await StoreSettingService.getSettings();
      if (mounted) setState(() => _settings = data);
      
      // Simpan ke SharedPreferences agar sinkron di kasir
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enable_products', data.enableProducts);
      await prefs.setBool('enable_services', data.enableServices);
      await prefs.setBool('enable_table_number', data.enableTableNumber);
      await prefs.setBool('enable_order_type', data.enableOrderType);
      
    } catch (e) {
      _showNotif("Gagal load pengaturan: ${e.toString().replaceAll('Exception: ', '')}", AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotif(String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _toggleSetting(String key, bool newValue, String title) async {
    final action = newValue ? 'mengaktifkan' : 'menonaktifkan';
    
    // Popup Konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Konfirmasi $title', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        content: Text('Apakah Anda yakin ingin $action fitur $title?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: newValue ? AppColors.primaryEmerald : Colors.orange.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Lanjutkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Optimistic UI Update
    StoreSettingModel oldSettings = _settings;
    setState(() {
      _settings = StoreSettingModel(
        enableProducts: key == 'enable_products' ? newValue : _settings.enableProducts,
        enableServices: key == 'enable_services' ? newValue : _settings.enableServices,
        enableTableNumber: key == 'enable_table_number' ? newValue : _settings.enableTableNumber,
        enableOrderType: key == 'enable_order_type' ? newValue : _settings.enableOrderType,
      );
    });

    try {
      await StoreSettingService.updateSettings({key: newValue ? 1 : 0});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, newValue);
      _showNotif('Berhasil menyimpan pengaturan $title.', AppColors.primaryEmerald);
    } catch (e) {
      // Revert if API fails
      setState(() => _settings = oldSettings);
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pengaturan Bisnis', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd])),
          ),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : ListView(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 40),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('Toko Saat Ini', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13))),
                  _buildGlassMenu(Icons.storefront, 'Profil Toko', 'Ubah nama, alamat, & kontak', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanProfilToko()))),
                  _buildGlassMenu(Icons.payment, 'Metode Pembayaran', 'Atur QRIS, Transfer, & E-Wallet', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanMetodePembayaran()))),
                  
                  const SizedBox(height: 24),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('Personalisasi Kasir', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13))),
                  
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          children: [
                            _buildGlassSwitch('Produk / Barang', 'Aktifkan sistem inventori fisik', _settings.enableProducts, (val) => _toggleSetting('enable_products', val, 'Produk')),
                            const Divider(height: 1, color: AppColors.border),
                            _buildGlassSwitch('Jasa Manual', 'Izinkan kasir menambah jasa khusus', _settings.enableServices, (val) => _toggleSetting('enable_services', val, 'Jasa Manual')),
                            const Divider(height: 1, color: AppColors.border),
                            _buildGlassSwitch('Nomor Meja', 'Wajib input nomor meja (F&B)', _settings.enableTableNumber, (val) => _toggleSetting('enable_table_number', val, 'Nomor Meja')),
                            const Divider(height: 1, color: AppColors.border),
                            _buildGlassSwitch('Jenis Pesanan', 'Pilih Dine In atau Takeaway', _settings.enableOrderType, (val) => _toggleSetting('enable_order_type', val, 'Jenis Pesanan')),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('Perangkat & Operasional', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13))),
                  _buildGlassMenu(Icons.print_outlined, 'Pengaturan Printer', 'Kelola koneksi Bluetooth & Thermal', () async {
                    final prefs = await SharedPreferences.getInstance();
                    String activeStoreId = prefs.getInt('store_id')?.toString() ?? "1"; 
                    if(mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanPengaturanPrinter(storeId: activeStoreId, namaCabang: prefs.getString('nama_toko') ?? 'Toko')));
                  }),
                  
                  const SizedBox(height: 24),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text('Manajemen Cabang', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13))),
                  _buildGlassMenu(Icons.swap_horiz, 'Pindah Cabang', 'Ganti cabang yang aktif', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanPilihCabang()))),
                  _buildGlassMenu(Icons.add_business, 'Kelola & Tambah Cabang', 'Daftar semua cabang bisnis', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanDaftarCabang()))),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildGlassMenu(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primaryEmerald)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSwitch(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      activeColor: AppColors.primaryEmerald,
      activeTrackColor: AppColors.primaryEmerald.withOpacity(0.3),
      inactiveThumbColor: Colors.grey.shade400,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      value: value,
      onChanged: onChanged,
    );
  }
}
