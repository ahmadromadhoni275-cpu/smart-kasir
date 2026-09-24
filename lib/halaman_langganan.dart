import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'tema.dart'; // Import tema premium eksklusif

class HalamanLangganan extends StatefulWidget {
  const HalamanLangganan({super.key});

  @override
  State<HalamanLangganan> createState() => _HalamanLanggananState();
}

class _HalamanLanggananState extends State<HalamanLangganan> {
  final String domainUrl = 'https://smartkasir.shop';
  
  bool isLoading = true;
  bool isSaving = false;
  
  int _tokoId = 1;
  String _masaAktif = '-';
  int _sisaHari = 0;
  
  List _paketList = [];
  String _rekeningTujuan = 'Memuat informasi rekening...';
  int? _selectedPaketId;
  
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
    await _ambilPaketLangganan();
    
    setState(() => isLoading = false);
  }

  // Mengambil informasi masa aktif toko saat ini
  Future<void> _ambilDataToko() async {
    try {
      final response = await http.get(Uri.parse('$domainUrl/api/detailToko/$_tokoId'), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        if (data['masa_aktif'] != null) {
          DateTime masaAktifDt = DateTime.parse(data['masa_aktif']);
          DateTime hariIni = DateTime.now();
          setState(() {
            _masaAktif = DateFormat('dd MMMM yyyy', 'id_ID').format(masaAktifDt);
            _sisaHari = masaAktifDt.difference(hariIni).inDays;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat status langganan: $e");
    }
  }

  // Mengambil daftar paket langganan dan rekening tujuan dari API
  Future<void> _ambilPaketLangganan() async {
    try {
      final response = await http.get(Uri.parse('$domainUrl/api/getPaketLangganan'), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() {
          _paketList = res['data'] ?? [];
          _rekeningTujuan = res['rekening_tujuan'] ?? 'BCA 123456789 a/n Smart Kasir';
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat paket langganan: $e");
    }
  }

  Future<void> _pilihBuktiTransfer() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _prosesPembayaran() async {
    if (_selectedPaketId == null) {
      _tampilkanNotif('Pilih Paket', 'Silakan pilih paket langganan terlebih dahulu.', AppColors.premiumGold);
      return;
    }
    if (_imageFile == null) {
      _tampilkanNotif('Bukti Transfer Kosong', 'Harap unggah bukti transfer pembayaran Anda.', AppColors.red);
      return;
    }

    setState(() => isSaving = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$domainUrl/api/beliPaket'));
      request.fields['toko_id'] = _tokoId.toString();
      request.fields['paket_id'] = _selectedPaketId.toString();
      request.fields['metode'] = 'manual';

      final bytes = await _imageFile!.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('bukti_bayar', bytes, filename: _imageFile!.name));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = json.decode(response.body);
        _tampilkanNotif('Berhasil!', resData['message'] ?? 'Bukti pembayaran terkirim. Menunggu verifikasi admin pusat.', AppColors.emerald);
        
        // Reset form setelah sukses
        setState(() {
          _selectedPaketId = null;
          _imageFile = null;
        });
        
        // Arahkan kembali ke dashboard atau pop up konfirmasi
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _tampilkanNotif('Gagal', 'Terjadi kesalahan saat memproses pembayaran. (Error: ${response.statusCode})', AppColors.red);
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
            Icon(warna == AppColors.emerald ? Icons.check_circle : (warna == AppColors.red ? Icons.error_outline : Icons.info_outline), color: AppColors.white),
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

  String _formatRupiah(int angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
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
        title: const Text('Langganan Sistem', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.white),
            tooltip: 'Riwayat Pembayaran',
            onPressed: () {
              // Navigasi ke Riwayat Langganan (Jika ada)
              _tampilkanNotif('Info', 'Fitur Riwayat Pembayaran akan segera hadir.', AppColors.smartBlue);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- KARTU STATUS MEMBER VIP ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(25),
                    decoration: const BoxDecoration(
                      color: AppColors.deepNavy,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.darkBlue, AppColors.smartBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('SMART KASIR PRO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.white, letterSpacing: 1.5)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _sisaHari > 0 ? AppColors.emerald : AppColors.red, borderRadius: BorderRadius.circular(20)),
                                child: Text(_sisaHari > 0 ? 'AKTIF' : 'KEDALUWARSA', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.white)),
                              )
                            ],
                          ),
                          const SizedBox(height: 25),
                          const Text('Masa Aktif Sampai:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 5),
                          Text(_masaAktif, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white)),
                          const SizedBox(height: 5),
                          Text(
                            _sisaHari > 0 ? 'Tersisa $_sisaHari hari lagi' : 'Masa aktif telah habis. Akses kasir terkunci.',
                            style: TextStyle(color: _sisaHari > 0 ? AppColors.premiumGold : AppColors.red, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // --- PILIHAN PAKET EKSKLUSIF ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Pilih Paket Perpanjangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                  ),
                  const SizedBox(height: 15),

                  if (_paketList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Belum ada paket tersedia.', style: TextStyle(color: AppColors.slateGray)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _paketList.length,
                      itemBuilder: (context, index) {
                        var paket = _paketList[index];
                        int idPaket = int.parse(paket['id'].toString());
                        bool isSelected = _selectedPaketId == idPaket;
                        int harga = int.parse(paket['harga'].toString());

                        return GestureDetector(
                          onTap: () => setState(() => _selectedPaketId = idPaket),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.teal.withOpacity(0.05) : AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isSelected ? AppColors.teal : Colors.grey.shade200, width: isSelected ? 2 : 1),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                // Radio Icon
                                Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? AppColors.teal : AppColors.slateGray),
                                const SizedBox(width: 15),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(paket['nama_paket'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkText)),
                                      const SizedBox(height: 4),
                                      Text(paket['deskripsi'] ?? 'Perpanjangan sistem full akses', style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                                    ],
                                  ),
                                ),
                                
                                // Harga
                                Text(_formatRupiah(harga), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? AppColors.teal : AppColors.smartBlue)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 25),

                  // --- INFO TRANSFER & UPLOAD BUKTI ---
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Instruksi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transfer ke Rekening Pusat:', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.dash)),
                          child: SelectableText(
                            _rekeningTujuan,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        const Text('Upload Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText)),
                        const SizedBox(height: 10),
                        
                        InkWell(
                          onTap: _pilihBuktiTransfer,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.smartBlue.withOpacity(0.5), width: 1.5, style: BorderStyle.dash),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    // Membaca file lokal menggunakan ImageProvider memori/future (untuk Web & Android)
                                    child: FutureBuilder(
                                      future: _imageFile!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                          return Image.memory(snapshot.data as dynamic, fit: BoxFit.cover);
                                        }
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.smartBlue),
                                      SizedBox(height: 10),
                                      Text('Ketuk untuk unggah foto/screenshot', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
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
            onPressed: (isSaving || isLoading) ? null : _prosesPembayaran,
            child: isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                : const Text('Kirim Bukti Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}
