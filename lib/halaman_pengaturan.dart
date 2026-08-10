import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'halaman_bantuan.dart';
import 'halaman_notifikasi.dart';
import 'halaman_referral.dart'; // IMPORT HALAMAN REFERRAL

class HalamanPengaturan extends StatefulWidget {
  const HalamanPengaturan({super.key});

  @override
  State<HalamanPengaturan> createState() => _HalamanPengaturanState();
}

class _HalamanPengaturanState extends State<HalamanPengaturan> {
  // URL Domain telah disesuaikan ke hosting AnymHost Anda
  final String domainUrl = 'https://smartkasir.shop';
  late final String baseUrl;

  final TextEditingController _namaCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _alamatCtrl = TextEditingController();
  final TextEditingController _noHpCtrl = TextEditingController();

  final TextEditingController _namaBankCtrl = TextEditingController();
  final TextEditingController _rekeningCtrl = TextEditingController();
  final TextEditingController _atasNamaCtrl = TextEditingController();
  final TextEditingController _ppnCtrl = TextEditingController();

  String _paketLangganan = '-';
  String _masaAktif = '-';
  int _saldoDeposit = 0;

  String? _qrUrl;
  Uint8List? _serverImageBytes;

  bool isLoading = true;
  bool isSaving = false;
  int _tokoId = 1;

