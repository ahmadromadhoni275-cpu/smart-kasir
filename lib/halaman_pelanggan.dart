import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tema.dart'; // Import tema eksklusif

class HalamanPelanggan extends StatefulWidget {
  const HalamanPelanggan({super.key});

  @override
  State<HalamanPelanggan> createState() => _HalamanPelangganState();
}

class _HalamanPelangganState extends State<HalamanPelanggan> {
  final String domainUrl = 'https://smartkasir.shop';
  bool isLoading = true;
  int _tokoId = 1;

  List dataPelanggan = [];
  List filteredPelanggan = [];
  TextEditingController searchCtrl = TextEditingController();

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
    await _ambilDataPelanggan();
  }

  // ==========================================
  // FUNGSI API (CRUD)
  // ==========================================
  Future<void> _ambilDataPelanggan() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/daftarPelanggan?toko_id=$_tokoId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() {
          dataPelanggan = res['data'] ?? [];
          filteredPelanggan = dataPelanggan;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Gagal memuat pelanggan: $e");
      setState(() => isLoading = false);
    }
  }

  void _filterPencarian(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredPelanggan = dataPelanggan;
      } else {
        filteredPelanggan = dataPelanggan.where((item) {
          final nama = item['nama']?.toString().toLowerCase() ?? '';
          final noHp = item['no_hp']?.toString().toLowerCase() ?? '';
          final searchLower = keyword.toLowerCase();
          return nama.contains(searchLower) || noHp.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _simpanPelanggan(int? id, String nama, String noHp, String email, String alamat) async {
    final isEdit = id != null;
    final url = isEdit ? Uri.parse('$domainUrl/api/ubahPelanggan/$id') : Uri.parse('$domainUrl/api/tambahPelanggan');
    
    final payload = {
      'toko_id': _tokoId,
      'nama': nama,
      'no_hp': noHp,
      'email': email,
      'alamat': alamat,
    };

    try {
      final response = await (isEdit ? http.put : http.post)(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _tampilkanNotif('Berhasil!', isEdit ? 'Data pelanggan diperbarui.' : 'Pelanggan baru ditambahkan.', AppColors.emerald);
        await _ambilDataPelanggan();
      } else {
        _tampilkanNotif('Gagal!', 'Gagal menyimpan data.', AppColors.red);
      }
    } catch (e) {
      _tampilkanNotif('Error', 'Kesalahan jaringan: $e', AppColors.red);
    }
  }

  Future<void> _hapusPelanggan(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$domainUrl/api/hapusPelanggan/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        _tampilkanNotif('Terhapus', 'Pelanggan berhasil dihapus.', AppColors.emerald);
        await _ambilDataPelanggan();
      }
    } catch (e) {
      debugPrint("Gagal hapus pelanggan: $e");
    }
  }

  void _tampilkanNotif(String judul, String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(warna == AppColors.emerald ? Icons.check_circle : Icons.error_outline, color: AppColors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(pesan, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ==========================================
  // BOTTOM SHEET FORM (Tambah / Edit)
  // ==========================================
  void _tampilkanFormDialog({Map<String, dynamic>? pelangganInfo}) {
    TextEditingController namaCtrl = TextEditingController(text: pelangganInfo?['nama'] ?? '');
    TextEditingController noHpCtrl = TextEditingController(text: pelangganInfo?['no_hp'] ?? '');
    TextEditingController emailCtrl = TextEditingController(text: pelangganInfo?['email'] ?? '');
    TextEditingController alamatCtrl = TextEditingController(text: pelangganInfo?['alamat'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 24, right: 24),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 25),
                Text(pelangganInfo == null ? 'Tambah Pelanggan Baru' : 'Edit Data Pelanggan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                const SizedBox(height: 25),
                
                _buildPremiumTextField('Nama Lengkap', Icons.person, namaCtrl),
                _buildPremiumTextField('Nomor WhatsApp', Icons.phone, noHpCtrl, isNumber: true),
                _buildPremiumTextField('Email (Opsional)', Icons.email, emailCtrl, isEmail: true),
                _buildPremiumTextField('Alamat Lengkap', Icons.location_on, alamatCtrl, maxLines: 2),
                
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      if (namaCtrl.text.isEmpty) {
                        _tampilkanNotif('Peringatan', 'Nama pelanggan wajib diisi!', AppColors.premiumGold);
                        return;
                      }
                      Navigator.pop(context);
                      int? pId = pelangganInfo != null ? int.parse(pelangganInfo['id'].toString()) : null;
                      _simpanPelanggan(pId, namaCtrl.text, noHpCtrl.text, emailCtrl.text, alamatCtrl.text);
                    },
                    child: const Text('Simpan Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumTextField(String label, IconData icon, TextEditingController controller, {bool isNumber = false, bool isEmail = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.slateGray, size: 20) : null,
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

  void _konfirmasiHapus(int id, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pelanggan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hapus data $nama dari daftar pelanggan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.slateGray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(ctx);
              _hapusPelanggan(id);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
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
        title: const Text('Data Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER HALAMAN
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            color: AppColors.lightGray,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daftar Pelanggan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    SizedBox(height: 4),
                    Text('Kelola database pelanggan setia Anda', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _tampilkanFormDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.smartBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),

          // 2. SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: TextField(
              controller: searchCtrl,
              onChanged: _filterPencarian,
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor HP...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.slateGray),
                prefixIcon: const Icon(Icons.search, color: AppColors.slateGray, size: 20),
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. DAFTAR PELANGGAN
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : filteredPelanggan.isEmpty
                    ? const Center(child: Text("Belum ada data pelanggan.", style: TextStyle(color: AppColors.slateGray)))
                    : RefreshIndicator(
                        onRefresh: _ambilDataPelanggan,
                        color: AppColors.teal,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
                          itemCount: filteredPelanggan.length,
                          itemBuilder: (context, index) {
                            var p = filteredPelanggan[index];
                            int idPelanggan = int.parse(p['id'].toString());
                            String inisial = p['nama'].toString().substring(0, 1).toUpperCase();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                children: [
                                  // Avatar Inisial
                                  Container(
                                    width: 45,
                                    height: 45,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.1), shape: BoxShape.circle),
                                    child: Text(inisial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.teal)),
                                  ),
                                  const SizedBox(width: 15),
                                  
                                  // Info Utama
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkText)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone, size: 12, color: AppColors.slateGray),
                                            const SizedBox(width: 4),
                                            Text(p['no_hp'] == null || p['no_hp'] == '' ? '-' : p['no_hp'], style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Tombol Aksi
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: AppColors.slateGray),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    onSelected: (String result) {
                                      if (result == 'edit') {
                                        _tampilkanFormDialog(pelangganInfo: p);
                                      } else if (result == 'hapus') {
                                        _konfirmasiHapus(idPelanggan, p['nama']);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: AppColors.smartBlue), SizedBox(width: 10), Text('Edit Data')])),
                                      const PopupMenuItem<String>(value: 'hapus', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.red), SizedBox(width: 10), Text('Hapus', style: TextStyle(color: AppColors.red))])),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
