import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HalamanProduk extends StatefulWidget {
  const HalamanProduk({super.key});

  @override
  State<HalamanProduk> createState() => _HalamanProdukState();
}

class _HalamanProdukState extends State<HalamanProduk> {
  // URL telah disesuaikan ke hosting AnymHost Anda
  final String baseUrl = 'https://smartkasir.shop/api/produk';
  
  List dataProduk = [];
  String _userRole = 'kasir';
  bool isLoading = true;

  // --- STATUS SAKELAR JASA ---
  bool _isFiturJasaAktif = true;

  @override
  void initState() {
    super.initState();
    _cekRolePengguna();
    ambilDataProduk();
  }

  Future<void> _cekRolePengguna() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'kasir';
      // Mengambil status Jasa dari memori HP (Default: true/ON)
      _isFiturJasaAktif = prefs.getBool('fitur_jasa_aktif') ?? true;
    });
  }

  // --- MENGUBAH STATUS JASA (ON/OFF) ---
  Future<void> _toggleFiturJasa(bool nilaiBaru) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fitur_jasa_aktif', nilaiBaru);
    setState(() {
      _isFiturJasaAktif = nilaiBaru;
    });

    tampilkanNotifikasiTengah(
        'Berhasil!',
        'Kolom input Jasa manual di halaman Kasir telah di${nilaiBaru ? "aktifkan" : "nonaktifkan"}.',
        true);
  }

  Future<void> ambilDataProduk() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: {
        'ngrok-skip-browser-warning': 'true',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          // Hanya mengambil data yang berjenis 'barang' agar bersih dari data jasa lama (jika ada)
          List semuaData = responseData['data'] ?? [];
          dataProduk =
              semuaData.where((item) => item['jenis'] != 'jasa').toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  void tampilkanNotifikasiTengah(String judul, String pesan, bool sukses) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: sukses
                        ? Colors.green.withAlpha(50)
                        : Colors.red.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    sukses ? Icons.check_circle : Icons.error_outline,
                    color: sukses ? Colors.green : Colors.red,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                Text(judul,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(pesan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: sukses ? Colors.green : Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> simpanProduk(
      int? id, String kodeBarang, String nama, int harga, int stok) async {
    final url = id == null ? Uri.parse(baseUrl) : Uri.parse('$baseUrl/$id');

    // Paksa jenis = 'barang'
    final Map<String, dynamic> payload = {
      'toko_id': 1,
      'kode_barang': kodeBarang,
      'nama': nama,
      'jenis': 'barang',
      'harga': harga,
      'stok': stok,
    };

    try {
      final response = id == null
          ? await http.post(url,
              headers: {
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true'
              },
              body: json.encode(payload))
          : await http.put(url,
              headers: {
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true'
              },
              body: json.encode(payload));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await ambilDataProduk();
        if (mounted) {
          tampilkanNotifikasiTengah(
              'Berhasil!', 'Data barang berhasil disimpan.', true);
        }
      } else {
        if (mounted) {
          tampilkanNotifikasiTengah('Gagal!',
              'Server menolak (Error ${response.statusCode}).', false);
        }
      }
    } catch (e) {
      if (mounted) {
        tampilkanNotifikasiTengah(
            'Error Jaringan', 'Terjadi kesalahan: $e', false);
      }
    }
  }

  Future<void> hapusProduk(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: {
        'ngrok-skip-browser-warning': 'true',
      });
      if (response.statusCode == 200) {
        await ambilDataProduk();
        if (mounted) {
          tampilkanNotifikasiTengah(
              'Terhapus!', 'Data telah berhasil dihapus.', true);
        }
      }
    } catch (e) {
      debugPrint("Error Hapus: $e");
    }
  }

  void tampilkanFormDialog({Map<String, dynamic>? produkInfo}) {
    TextEditingController kodeCtrl =
        TextEditingController(text: produkInfo?['kode_barang'] ?? '');
    TextEditingController namaCtrl =
        TextEditingController(text: produkInfo?['nama'] ?? '');
    TextEditingController hargaCtrl =
        TextEditingController(text: produkInfo?['harga']?.toString() ?? '');
    TextEditingController stokCtrl =
        TextEditingController(text: produkInfo?['stok']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Text(
                    produkInfo == null
                        ? '✨ Tambah Barang Baru'
                        : '✏️ Edit Barang',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                    controller: kodeCtrl,
                    decoration: InputDecoration(
                        labelText: 'Kode Barang',
                        prefixIcon: const Icon(Icons.qr_code),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)))),
                const SizedBox(height: 15),
                TextField(
                    controller: namaCtrl,
                    decoration: InputDecoration(
                        labelText: 'Nama Barang',
                        prefixIcon: const Icon(Icons.inventory_2),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)))),
                const SizedBox(height: 15),
                TextField(
                    controller: hargaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Harga (Rp)',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)))),
                const SizedBox(height: 15),
                TextField(
                    controller: stokCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Jumlah Stok',
                        prefixIcon: const Icon(Icons.layers),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15)))),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    onPressed: () {
                      int idBarang = produkInfo != null
                          ? int.parse(produkInfo['id'].toString())
                          : 0;
                      Navigator.pop(context);
                      simpanProduk(
                        produkInfo == null ? null : idBarang,
                        kodeCtrl.text,
                        namaCtrl.text,
                        int.tryParse(hargaCtrl.text) ?? 0,
                        int.tryParse(stokCtrl.text) ?? 0,
                      );
                    },
                    child: const Text('Simpan Data Barang',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _userRole == 'admin' || _userRole == 'superadmin';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Katalog Barang',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- PANEL PENGATURAN JASA (HANYA UNTUK ADMIN) ---
          if (isAdmin)
            Card(
              margin: const EdgeInsets.all(15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.shade300)),
              child: SwitchListTile(
                activeColor: Colors.green,
                title: const Text('Fitur Input Jasa Kasir',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isFiturJasaAktif
                    ? 'Aktif (Muncul di layar kasir)'
                    : 'Nonaktif (Disembunyikan)'),
                secondary: const Icon(Icons.handyman, color: Colors.purple),
                value: _isFiturJasaAktif,
                onChanged: _toggleFiturJasa,
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: ambilDataProduk,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                          top: 5, left: 15, right: 15, bottom: 80),
                      itemCount: dataProduk.length,
                      itemBuilder: (context, index) {
                        var item = dataProduk[index];
                        int idItem = int.parse(item['id'].toString());

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.withAlpha(30),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5))
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.blueAccent.withAlpha(25),
                                      borderRadius: BorderRadius.circular(15)),
                                  child: const Icon(Icons.shopping_bag,
                                      color: Colors.blueAccent, size: 30),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['kode_barang'] ?? '-',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 3),
                                      Text(item['nama'],
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      Text('Rp ${item['harga']}',
                                          style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      const SizedBox(height: 5),
                                      Text('Stok: ${item['stok']}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                                isAdmin
                                    ? Column(
                                        children: [
                                          IconButton(
                                              icon: const Icon(Icons.edit_note,
                                                  color: Colors.orange,
                                                  size: 28),
                                              onPressed: () =>
                                                  tampilkanFormDialog(
                                                      produkInfo: item)),
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 28),
                                              onPressed: () =>
                                                  hapusProduk(idItem)),
                                        ],
                                      )
                                    : const SizedBox(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blueAccent,
              onPressed: () => tampilkanFormDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Barang',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