  Uint8List? _imageBytes;
  String? _imageName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    baseUrl = '$domainUrl/api/toko';
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tokoId = prefs.getInt('toko_id') ?? 1;
      _emailCtrl.text = prefs.getString('email') ?? 'Email belum diatur';
    });
    // Panggil data pertama kali dengan loading layar penuh
    ambilDataToko();
  }

  // FITUR BARU: Tambahkan parameter isRefresh agar saat simpan, layar tidak kedip
  Future<void> ambilDataToko({bool isRefresh = false}) async {
    if (!isRefresh) setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/$_tokoId'),
          headers: {'ngrok-skip-browser-warning': 'true'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _namaCtrl.text = data['nama_toko'] ?? '';
          _alamatCtrl.text = data['alamat'] ?? '';
          _noHpCtrl.text = data['no_hp'] ?? '';
          _namaBankCtrl.text = data['nama_bank'] ?? '';
          _rekeningCtrl.text = data['rekening_bank'] ?? '';
          _atasNamaCtrl.text = data['atas_nama'] ?? '';
          _ppnCtrl.text = data['ppn_persen']?.toString() ?? '0';

          _paketLangganan = data['paket_langganan'] ?? 'Trial';
          _masaAktif = data['masa_aktif'] ?? '-';
          _saldoDeposit = int.parse(data['saldo_deposit']?.toString() ?? '0');

          _qrUrl = data['qr_qris'];
          isLoading = false;
        });

        if (_qrUrl != null && _qrUrl!.isNotEmpty) {
          _unduhGambarServer();
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _unduhGambarServer() async {
    try {
      // FITUR ANTI-CACHE: Tambahkan waktu sekarang ke URL agar Flutter Web selalu menarik gambar terbaru
      String waktuSekarang = DateTime.now().millisecondsSinceEpoch.toString();
      final url = Uri.parse(
          '$domainUrl/api/tampilGambar?file=$_qrUrl&v=$waktuSekarang');

      final res =
          await http.get(url, headers: {'ngrok-skip-browser-warning': 'true'});

      if (res.statusCode == 200) {
        setState(() {
          _serverImageBytes = res.bodyBytes;
        });
      } else {
        setState(() {
          _qrUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _qrUrl = null;
      });
      debugPrint('Gagal memuat gambar: $e');
    }
  }

  Future<void> _pilihGambar() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });
    }
  }

  Future<void> simpanPerubahan() async {
    if (_namaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nama Toko wajib diisi!'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => isSaving = true);

    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/$_tokoId'));
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.fields['nama_toko'] = _namaCtrl.text;
      request.fields['alamat'] = _alamatCtrl.text;
      request.fields['no_hp'] = _noHpCtrl.text;
      request.fields['nama_bank'] = _namaBankCtrl.text;
      request.fields['rekening_bank'] = _rekeningCtrl.text;
      request.fields['atas_nama'] = _atasNamaCtrl.text;
      request.fields['ppn_persen'] =
          _ppnCtrl.text.isEmpty ? '0' : _ppnCtrl.text;

      if (_imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('qr_qris', _imageBytes!,
            filename: _imageName ?? 'upload_qr.jpg'));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => isSaving = false);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Profil toko berhasil diperbarui!'),
              backgroundColor: Colors.green));
          FocusScope.of(context).unfocus();

          setState(() {
            // LOGIKA CERDAS: Langsung jadikan gambar lokal (yang baru diunggah) sebagai gambar utama
            // Hal ini membuat gambar langsung muncul tanpa kedip atau jeda unduh.
            if (_imageBytes != null) {
              _serverImageBytes = _imageBytes;
              _imageBytes = null;
            }
          });

          // Sinkronkan data toko di latar belakang (tanpa efek loading putih)
          ambilDataToko(isRefresh: true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Gagal menyimpan perubahan.'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kesalahan jaringan saat menyimpan.'),
            backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildTextField(
      String label, IconData icon, TextEditingController controller,
      {int lines = 1,
      TextInputType type = TextInputType.text,
      bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: lines,
        keyboardType: type,
        readOnly: isReadOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: lines == 1
              ? Icon(icon, color: isReadOnly ? Colors.grey : Colors.blueAccent)
              : null,
          filled: true,
          fillColor: isReadOnly ? Colors.grey[200] : Colors.grey[50],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  String _formatRupiah(int angka) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(angka);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pengaturan Toko',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white),
            tooltip: 'Notifikasi & Peringatan',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HalamanNotifikasi()));
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- KARTU LANGGANAN ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Colors.purple, Colors.deepPurpleAccent]),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Langganan Sistem',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Paket: ${_paketLangganan.toUpperCase()}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Masa Aktif',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                  Text(_masaAktif,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold))
                                ]),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Saldo Deposit',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                  Text(_formatRupiah(_saldoDeposit),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold))
                                ]),
                          ],
                        ),
                        const Divider(color: Colors.white30, height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Menghubungkan ke Payment Gateway Otomatis...')));
                            },
                            icon: const Icon(Icons.payment),
                            label: const Text('Perpanjang Masa Aktif / Deposit',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- KARTU PUSAT BANTUAN ---
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child:
                              Icon(Icons.support_agent, color: Colors.white)),
                      title: const Text('Pusat Bantuan',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          'Punya kendala? Chat atau hubungi admin pusat.'),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HalamanBantuan()));
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // =======================================================
                  // --- FITUR BARU: MENU REFERRAL / UNDANG TEMAN ---
                  // =======================================================
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child:
                              Icon(Icons.card_giftcard, color: Colors.white)),
                      title: const Text('Program Undang Teman',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          'Dapatkan gratis masa aktif toko 30 hari!'),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HalamanReferral()));
                      },
                    ),
                  ),
                  // =======================================================

                  const SizedBox(height: 25),
                  const Text('Informasi Dasar Toko',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // --- FORM INFORMASI TOKO ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        _buildTextField(
                            'Nama Toko', Icons.storefront, _namaCtrl),
                        _buildTextField(
                            'Email Akun (Hanya Baca)', Icons.email, _emailCtrl,
                            type: TextInputType.emailAddress, isReadOnly: true),
                        _buildTextField(
                            'No HP / WhatsApp', Icons.phone, _noHpCtrl,
                            type: TextInputType.phone),
                        _buildTextField(
                            'Alamat Lengkap', Icons.location_on, _alamatCtrl,
                            lines: 3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text('Rekening & Pembayaran Non-Tunai',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // --- FORM PEMBAYARAN & QRIS ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField('Nama Bank (Misal: BCA / Mandiri)',
                            Icons.account_balance, _namaBankCtrl),
                        _buildTextField(
                            'Nomor Rekening', Icons.numbers, _rekeningCtrl,
                            type: TextInputType.number),
                        _buildTextField(
                            'Atas Nama (a/n)', Icons.person, _atasNamaCtrl),
                        _buildTextField(
                            'Persentase PPN (%)', Icons.percent, _ppnCtrl,
                            type: TextInputType.number),
                        const Divider(height: 30),
                        const Text('Upload Barcode QRIS / Rekening',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: _pilihGambar,
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: Colors.grey.shade400,
                                    style: BorderStyle.solid)),
                            child: _imageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.memory(_imageBytes!,
                                        fit: BoxFit.contain))
                                : (_serverImageBytes != null)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.memory(_serverImageBytes!,
                                            fit: BoxFit.contain))
                                    : (_qrUrl != null && _qrUrl!.isNotEmpty)
                                        ? const Center(
                                            child: CircularProgressIndicator())
                                        : const Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.qr_code_scanner,
                                                  size: 50, color: Colors.grey),
                                              SizedBox(height: 10),
                                              Text(
                                                  'Ketuk untuk pilih gambar dari galeri',
                                                  style: TextStyle(
                                                      color: Colors.grey))
                                            ],
                                          ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  
                  // --- TOMBOL SIMPAN ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      onPressed: isSaving ? null : simpanPerubahan,
                      icon: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save, color: Colors.white),
                      label: const Text('Simpan Data Toko',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
