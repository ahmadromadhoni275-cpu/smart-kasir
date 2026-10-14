import 'package:flutter/material.dart';
import 'tema.dart';
import 'halaman_pilih_cabang.dart';
import 'halaman_profil_toko.dart';
import 'halaman_daftar_cabang.dart';

class HalamanPengaturanToko extends StatelessWidget {
  const HalamanPengaturanToko({super.key});

  @override
  Widget build(BuildContext context) {
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
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanProfilToko()))
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
            () {
              // Navigasi ke HalamanDaftarCabang (Jika Anda membuat halamannya terpisah)
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanDaftarCabang()));
            }
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primaryEmerald),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
