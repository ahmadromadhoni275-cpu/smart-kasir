import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'halaman_kategori.dart'; // Navigasi ke manajemen kategori

class HalamanProduk extends StatefulWidget {
  const HalamanProduk({super.key});

  @override
  State<HalamanProduk> createState() => _HalamanProdukState();
}

class _HalamanProdukState extends State<HalamanProduk> {
  final String domainUrl = 'https://smartkasir.shop';
  final String baseUrl = 'https://smartkasir.shop/api/produk';
  final String kategoriUrl = 'https://smartkasir.shop/api/kategori';

  List dataProduk = [];
  List filteredProduk = []; 
  List daftarKategori = []; 
  String _userRole = 'kasir';
  bool isLoading = true;

  bool _isFiturJasaAktif = true;
  bool _isFiturMejaAktif = false;
  bool _isFiturTakeawayAktif = false; 

  // Controller untuk fitur pencarian
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cekRolePengguna();
    ambilDataProduk();
    ambilDaftarKategori();
  }

  // ========================================================
  // PERBAIKAN: Penarikan setelan fitur toko dengan key "_aktif"
  // ========================================================
  Future<void> _cekRolePengguna() async {
    final prefs = await SharedPreferences.getInstance();
    int tokoId = prefs.getInt('toko_id') ?? 1;

    setState(() {
      _userRole = prefs.getString('role') ?? 'kasir';
      // Load sementara dari lokal (sudah pakai "_aktif")
      _isFiturJasaAktif = prefs.getBool('fitur_jasa_aktif') ?? true;
      _isFiturMejaAktif = prefs.getBool('fitur_meja_aktif') ?? false;
      _isFiturTakeawayAktif = prefs.getBool('fitur_takeaway_aktif') ?? false; 
    });

    // TARIK DATA ASLI DARI SERVER AGAR SINKRON DENGAN WEB
    try {
      final response = await http.get(Uri.parse('$domainUrl/api/detailToko/$tokoId'), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final dataToko = json.decode(response.body)['data'];
        
        // PERBAIKAN: Parsing aman kebal error String vs Integer
        bool dbJasa = dataToko['fitur_jasa'].toString() == '1';
        bool dbMeja = dataToko['fitur_meja'].toString() == '1';
        bool dbTakeaway = dataToko['fitur_takeaway'].toString() == '1';

        setState(() {
          _isFiturJasaAktif = dbJasa;
          _isFiturMejaAktif = dbMeja;
          _isFiturTakeawayAktif = dbTakeaway;
        });

        // Simpan ke lokal menggunakan "_aktif" agar dikenali kasir
        await prefs.setBool('fitur_jasa_aktif', dbJasa);
        await prefs.setBool('fitur_meja_aktif', dbMeja);
        await prefs.setBool('fitur_takeaway_aktif', dbTakeaway);
      }
    } catch (e) {
      debugPrint("Gagal sinkron setelan toko: $e");
    }
  }

  Future<void> ambilDaftarKategori() async {
    try {
      final response = await http.get(Uri.parse(kategoriUrl), headers: {'Accept': 'application/json'});
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

  // ========================================================
  // FUNGSI PINTAR SINKRONISASI FITUR (LOKAL + DATABASE SERVER)
  // ========================================================
  Future<void> _ubahFiturGlobal(String jenisFitur, bool nilaiBaru, String namaFiturTampil) async {
    final prefs = await SharedPreferences.getInstance();
    int tokoId = prefs.getInt('toko_id') ?? 1;

    setState(() {
      if (jenisFitur == 'fitur_jasa') _isFiturJasaAktif = nilaiBaru;
      if (jenisFitur == 'fitur_meja') _isFiturMejaAktif = nilaiBaru;
      if (jenisFitur == 'fitur_takeaway') _isFiturTakeawayAktif = nilaiBaru;
    });

    // Simpan ke lokal dengan tambahan "_aktif"
    await prefs.setBool('${jenisFitur}_aktif', nilaiBaru);

    // Kirim sinyal ke Server agar Website ikut berubah
    try {
      final url = Uri.parse('$domainUrl/api/updateFiturToko');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'toko_id': tokoId,
          'jenis_fitur': jenisFitur,
          'status': nilaiBaru ? 1 : 0
        }),
      );
    } catch (e) {
      debugPrint("Gagal kirim status $jenisFitur ke server: $e");
    }

    tampilkanNotifikasiTengah('Berhasil!', '$namaFiturTampil telah di${nilaiBaru ? "aktifkan" : "nonaktifkan"}.', true);
  }

  // --- FUNGSI SCAN BARCODE UMUM (Untuk Input / Tambah Barang) ---
  Future<void> mulaiScanBarcode(TextEditingController targetController) async {
    try {
      var result = await BarcodeScanner.scan();
      String hasilScan = result.rawContent;

      if (hasilScan.isNotEmpty && hasilScan != '-1') {
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
      var result = await BarcodeScanner.scan();
      String hasilScan = result.rawContent;

      if (hasilScan.isNotEmpty && hasilScan != '-1') {
        searchCtrl.text = hasilScan;
        _filterPencarian(hasilScan); 
      }
    } catch (e) {
      debugPrint('Error saat scanning barcode pencarian: $e');
    }
  }

  // --- FUNGSI FILTER PENCARIAN BARANG ---
  void _filterPencarian(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        filteredProduk = dataProduk; 
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
    // HANYA AMBIL PRODUK MILIK TOKO YANG SEDANG LOGIN SAJA (Filter via params jika memungkinkan, tapi backend sudah set via middleware/session jika diakses via route API yang tepat, pastikan sesuai. Jika API get all, backend memfilternya via token/session, jika tidak filter manual atau sesuaikan API)
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        final prefs = await SharedPreferences.getInstance();
        int tokoIdAsli = prefs.getInt('toko_id') ?? 1;

        setState(() {
          List semuaData = responseData['data'] ?? [];
          // Filter produk berdasarkan toko_id yang sedang login dan yang bukan jasa
          dataProduk = semuaData.where((item) => item['jenis'] != 'jasa' && item['toko_id'].toString() == tokoIdAsli.toString()).toList();
          filteredProduk = dataProduk; 
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

  // =========================================================================
  // PERBAIKAN: Menambahkan `toko_id` dinamis & `divisiPrinter`
  // =========================================================================
  Future<void> simpanProduk(int? id, String kodeBarang, String nama, int harga, int stok, int? kategoriId, String divisiPrinter) async {
    final prefs = await SharedPreferences.getInstance();
    int tokoIdAsli = prefs.getInt('toko_id') ?? 1; // DINAMIS MULTI-TOKO

    final url = id == null ? Uri.parse(baseUrl) : Uri.parse('$baseUrl/$id');
    final Map<String, dynamic> payload = {
      'toko_id': tokoIdAsli,
      'kode_barang': kodeBarang,
      'nama': nama,
      'jenis': 'barang',
      'harga': harga,
      'stok': stok,
      'kategori_id': kategoriId,
      'divisi_printer': divisiPrinter, 
    };

    try {
      final response = id == null
          ? await http.post(url, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}, body: json.encode(payload))
          : await http.put(url, headers: {'Content-Type': 'application/json', 'Accept': 'application/json'}, body: json.encode(payload));

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
      final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: {'Accept': 'application/json'});
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
    
    // Default divisi adalah 'kasir' jika tidak ada
    String selectedDivisiPrinter = produkInfo?['divisi_printer']?.toString() ?? 'kasir';

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
                          labelText: 'Kategori Produk',
                          prefixIcon: const Icon(Icons.category, color: Colors.orange),
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

                    // =========================================================================
                    // DROPDOWN DIVISI PRINTER (Tujuan Struk Dapur / Bar)
                    // =========================================================================
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: ['kasir', 'dapur', 'bar'].contains(selectedDivisiPrinter) ? selectedDivisiPrinter : 'kasir',
                      decoration: InputDecoration(
                        labelText: 'Tujuan Cetak Printer (Divisi)',
                        prefixIcon: const Icon(Icons.print, color: Colors.blueAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'kasir', child: Text('Hanya di Kasir')),
                        DropdownMenuItem(value: 'dapur', child: Text('Kirim ke Printer Dapur')),
                        DropdownMenuItem(value: 'bar', child: Text('Kirim ke Printer Bar')),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          selectedDivisiPrinter = val ?? 'kasir';
                        });
                      },
                    ),

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
                            selectedDivisiPrinter, 
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
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: searchCtrl,
              onChanged: _filterPencarian, 
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
                          _filterPencarian(''); 
                        },
                      ),
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
                onChanged: (val) => _ubahFiturGlobal('fitur_jasa', val, 'Fitur Input Jasa Kasir'),
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
                onChanged: (val) => _ubahFiturGlobal('fitur_meja', val, 'Fitur No Meja'),
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade300)),
              child: SwitchListTile(
                activeColor: Colors.orange,
                title: const Text('Fitur Dine In & Takeaway', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isFiturTakeawayAktif ? 'Aktif (Pilihan muncul di tiap item kasir)' : 'Nonaktif (Disembunyikan)'),
                secondary: const Icon(Icons.takeout_dining, color: Colors.deepOrange),
                value: _isFiturTakeawayAktif,
                onChanged: (val) => _ubahFiturGlobal('fitur_takeaway', val, 'Fitur Dine In & Takeaway'),
              ),
            ),
          ],

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProduk.isEmpty 
                    ? const Center(child: Text("Barang tidak ditemukan."))
                    : RefreshIndicator(
                        onRefresh: ambilDataProduk,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 5, left: 15, right: 15, bottom: 80),
                          itemCount: filteredProduk.length, 
                          itemBuilder: (context, index) {
                            var item = filteredProduk[index]; 
                            int idItem = int.parse(item['id'].toString());
                            String divisiItem = item['divisi_printer']?.toString().toUpperCase() ?? 'KASIR';

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
                                          // Tampilan Stok & Label Divisi
                                          Row(
                                            children: [
                                              Text('Stok: ${item['stok']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                              const SizedBox(width: 10),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: divisiItem == 'DAPUR' ? Colors.deepOrange.withOpacity(0.1) : (divisiItem == 'BAR' ? Colors.brown.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
                                                  border: Border.all(color: divisiItem == 'DAPUR' ? Colors.deepOrange : (divisiItem == 'BAR' ? Colors.brown : Colors.blueAccent)),
                                                  borderRadius: BorderRadius.circular(5)
                                                ),
                                                child: Text(
                                                  'Printer: $divisiItem',
                                                  style: TextStyle(
                                                    fontSize: 10, 
                                                    fontWeight: FontWeight.bold,
                                                    color: divisiItem == 'DAPUR' ? Colors.deepOrange : (divisiItem == 'BAR' ? Colors.brown : Colors.blueAccent)
                                                  )
                                                ),
                                              )
                                            ],
                                          ),
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
