import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/store_service.dart'; // Pastikan path ini sesuai dengan letak service Anda

class HalamanTambahCabang extends StatefulWidget {
  const HalamanTambahCabang({super.key});

  @override
  State<HalamanTambahCabang> createState() => _HalamanTambahCabangState();
}

class _HalamanTambahCabangState extends State<HalamanTambahCabang> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  
  String _status = 'ACTIVE';
  bool _isLoading = false;

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan, style: const TextStyle(color: Colors.white)), backgroundColor: warna),
    );
  }

  Future<void> _simpan() async {
    if (_nameCtrl.text.isEmpty) {
      _showNotif('Nama cabang wajib diisi!', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Data yang akan dikirim ke Backend CI4
      final data = {
        'name': _nameCtrl.text,
        'phone': _phoneCtrl.text,
        'address': _addressCtrl.text,
        'status': _status,
      };

      // Memanggil fungsi createStore (yang sudah kita buat di StoreService sebelumnya)
      // Jika Backend menolak karena batas langganan, ia akan melempar Exception yang ditangkap di catch
      await StoreService.createStore(data);
      
      _showNotif('Cabang baru berhasil dibuat!', AppColors.primaryEmerald);
      if (mounted) Navigator.pop(context, true); // Kembali dengan parameter true agar halaman sebelumnya me-refresh
      
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
        title: const Text('Tambah Cabang Baru', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: AppColors.border)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Informasi Cabang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 16),
              
              // NAMA CABANG
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Cabang *', 
                  hintText: 'Misal: Cabang Sudirman',
                  filled: true, 
                  fillColor: AppColors.lightGray, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                  prefixIcon: const Icon(Icons.storefront)
                ),
              ),
              const SizedBox(height: 16),
              
              // NOMOR TELEPON
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor Telepon', 
                  hintText: '08xxxxxxxxxx',
                  filled: true, 
                  fillColor: AppColors.lightGray, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                  prefixIcon: const Icon(Icons.phone)
                ),
              ),
              const SizedBox(height: 16),
              
              // ALAMAT LENGKAP
              TextField(
                controller: _addressCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Alamat Lengkap', 
                  alignLabelWithHint: true,
                  filled: true, 
                  fillColor: AppColors.lightGray, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 30), // Menyesuaikan posisi icon untuk multi-line
                    child: Icon(Icons.location_on_outlined),
                  )
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Status Operasional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 16),
              
              // STATUS CABANG (ACTIVE / INACTIVE)
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  filled: true, 
                  fillColor: AppColors.lightGray, 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                  prefixIcon: const Icon(Icons.check_circle_outline)
                ),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Aktif (Bisa digunakan)')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Nonaktif (Sementara tutup)')),
                ],
                onChanged: (val) => setState(() => _status = val!),
              ),
              
              const SizedBox(height: 32),
              
              // TOMBOL SIMPAN
              SizedBox(
                width: double.infinity, 
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: _isLoading ? null : _simpan,
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('SIMPAN CABANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
