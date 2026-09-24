import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:convert';

import 'tema.dart'; // Import tema eksklusif
import 'halaman_kategori.dart'; // Jika masih digunakan

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

  // Setelan Fitur Admin
  bool _isFiturJasaAktif = true;
  bool _isFiturMejaAktif = false;
  bool _isFiturTakeawayAktif = false;

  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cekRolePengguna();
    ambilDataProduk();
    ambilDaftarKategori();
  }

  // ==========================================
  // PENGAMBILAN DATA (Sama dengan konsep lama)
  // ==========================================
  Future<void> _cekRolePengguna() async {
    final prefs = await SharedPreferences.getInstance();
    int tokoId = prefs.getInt('toko_id') ?? 1;

    setState(() {
      _userRole = prefs.getString('role') ?? 'kasir';
      _isFiturJasaAktif = prefs.getBool('fitur_jasa_aktif') ?? true;
      _isFiturMejaAktif = prefs.getBool('fitur_meja_aktif') ?? false;
      _isFiturTakeawayAktif = prefs.getBool('fitur_takeaway_aktif') ?? false;
    });

    try {
      final response = await http.get(Uri.parse('$domainUrl/api/detailToko/$tokoId'), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final dataToko = json.decode(response.body)['data'];
        bool dbJasa = dataToko['fitur_jasa'].toString() == '1';
        bool dbMeja = dataToko['fitur_meja'].toString() == '1';
        bool dbTakeaway = dataToko['fitur_takeaway'].toString() == '1';

        setState(() {
          _isFiturJasaAktif = dbJasa;
          _isFiturMejaAktif = dbMeja;
          _isFiturTakeawayAktif = dbTakeaway;
        });

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
        setState(() {
          daftarKategori = json.decode(response.body)['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error Kategori: $e");
    }
  }

  Future<void> ambilDataProduk() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      int tokoIdAsli = prefs.getInt('toko_id') ?? 1;

      final response = await http.get(Uri.parse('$baseUrl?toko_id=$tokoIdAsli'), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          List semuaData = responseData['data'] ?? [];
          dataProduk = semuaData.where((item) => item['jenis'] != 'jasa' && item['toko_id'].toString() == tokoIdAsli.toString()).toList();
          filteredProduk = dataProduk;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

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

  // ==========================================
  // FUNGSI CRUD & SCANNER
  // ==========================================
  Future<void> simpanProduk(int? id, String kodeBarang, String nama, int harga, int stok, int? kategoriId, String divisiPrinter) async {
    final prefs = await SharedPreferences.getInstance();
    int tokoIdAsli = prefs.getInt('toko_id') ?? 1;

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
          ? await http.post(url, headers: {'Content-Type': 'application/json'}, body: json.encode(payload))
          : await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode(payload));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await ambilDataProduk();
        if (mounted) _tampilkanNotif('Berhasil!', 'Data barang disimpan.', true);
      } else {
        if (mounted) _tampilkanNotif('Gagal!', 'Server menolak (Error ${response.statusCode}).', false);
      }
    } catch (e) {
      if (mounted) _tampilkanNotif('Error', 'Kesalahan jaringan: $e', false);
    }
  }

  Future<void> hapusProduk(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int tokoIdAsli = prefs.getInt('toko_id') ?? 1;

      final response = await http.delete(Uri.parse('$baseUrl/$id?toko_id=$tokoIdAsli'), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        await ambilDataProduk();
        if (mounted) _tampilkanNotif('Terhapus!', 'Produk berhasil dihapus.', true);
      }
    } catch (e) {
      debugPrint("Error Hapus: $e");
    }
  }

  void _tampilkanNotif(String judul, String pesan, bool sukses) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(sukses ? Icons.check_circle : Icons.error, color: AppColors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(pesan, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: sukses ? AppColors.emerald : AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==========================================
  // BOTTOM SHEET FORM (TAMPILAN PREMIUM)
  // ==========================================
  void tampilkanFormDialog({Map<String, dynamic>? produkInfo}) {
    TextEditingController kodeCtrl = TextEditingController(text: produkInfo?['kode_barang'] ?? '');
    TextEditingController namaCtrl = TextEditingController(text: produkInfo?['nama'] ?? '');
    TextEditingController hargaCtrl = TextEditingController(text: produkInfo?['harga']?.toString() ?? '');
    TextEditingController stokCtrl = TextEditingController(text: produkInfo?['stok']?.toString() ?? '');
    int? selectedKategoriId = produkInfo?['kategori_id'] != null ? int.tryParse(produkInfo!['kategori_id'].toString()) : null;
    String selectedDivisiPrinter = produkInfo?['divisi_printer']?.toString() ?? 'kasir';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 24, right: 24),
              decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 25),
                    Text(produkInfo == null ? 'Tambah Produk Baru' : 'Edit Produk', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    const SizedBox(height: 25),
                    
                    _buildPremiumTextField('Kode Barang / Barcode', Icons.qr_code, kodeCtrl, isScan: true, onScan: () async {
                      var result = await BarcodeScanner.scan();
                      if (result.rawContent.isNotEmpty && result.rawContent != '-1') {
                        setModalState(() => kodeCtrl.text = result.rawContent);
                      }
                    }),
                    _buildPremiumTextField('Nama Barang', Icons.inventory_2, namaCtrl),
                    _buildPremiumTextField('Harga Jual (Rp)', Icons.attach_money, hargaCtrl, isNumber: true),
                    _buildPremiumTextField('Stok Awal', Icons.layers, stokCtrl, isNumber: true),
                    
                    if (daftarKategori.isNotEmpty) ...[
                      const Text('Kategori Produk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selectedKategoriId,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.lightGray,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        items: daftarKategori.map((kat) {
                          return DropdownMenuItem<int>(value: int.parse(kat['id'].toString()), child: Text(kat['nama_kategori']));
                        }).toList(),
                        onChanged: (val) => setModalState(() => selectedKategoriId = val),
                      ),
                      const SizedBox(height: 15),
                    ],

                    const Text('Divisi Printer Dapur/Bar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: ['kasir', 'dapur', 'bar'].contains(selectedDivisiPrinter) ? selectedDivisiPrinter : 'kasir',
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.lightGray,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'kasir', child: Text('Hanya di Kasir')),
                        DropdownMenuItem(value: 'dapur', child: Text('Kirim ke Printer Dapur')),
                        DropdownMenuItem(value: 'bar', child: Text('Kirim ke Printer Bar')),
                      ],
                      onChanged: (val) => setModalState(() => selectedDivisiPrinter = val ?? 'kasir'),
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          Navigator.pop(context);
                          simpanProduk(
                            produkInfo != null ? int.parse(produkInfo['id'].toString()) : null,
                            kodeCtrl.text, namaCtrl.text, int.tryParse(hargaCtrl.text) ?? 0,
                            int.tryParse(stokCtrl.text) ?? 0, selectedKategoriId, selectedDivisiPrinter,
                          );
                        },
                        child: const Text('Simpan Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
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

  Widget _buildPremiumTextField(String label, IconData icon, TextEditingController controller, {bool isNumber = false, bool isScan = false, VoidCallback? onScan}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.slateGray, size: 20),
              suffixIcon: isScan ? IconButton(icon: const Icon(Icons.qr_code_scanner, color: AppColors.smartBlue), onPressed: onScan) : null,
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

  // ==========================================
  // WIDGET UTAMA (BODY)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    bool isAdmin = _userRole == 'admin' || _userRole == 'superadmin';

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      // Tidak menggunakan AppBar karena menempel di KerangkaNavigasi
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
                    Text('Katalog Produk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    SizedBox(height: 4),
                    Text('Riwayat seluruh produk dan stok toko', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                  ],
                ),
                if (isAdmin)
                  ElevatedButton.icon(
                    onPressed: () => tampilkanFormDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Produk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.smartBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),

          // 2. SEARCH & FILTER SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: _filterPencarian,
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.slateGray),
                      prefixIcon: const Icon(Icons.search, color: AppColors.slateGray, size: 20),
                      filled: true,
                      fillColor: AppColors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Kategori', style: TextStyle(fontSize: 13, color: AppColors.slateGray)),
                        items: const [], // Bisa disambungkan ke filter kategori nanti
                        onChanged: (val) {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 3. DAFTAR PRODUK (TABLE-LIKE CARDS)
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                : filteredProduk.isEmpty
                    ? const Center(child: Text("Belum ada produk.", style: TextStyle(color: AppColors.slateGray)))
                    : RefreshIndicator(
                        onRefresh: ambilDataProduk,
                        color: AppColors.teal,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
                          itemCount: filteredProduk.length,
                          itemBuilder: (context, index) {
                            var item = filteredProduk[index];
                            int stok = int.tryParse(item['stok'].toString()) ?? 0;
                            int idItem = int.parse(item['id'].toString());

                            // Logika Status Badge Premium
                            String statusText = 'Aman';
                            Color statusColor = AppColors.emerald;
                            Color statusBg = AppColors.emerald.withOpacity(0.1);

                            if (stok == 0) {
                              statusText = 'Habis';
                              statusColor = AppColors.red;
                              statusBg = AppColors.red.withOpacity(0.1);
                            } else if (stok <= 10) {
                              statusText = 'Menipis';
                              statusColor = AppColors.premiumGold;
                              statusBg = AppColors.premiumGold.withOpacity(0.15);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Row(
                                children: [
                                  // Ikon Placeholder Gambar
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.slateGray),
                                  ),
                                  const SizedBox(width: 15),
                                  
                                  // Info Utama
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkText)),
                                        const SizedBox(height: 4),
                                        Text('Rp ${item['harga']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slateGray)),
                                      ],
                                    ),
                                  ),

                                  // Info Stok & Status
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$stok pcs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkText)),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                                        child: Text(statusText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                                      ),
                                    ],
                                  ),

                                  // Tombol Aksi Admin
                                  if (isAdmin) ...[
                                    const SizedBox(width: 5),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: AppColors.slateGray),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      onSelected: (String result) {
                                        if (result == 'edit') {
                                          tampilkanFormDialog(produkInfo: item);
                                        } else if (result == 'hapus') {
                                          hapusProduk(idItem);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: AppColors.smartBlue), SizedBox(width: 10), Text('Edit')])),
                                        const PopupMenuItem<String>(value: 'hapus', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.red), SizedBox(width: 10), Text('Hapus', style: TextStyle(color: AppColors.red))])),
                                      ],
                                    ),
                                  ]
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
