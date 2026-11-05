import 'dart:ui';
import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/store_service.dart'; 

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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _simpan() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showNotif('Nama cabang wajib diisi!', Colors.orange.shade700);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'status': _status,
      };

      await StoreService.createStore(data);
      
      _showNotif('Cabang baru berhasil dibuat!', AppColors.primaryEmerald);
      if (mounted) Navigator.pop(context, true); 
      
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tambah Cabang Baru', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
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
          
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 24, left: 16, right: 16, bottom: 40),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storefront, color: AppColors.navyActive, size: 20),
                          SizedBox(width: 8),
                          Text('Informasi Cabang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nama Cabang *', 
                          hintText: 'Misal: Cabang Sudirman',
                          filled: true, fillColor: Colors.white.withOpacity(0.8), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                          prefixIcon: const Icon(Icons.store_mall_directory_outlined, color: AppColors.textSecondary)
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Nomor Telepon', 
                          hintText: '08xxxxxxxxxx',
                          filled: true, fillColor: Colors.white.withOpacity(0.8), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary)
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _addressCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Alamat Lengkap', 
                          alignLabelWithHint: true,
                          filled: true, fillColor: Colors.white.withOpacity(0.8), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                          prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.location_on_outlined, color: AppColors.textSecondary))
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      const Row(
                        children: [
                          Icon(Icons.toggle_on_outlined, color: AppColors.navyActive, size: 20),
                          SizedBox(width: 8),
                          Text('Status Operasional', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          filled: true, fillColor: Colors.white.withOpacity(0.8), 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                          prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.textSecondary)
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ACTIVE', child: Text('Aktif (Bisa digunakan)')),
                          DropdownMenuItem(value: 'INACTIVE', child: Text('Nonaktif (Sementara tutup)')),
                        ],
                        onChanged: (val) => setState(() => _status = val!),
                      ),
                      
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryEmerald, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4, shadowColor: AppColors.primaryEmerald.withOpacity(0.5)
                          ),
                          onPressed: _isLoading ? null : _simpan,
                          child: _isLoading 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                            : const Text('SIMPAN CABANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
