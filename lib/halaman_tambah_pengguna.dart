import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/pengguna_service.dart';

class HalamanTambahPengguna extends StatefulWidget {
  const HalamanTambahPengguna({super.key});

  @override
  State<HalamanTambahPengguna> createState() => _HalamanTambahPenggunaState();
}

class _HalamanTambahPenggunaState extends State<HalamanTambahPengguna> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  String _selectedRole = 'KASIR';
  bool _isLoading = false;

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(color: Colors.white)), backgroundColor: warna));
  }

  Future<void> _simpan() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      _showNotif('Nama dan Email wajib diisi!', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await PenggunaService.invitePengguna({
        'name': _nameCtrl.text,
        'email': _emailCtrl.text,
        'role': _selectedRole,
      });
      _showNotif('Berhasil menambahkan pengguna', AppColors.primaryEmerald);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Karyawan Baru', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data Profil Karyawan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 16),
              
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'Nama Lengkap', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Alamat Email', hintText: 'email@contoh.com', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 24),
              
              const Text('Hak Akses & Peran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.admin_panel_settings_outlined)),
                items: const [
                  DropdownMenuItem(value: 'KASIR', child: Text('Kasir (Akses Transaksi & Shift)')),
                  DropdownMenuItem(value: 'MANAGER', child: Text('Manajer (Akses Laporan & Produk)')),
                  DropdownMenuItem(value: 'OWNER', child: Text('Pemilik (Akses Penuh)')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Karyawan baru akan mendapatkan kata sandi default yang dikirim ke email, atau dapat menggunakan kata sandi SmartKasir123! untuk login pertama kali.', style: TextStyle(fontSize: 11, color: Colors.blue.shade900))),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _isLoading ? null : _simpan,
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('UNDANG KARYAWAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
