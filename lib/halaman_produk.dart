import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'halaman_kategori.dart'; // Navigasi ke manajemen kategori

class HalamanProduk extends StatefulWidget {
  const HalamanProduk({super.key});

  @override
  State<HalamanProduk> createState() => _HalamanProdukState();
}

class _HalamanProdukState extends State<HalamanProduk> {
  final String baseUrl = 'https://smartkasir.shop/api/produk';
  final String kategoriUrl = 'https://smartkasir.shop/api/kategori';
  
  List dataProduk = [];
  List filteredProduk = []; // Variabel baru untuk menampung hasil pencarian
  List daftarKategori = []; 
  
  String _userRole = 'kasir';
  bool isLoading = true;

  bool _isFiturJasaAktif = true;
  bool _isFiturMejaAktif = false;

  // Controller untuk fitur pencarian
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cekRolePengguna();
    ambilDataProduk();
    ambilDaftarKategori();
  }

  Future<void> _cekRolePengguna() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'kasir';
      _isFiturJasaAktif = prefs.getBool('fitur_jasa_aktif') ?? true;
      _isFiturMejaAktif = prefs.getBool('fitur_meja_aktif') ?? false;
    });
  }

  Future<void> ambilDaftarKategori() async {
    try {
      final response = await http.get(Uri.parse(kategoriUrl), headers: {'ngrok-skip-browser-warning': 'true'});
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() {
          daftarKategori = res['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error Kategori: $e");
    }
  }

  Future<void> _toggleFiturJasa(bool nilaiBaru) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fitur_jasa_aktif', nilaiBaru);
    setState(() {
      _isFiturJasaAktif = nilaiBaru;
    });
    tampilkanNotifikasiTengah('Berhasil!', 'Kolom input Jasa manual di halaman Kasir telah di${nilaiBaru ? "aktifkan" : "nonaktifkan"}.', true);
  }

  Future<void> _toggleFiturMeja(bool nilaiBaru) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fitur_meja_aktif', nilaiBaru);
    setState(() {
      _isFiturMejaAktif = nilaiBaru;
    });
    tampilkanNotifikasiTengah('Berhasil!', 'Fitur input No Meja di halaman Kasir telah di${nilaiBaru ? "aktifkan" : "nonaktifkan"}.', true);
  }

  // --- FUNGSI SCAN BARCODE UMUM (Untuk Input / Tambah Barang) ---
  Future<void> mulaiScanBarcode(TextEditingController targetController) async {
    try {
      String hasilScan = await FlutterBarcodeScanner.scanBarcode('#ff6600', 'Batal', true, ScanMode.BARCODE);
      if (hasilScan != '-1') {
        setState(() {
          targetController.text = hasilScan;
        });
      }
    } catch (e) {
      debugPrint('Error saat scanning barcode: $e');
    }
  }

  // --- FUNGSI SCAN BARCODE KHUSUS UNTUK PENCARIAN ---
  Future<void> _scanBarcodeUntukPencarian() async {
    try {
      String hasilScan = await FlutterBarcodeScanner.scanBarcode('#ff6600', 'Batal', true, ScanMode.BARCODE);
      if (hasilScan != '-1') {
        searchCtrl.text = hasilScan;
        _filterPencarian(hasilScan); // Langsung jalankan fungsi filter
      }
    } catch (e) {
      debugPrint('Error saat scanning barcode pencarian: $e');
    }
  }

  // --- FUNGSI FILTER PENCARIAN BARANG ---
  void _filterPencarian(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredProduk = dataProduk; // Kembalikan ke seluruh data jika kosong
      } else {
        filteredProduk = dataProduk.where((item) {
          final nama = item['nama']?.toString().toLowerCase() ?? '';
          final kode = item['kode_barang']?.toString().toLowerCase() ?? '';
          final searchLower = keyword.toLowerCase();
          
          return nama.contains(searchLower) || kode.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> ambilDataProduk() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: {'ngrok-skip-browser-warning': 'true'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          List semuaData = responseData['data'] ?? [];
          dataProduk = semuaData.where((item) => item['jenis'] != 'jasa').toList();
          filteredProduk = dataProduk; // Samakan data filter dengan data asli di awal
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error Ambil Data: $e");
      setState(() => isLoading = false);
    }
  }

  void tampilkanNotifikasiTengah(String judul, String pesan, bool sukses) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: sukses ? Colors.green.withAlpha(50) : Colors.red.withAlpha(50), shape: BoxShape.circle),
                  child: Icon(sukses ? Icons.check_circle : Icons.error_outline, color: sukses ? Colors.green : Colors.red, size: 60),
                ),
                const SizedBox(height: 20),
                Text(judul, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(pesan, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: sukses ? Colors.green : Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> simpanProduk(int? id, String kodeBarang, String nama, int harga, int stok, int? kategoriId) async {
    final url = id == null ? Uri.parse(baseUrl) : Uri.parse('$baseUrl/$id');
    final Map<String, dynamic> payload = {
      'toko_id': 1,
      'kode_barang': kodeBarang,
      'nama': nama,
      'jenis': 'barang',
      'harga': harga,
      'stok': stok,
      'kategori_id': kategoriId,
    };

    try {
      final response = id == null
          ? await http.post(url, headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'}, body: json.encode(payload))
          : await http.put(url, headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'}, body: json.encode(payload));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await ambilDataProduk();
        if (mounted) tampilkanNotifikasiTengah('Berhasil!', 'Data barang berhasil disimpan.', true);
      } else {
        if (mounted) tampilkanNotifikasiTengah('Gagal!', 'Server menolak (Error ${response.statusCode}).', false);
      }
    } catch (e) {
      if (mounted) tampilkanNotifikasiTengah('Error Jaringan', 'Terjadi kesalahan: $e', false);
    }
  }

  Future<void> hapusProduk(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: {'ngrok-skip-browser-warning': 'true'});
      if (response.statusCode == 200) {
        await ambilDataProduk();
        if (mounted) tampilkanNotifikasiTengah('Terhapus!', 'Data telah berhasil dihapus.', true);
      }
    } catch (e) {
      debugPrint("Error Hapus: $e");
    }
  }

  void tampilkanFormDialog({Map<String, dynamic>? produkInfo}) {
    TextEditingController kodeCtrl = TextEditingController(text: produkInfo?['kode_barang'] ?? '');
    TextEditingController namaCtrl = TextEditingController(text: produkInfo?['nama'] ?? '');
    TextEditingController hargaCtrl = TextEditingController(text: produkInfo?['harga']?.toString() ?? '');
    TextEditingController stokCtrl = TextEditingController(text: produkInfo?['stok']?.toString() ?? '');
    int? selectedKategoriId = produkInfo?['kategori_id'] != null ? int.tryParse(produkInfo!['kategori_id'].toString()) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
              decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    Text(produkInfo == null ? '✨ Tambah Barang Baru' : '✏️ Edit Barang', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: kodeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Kode Barang / Barcode',
                        prefixIcon: const Icon(Icons.qr_code),
                        suffixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.blueAccent), 
                            onPressed: () {
                              mulaiScanBarcode(kodeCtrl).then((_) {
                                setModalState(() {}); 
                              });
                            }
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(controller: namaCtrl, decoration: InputDecoration(labelText: 'Nama Barang', prefixIcon: const Icon(Icons.inventory_2), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                    const SizedBox(height: 15),
                    TextField(controller: hargaCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Harga (Rp)', prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                    const SizedBox(height: 15),
                    TextField(controller: stokCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Jumlah Stok', prefixIcon: const Icon(Icons.layers), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                    if (daftarKategori.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      DropdownButtonFormField<int>(
                        value: selectedKategoriId,
                        decoration: InputDecoration(
                          labelText: 'Divisi / Kategori Cetak Printer',
                          prefixIcon: const Icon(Icons.print, color: Colors.blueAccent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        items: daftarKategori.map((kat) {
                          return DropdownMenuItem<int>(
                            value: int.parse(kat['id'].toString()),
                            child: Text(kat['nama_kategori']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedKategoriId = val;
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: () {
                          int idBarang = produkInfo != null ? int.parse(produkInfo['id'].toString()) : 0;
                          Navigator.pop(context);
                          simpanProduk(
                            produkInfo == null ? null : idBarang,
                            kodeCtrl.text,
                            namaCtrl.text,
                            int.tryParse(hargaCtrl.text) ?? 0,
                            int.tryParse(stokCtrl.text) ?? 0,
                            selectedKategoriId,
                          );
                        },
                        child: const Text('Simpan Data Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
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
        title: const Text('Katalog Barang', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.category),
              tooltip: 'Kelola Kategori / Divisi',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HalamanKategori()),
                ).then((_) => ambilDaftarKategori()); 
              },
            ),
        ],
      ),
      body: Column(
        children: [
          
          // ========================================================
          // KOLOM PENCARIAN & SCAN BARCODE (Dapat diakses Kasir & Admin)
          // ========================================================
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: searchCtrl,
              onChanged: _filterPencarian, // Panggil filter tiap mengetik
              decoration: InputDecoration(
                hintText: 'Cari nama atau scan kode...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (searchCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchCtrl.clear();
                          _filterPencarian(''); // Hapus filter
                        },
                      ),
                    // Tombol kamera untuk scan langsung dari bar pencarian
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                      onPressed: _scanBarcodeUntukPencarian,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // ========================================================

          if (isAdmin) ...[
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade300)),
              child: SwitchListTile(
                activeColor: Colors.green,
                title: const Text('Fitur Input Jasa Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isFiturJasaAktif ? 'Aktif (Muncul di layar kasir)' : 'Nonaktif (Disembunyikan)'),
                secondary: const Icon(Icons.handyman, color: Colors.purple),
                value: _isFiturJasaAktif,
                onChanged: _toggleFiturJasa,
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 5),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade300)),
              child: SwitchListTile(
                activeColor: Colors.blue,
                title: const Text('Fitur No Meja', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isFiturMejaAktif ? 'Aktif (Muncul di layar kasir)' : 'Nonaktif (Disembunyikan)'),
                secondary: const Icon(Icons.table_restaurant, color: Colors.orange),
                value: _isFiturMejaAktif,
                onChanged: _toggleFiturMeja,
              ),
            ),
          ],

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProduk.isEmpty // Gunakan filteredProduk
                    ? const Center(child: Text("Barang tidak ditemukan."))
                    : RefreshIndicator(
                        onRefresh: ambilDataProduk,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 5, left: 15, right: 15, bottom: 80),
                          itemCount: filteredProduk.length, // Gunakan filteredProduk
                          itemBuilder: (context, index) {
                            var item = filteredProduk[index]; // Gunakan filteredProduk
                            int idItem = int.parse(item['id'].toString());

                            return Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withAlpha(30), blurRadius: 10, offset: const Offset(0, 5))]),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.blueAccent.withAlpha(25), borderRadius: BorderRadius.circular(15)),
                                      child: const Icon(Icons.shopping_bag, color: Colors.blueAccent, size: 30),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['kode_barang'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 3),
                                          Text(item['nama'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 5),
                                          Text('Rp ${item['harga']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                                          const SizedBox(height: 5),
                                          Text('Stok: ${item['stok']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    isAdmin
                                        ? Column(
                                            children: [
                                              IconButton(icon: const Icon(Icons.edit_note, color: Colors.orange, size: 28), onPressed: () => tampilkanFormDialog(produkInfo: item)),
                                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28), onPressed: () => hapusProduk(idItem)),
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
              label: const Text('Tambah Barang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
