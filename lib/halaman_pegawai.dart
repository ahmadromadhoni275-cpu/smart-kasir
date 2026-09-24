import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'tema.dart'; // Import tema eksklusif

class HalamanPegawai extends StatefulWidget {
  const HalamanPegawai({super.key});

  @override
  State<HalamanPegawai> createState() => _HalamanPegawaiState();
}

class _HalamanPegawaiState extends State<HalamanPegawai> {
  final String domainUrl = 'https://smartkasir.shop';
  bool isLoading = true;
  int _tokoId = 1;
  List dataPegawai = [];

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
    await _ambilDataPegawai();
  }

  // ==========================================
  // FUNGSI API PENGGUNA
  // ==========================================
  Future<void> _ambilDataPegawai() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/daftarPegawai?toko_id=$_tokoId'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() {
          dataPegawai = res['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Gagal mengambil data pegawai: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _tambahPegawai(String username, String email, String noWa, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$domainUrl/api/tambahPegawai'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'toko_id': _tokoId,
          'username': username,
          'email': email,
          'no_wa': noWa,
          'password': password,
          'role': 'kasir', // Default role yang didaftarkan admin adalah kasir
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _tampilkanNotif('Berhasil!', 'Pegawai baru berhasil ditambahkan.', AppColors.emerald);
        await _ambilDataPegawai();
      } else {
        final res = json.decode(response.body);
        _tampilkanNotif('Gagal!', res['message'] ?? 'Gagal menambahkan pegawai.', AppColors.red);
      }
    } catch (e) {
      _tampilkanNotif('Error', 'Kesalahan jaringan: $e', AppColors.red);
    }
  }

  Future<void> _ubahStatusAktif(int id, int statusBaru) async {
    try {
      final response = await http.put(
        Uri.parse('$domainUrl/api/ubahStatusPegawai/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'is_active': statusBaru}),
      );

      if (response.statusCode == 200) {
        _tampilkanNotif('Diperbarui', 'Status pegawai berhasil diubah.', AppColors.smartBlue);
      } else {
        await _ambilDataPegawai(); // Rollback jika gagal
      }
    } catch (e) {
      debugPrint("Gagal mengubah status: $e");
      await _ambilDataPegawai(); // Rollback UI
    }
  }

  Future<void> _hapusPegawai(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$domainUrl/api/hapusPegawai/$id'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        _tampilkanNotif('Terhapus', 'Akun pegawai berhasil dihapus.', AppColors.emerald);
        await _ambilDataPegawai();
      } else {
        _tampilkanNotif('Gagal', 'Tidak dapat menghapus pegawai.', AppColors.red);
      }
    } catch (e) {
      debugPrint("Gagal hapus pegawai: $e");
    }
  }

  void _tampilkanNotif(String judul, String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(warna == AppColors.red ? Icons.error_outline : Icons.check_circle, color: AppColors.white),
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
  // BOTTOM SHEET FORM (Tambah Pegawai)
  // ==========================================
  void _tampilkanFormTambah() {
    TextEditingController userCtrl = TextEditingController();
    TextEditingController emailCtrl = TextEditingController();
    TextEditingController waCtrl = TextEditingController();
    TextEditingController passCtrl = TextEditingController();
    bool isObscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    const Text('Tambah Pegawai (Kasir)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    const SizedBox(height: 5),
                    const Text('Tambahkan akun kasir baru untuk toko Anda.', style: TextStyle(color: AppColors.slateGray, fontSize: 13)),
                    const SizedBox(height: 25),

                    _buildPremiumTextField('Username (Tanpa Spasi)', Icons.person, userCtrl),
                    _buildPremiumTextField('Email (Opsional)', Icons.email, emailCtrl, isEmail: true),
                    _buildPremiumTextField('No WhatsApp (Opsional)', Icons.phone, waCtrl, isNumber: true),
                    
                    // Field Password Khusus
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Password Akun', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: passCtrl,
                            obscureText: isObscure,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock, color: AppColors.slateGray, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: AppColors.slateGray, size: 20),
                                onPressed: () => setModalState(() => isObscure = !isObscure),
                              ),
                              filled: true,
                              fillColor: AppColors.lightGray,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                            _tampilkanNotif('Peringatan', 'Username dan Password wajib diisi!', AppColors.red);
                            return;
                          }
                          Navigator.pop(context);
                          _tambahPegawai(userCtrl.text.replaceAll(' ', ''), emailCtrl.text, waCtrl.text, passCtrl.text);
                        },
                        child: const Text('Buat Akun Kasir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumTextField(String label, IconData icon, TextEditingController controller, {bool isNumber = false, bool isEmail = false}) {
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
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.slateGray, size: 20),
              filled: true,
              fillColor: AppColors.lightGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _konfirmasiHapus(int id, String username) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Pegawai?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus akun $username secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.slateGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(ctx);
              _hapusPegawai(id);
            },
            child: const Text('Ya, Hapus', style: TextStyle(color: AppColors.white)),
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
                    Text('Data Pegawai', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    SizedBox(height: 4),
                    Text('Kelola akses pengguna & kasir toko', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _tampilkanFormTambah,
                  icon: const Icon(Icons.person_add, size: 18),
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

          // 2. DAFTAR PEGAWAI (KARTU ELEGAN)
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : dataPegawai.isEmpty
                    ? const Center(child: Text("Belum ada pegawai/kasir.", style: TextStyle(color: AppColors.slateGray)))
                    : RefreshIndicator(
                        onRefresh: _ambilDataPegawai,
                        color: AppColors.teal,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80, top: 10),
                          itemCount: dataPegawai.length,
                          itemBuilder: (context, index) {
                            var p = dataPegawai[index];
                            int idPegawai = int.parse(p['id'].toString());
                            bool isActive = p['is_active'].toString() == '1';
                            String statusShift = p['status_shift'] ?? 'closed';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                children: [
                                  // Ikon Profil
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(color: isActive ? AppColors.teal.withOpacity(0.1) : Colors.grey.shade200, shape: BoxShape.circle),
                                    child: Icon(Icons.person, color: isActive ? AppColors.teal : Colors.grey.shade400, size: 28),
                                  ),
                                  const SizedBox(width: 15),
                                  
                                  // Informasi Akun
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(p['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                                            const SizedBox(width: 8),
                                            // Badge Shift Kasir
                                            if (statusShift == 'open')
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(color: AppColors.premiumGold.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                                child: const Text('Shift Aktif', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange)),
                                              )
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            const Icon(Icons.email, size: 12, color: AppColors.slateGray),
                                            const SizedBox(width: 4),
                                            Text(p['email'] ?? 'Tidak ada email', style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Kontrol Status & Hapus
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Switch(
                                        value: isActive,
                                        activeColor: AppColors.emerald,
                                        inactiveThumbColor: Colors.grey.shade400,
                                        inactiveTrackColor: Colors.grey.shade200,
                                        onChanged: (val) {
                                          setState(() => dataPegawai[index]['is_active'] = val ? 1 : 0);
                                          _ubahStatusAktif(idPegawai, val ? 1 : 0);
                                        },
                                      ),
                                      InkWell(
                                        onTap: () => _konfirmasiHapus(idPegawai, p['username']),
                                        child: const Padding(
                                          padding: EdgeInsets.only(top: 5, right: 5),
                                          child: Icon(Icons.delete_outline, size: 20, color: AppColors.red),
                                        ),
                                      )
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
