import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart';

// Import halaman edit dan ganti kata sandi jika sudah Anda buat:
// import 'halaman_edit_profil_akun.dart';
// import 'halaman_ganti_kata_sandi.dart';

class HalamanProfilAkun extends StatefulWidget {
  const HalamanProfilAkun({super.key});

  @override
  State<HalamanProfilAkun> createState() => _HalamanProfilAkunState();
}

class _HalamanProfilAkunState extends State<HalamanProfilAkun> {
  String _nama = 'Memuat...';
  String _role = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nama = prefs.getString('username') ?? 'User Kasir';
      _role = prefs.getString('role') ?? 'KASIR';
      _email = 'email@contoh.com'; // Diambil dari API ProfileService nantinya
    });
  }

  Future<void> _konfirmasiKeluar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Sesi kasir Anda saat ini akan diakhiri. Pastikan shift Anda sudah ditutup jika diperlukan.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Hapus token JWT dan data sesi
      if (mounted) {
        // Navigasi paksa ke halaman Login (ganti 'HalamanLogin' sesuai nama kelas login Anda)
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Akun', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // KARTU IDENTITAS
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                CircleAvatar(radius: 40, backgroundColor: AppColors.primaryEmerald.withOpacity(0.1), child: const Icon(Icons.person, size: 40, color: AppColors.primaryEmerald)),
                const SizedBox(height: 16),
                Text(_nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                const SizedBox(height: 4),
                Text(_email, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text('Peran Anda: $_role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          // MENU PENGATURAN
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text('Pengaturan Pribadi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
          ),
          _buildMenuTile(Icons.edit_outlined, 'Edit Profil', 'Ubah nama dan info kontak', () {
             // Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanEditProfilAkun()));
          }),
          _buildMenuTile(Icons.lock_outline, 'Ganti Kata Sandi', 'Tingkatkan keamanan akun', () {
             // Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanGantiKataSandi()));
          }),
          const SizedBox(height: 24),
          
          // TOMBOL LOGOUT
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade200))),
            onPressed: _konfirmasiKeluar,
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari Aplikasi', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.border)),
      child: ListTile(
        onTap: onTap,
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: AppColors.navyActive)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
