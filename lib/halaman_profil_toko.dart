import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'tema.dart'; // Pastikan tema.dart memuat AppColors.lightGray & AppColors.primaryEmerald
import 'core/services/api_service.dart'; // Jika Anda ingin langsung menembak API dari sini

class HalamanProfilToko extends StatefulWidget {
  const HalamanProfilToko({super.key});

  @override
  State<HalamanProfilToko> createState() => _HalamanProfilTokoState();
}

class _HalamanProfilTokoState extends State<HalamanProfilToko> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _muatDataToko();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _muatDataToko() async {
    setState(() => _isLoading = true);
    try {
      // Mengambil data toko yang tersimpan di sesi lokal (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      _namaController.text = prefs.getString('nama_toko') ?? '';
      _teleponController.text = prefs.getString('telepon_toko') ?? '';
      _alamatController.text = prefs.getString('alamat_toko') ?? '';
    } catch (e) {
      debugPrint("Gagal memuat profil toko: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _simpanProfilToko() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    try {
      // 1. Format data yang akan dikirim
      final dataUpdate = {
        'name': _namaController.text.trim(),
        'phone': _teleponController.text.trim(),
        'address': _alamatController.text.trim(),
      };

      // 2. Panggil API untuk update toko saat ini (endpoint PUT /stores/current)
      final response = await ApiService.put('stores/current', dataUpdate);

      if (response.statusCode == 200) {
        // 3. Update SharedPreferences lokal agar UI navigasi ikut berubah
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nama_toko', _namaController.text.trim());
        await prefs.setString('telepon_toko', _teleponController.text.trim());
        await prefs.setString('alamat_toko', _alamatController.text.trim());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil toko berhasil diperbarui!'), backgroundColor: AppColors.primaryEmerald),
        );
        Navigator.pop(context); // Kembali ke halaman Pengaturan Toko
      } else {
        final res = json.decode(response.body);
        throw Exception(res['message'] ?? 'Gagal memperbarui profil toko');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Latar abu-abu terang
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profil Toko', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER IKON ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront, size: 48, color: AppColors.primaryEmerald),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- FORM INPUT ---
                  const Text('Informasi Dasar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  
                  // NAMA TOKO
                  TextFormField(
                    controller: _namaController,
                    decoration: InputDecoration(
                      labelText: 'Nama Cabang / Toko',
                      filled: true,
                      fillColor: AppColors.lightGray,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.store_mall_directory_outlined, color: Colors.grey),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Nama toko tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),

                  // TELEPON TOKO
                  TextFormField(
                    controller: _teleponController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Nomor Telepon Toko',
                      filled: true,
                      fillColor: AppColors.lightGray,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.phone_outlined, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ALAMAT TOKO
                  TextFormField(
                    controller: _alamatController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Alamat Lengkap',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: AppColors.lightGray,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40), // Agar ikon sejajar atas
                        child: Icon(Icons.location_on_outlined, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- TOMBOL SIMPAN ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSaving ? null : _simpanProfilToko,
                      child: _isSaving
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
