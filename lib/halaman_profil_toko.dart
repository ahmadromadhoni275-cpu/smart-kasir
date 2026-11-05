import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'tema.dart'; 
import 'core/services/api_service.dart'; 

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

  Future<void> _muatDataToko() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    try {
      _namaController.text = prefs.getString('nama_toko') ?? '';
      _teleponController.text = prefs.getString('telepon_toko') ?? '';
      _alamatController.text = prefs.getString('alamat_toko') ?? '';

      final response = await ApiService.get('stores/current');
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        final dataToko = resData['data'];

        if (dataToko != null) {
          setState(() {
            _namaController.text = dataToko['name'] ?? _namaController.text;
            _teleponController.text = dataToko['phone'] ?? _teleponController.text;
            _alamatController.text = dataToko['address'] ?? _alamatController.text;
          });

          await prefs.setString('nama_toko', _namaController.text);
          await prefs.setString('telepon_toko', _teleponController.text);
          await prefs.setString('alamat_toko', _alamatController.text);
        }
      }
    } catch (e) {
      debugPrint("Gagal muat dari server: $e");
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

  Future<void> _simpanProfilToko() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    try {
      final dataUpdate = {
        'name': _namaController.text.trim(),
        'phone': _teleponController.text.trim(),
        'address': _alamatController.text.trim(),
      };

      final response = await ApiService.put('stores/current', dataUpdate);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nama_toko', _namaController.text.trim());
        await prefs.setString('telepon_toko', _teleponController.text.trim());
        await prefs.setString('alamat_toko', _alamatController.text.trim());
        
        // Memunculkan popup khusus profil
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(children: [Icon(Icons.check_circle, color: AppColors.primaryEmerald), SizedBox(width: 8), Text('Berhasil', style: TextStyle(color: AppColors.primaryEmerald))]),
              content: const Text('Profil toko berhasil diperbarui.'),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Oke', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          );
        }
      } else {
        final res = json.decode(response.body);
        throw Exception(res['message'] ?? 'Gagal memperbarui profil toko');
      }
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Profil Toko', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
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
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 24, left: 16, right: 16, bottom: 40),
                child: Form(
                  key: _formKey,
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
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.15), shape: BoxShape.circle),
                                child: const Icon(Icons.storefront, size: 48, color: AppColors.primaryEmerald),
                              ),
                            ),
                            const SizedBox(height: 32),

                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: AppColors.navyActive, size: 20),
                                SizedBox(width: 8),
                                Text('Informasi Dasar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            TextFormField(
                              controller: _namaController,
                              decoration: InputDecoration(
                                labelText: 'Nama Cabang / Toko',
                                filled: true, fillColor: Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.store_mall_directory_outlined, color: AppColors.textSecondary),
                              ),
                              validator: (val) => val == null || val.isEmpty ? 'Nama toko wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _teleponController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Nomor Telepon',
                                filled: true, fillColor: Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _alamatController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Alamat Lengkap',
                                alignLabelWithHint: true,
                                filled: true, fillColor: Colors.white.withOpacity(0.8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.location_on_outlined, color: AppColors.textSecondary)),
                              ),
                            ),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity, height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryEmerald,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4, shadowColor: AppColors.primaryEmerald.withOpacity(0.5),
                                ),
                                onPressed: _isSaving ? null : _simpanProfilToko,
                                child: _isSaving
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                    : const Text('SIMPAN PERUBAHAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ),
                            ),
                          ],
                        ),
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
