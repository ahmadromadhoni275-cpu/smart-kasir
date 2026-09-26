import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'tema.dart'; // Import tema eksklusif

class HalamanPengaturan extends StatefulWidget {
  const HalamanPengaturan({super.key});

  @override
  State<HalamanPengaturan> createState() => _HalamanPengaturanState();
}

class _HalamanPengaturanState extends State<HalamanPengaturan> {
  final String domainUrl = 'https://smartkasir.shop';
  
  bool isLoading = true;
  bool isSaving = false;
  int _tokoId = 1;

  final TextEditingController _namaTokoCtrl = TextEditingController();
  final TextEditingController _noHpCtrl = TextEditingController();
  final TextEditingController _alamatCtrl = TextEditingController();
  final TextEditingController _ppnCtrl = TextEditingController();
  final TextEditingController _namaBankCtrl = TextEditingController();
  final TextEditingController _rekeningCtrl = TextEditingController();
  final TextEditingController _atasNamaCtrl = TextEditingController();

  String? _qrQrisTersimpan;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tokoId = prefs.getInt('toko_id') ?? 1;
    });
    await _ambilDataToko();
  }

  // ==========================================
  // FUNGSI API PENGATURAN TOKO
  // ==========================================
  Future<void> _ambilDataToko() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/detailToko/$_tokoId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _namaTokoCtrl.text = data['nama_toko'] ?? '';
          _noHpCtrl.text = data['no_hp'] ?? '';
          _alamatCtrl.text = data['alamat'] ?? '';
          _ppnCtrl.text = data['ppn_persen']?.toString() ?? '0';
          _namaBankCtrl.text = data['nama_bank'] ?? '';
          _rekeningCtrl.text = data['rekening_bank'] ?? '';
          _atasNamaCtrl.text = data['atas_nama'] ?? '';
          _qrQrisTersimpan = data['qr_qris'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Gagal mengambil data toko: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _pilihGambarQRIS() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _simpanPengaturan() async {
    if (_namaTokoCtrl.text.isEmpty) {
      _tampilkanNotif('Perhatian', 'Nama toko wajib diisi!', AppColors.premiumGold);
      return;
    }

    setState(() => isSaving = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$domainUrl/api/ubahToko/$_tokoId'));
      
      request.fields['nama_toko'] = _namaTokoCtrl.text;
      request.fields['no_hp'] = _noHpCtrl.text;
      request.fields['alamat'] = _alamatCtrl.text;
      request.fields['ppn_persen'] = _ppnCtrl.text.isEmpty ? '0' : _ppnCtrl.text;
      request.fields['nama_bank'] = _namaBankCtrl.text;
      request.fields['rekening_bank'] = _rekeningCtrl.text;
      request.fields['atas_nama'] = _atasNamaCtrl.text;

      // Lampirkan gambar jika user memilih file baru
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('qr_qris', bytes, filename: _imageFile!.name));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = json.decode(response.body);
        
        // Simpan pembaruan nama toko ke memori lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nama_toko', _namaTokoCtrl.text);

        _tampilkanNotif('Berhasil!', 'Pengaturan toko berhasil diperbarui.', AppColors.emerald);
        
        // Perbarui UI gambar
        if (resData['qr_qris'] != null) {
          setState(() {
            _qrQrisTersimpan = resData['qr_qris'];
            _imageFile = null;
          });
        }
      } else {
        _tampilkanNotif('Gagal', 'Terjadi kesalahan saat menyimpan pengaturan.', AppColors.red);
      }
    } catch (e) {
      _tampilkanNotif('Error Jaringan', 'Gagal menghubungi server: $e', AppColors.red);
    }

    setState(() => isSaving = false);
  }

  void _tampilkanNotif(String judul, String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(warna == AppColors.emerald ? Icons.check_circle : Icons.error_outline, color: AppColors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
                  Text(pesan, style: const TextStyle(fontSize: 12, color: AppColors.white)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ==========================================
  // WIDGET UTAMA (BODY)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        title: const Text('Pengaturan Toko', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER INFO ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: const BoxDecoration(
                      color: AppColors.deepNavy,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.storefront, size: 50, color: AppColors.white),
                        ),
                        const SizedBox(height: 15),
                        const Text('Profil & Informasi Bisnis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                        const SizedBox(height: 5),
                        Text('Lengkapi data toko untuk cetak struk dan pembayaran.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.white.withOpacity(0.7))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- 1. PROFIL TOKO ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Profil Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: _buildCardDecoration(),
                    child: Column(
                      children: [
                        _buildPremiumTextField('Nama Toko', Icons.store, _namaTokoCtrl),
                        _buildPremiumTextField('Nomor WhatsApp (CS)', Icons.phone, _noHpCtrl, isNumber: true),
                        _buildPremiumTextField('Alamat Lengkap', Icons.location_on, _alamatCtrl, maxLines: 3, isLast: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- 2. PENGATURAN TRANSAKSI ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Pengaturan Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: _buildCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPremiumTextField('Pajak (PPN) Otomatis %', Icons.percent, _ppnCtrl, isNumber: true, isLast: true),
                        const SizedBox(height: 8),
                        const Text('*Biarkan 0 jika tidak ingin memungut PPN pada struk.', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- 3. PEMBAYARAN NON-TUNAI ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Metode Pembayaran (Transfer/QRIS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: _buildCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPremiumTextField('Nama Bank / E-Wallet', Icons.account_balance, _namaBankCtrl, hint: 'Contoh: BCA / DANA'),
                        _buildPremiumTextField('Nomor Rekening', Icons.numbers, _rekeningCtrl, isNumber: true),
                        _buildPremiumTextField('Atas Nama (A/N)', Icons.person, _atasNamaCtrl),
                        
                        const Divider(height: 30, color: AppColors.lightGray),
                        const Text('Upload Barcode QRIS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
                        const SizedBox(height: 10),

                        InkWell(
                          onTap: _pilihGambarQRIS,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.smartBlue.withOpacity(0.5), width: 1.5, style: BorderStyle.dash),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: FutureBuilder(
                                      future: _imageFile!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                          return Image.memory(snapshot.data as dynamic, fit: BoxFit.contain);
                                        }
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                    ),
                                  )
                                : (_qrQrisTersimpan != null && _qrQrisTersimpan!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _qrQrisTersimpan!.startsWith('http') 
                                              ? _qrQrisTersimpan! 
                                              : '$domainUrl/uploads/qr/$_qrQrisTersimpan',
                                          fit: BoxFit.contain,
                                          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: AppColors.slateGray, size: 40),
                                        ),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code_scanner, size: 40, color: AppColors.smartBlue),
                                          SizedBox(height: 10),
                                          Text('Ketuk untuk pilih dari galeri', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                                        ],
                                      ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
      // --- BOTTOM ACTION BUTTON ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: isSaving ? null : _simpanPengaturan,
            child: isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Text('Simpan Pengaturan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
    );
  }

  Widget _buildPremiumTextField(String label, IconData icon, TextEditingController controller, {String hint = '', bool isNumber = false, bool isLast = false, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.slateGray, size: 20) : null,
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              filled: true,
              fillColor: AppColors.lightGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: maxLines == 1 ? 0 : 15),
            ),
          ),
        ],
      ),
    );
  }
}
