import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'tema.dart'; // Import tema eksklusif
import 'halaman_struk.dart'; // Import halaman struk

class HalamanKasir extends StatefulWidget {
  const HalamanKasir({super.key});

  @override
  State<HalamanKasir> createState() => _HalamanKasirState();
}

class _HalamanKasirState extends State<HalamanKasir> {
  final String domainUrl = 'https://smartkasir.shop';
  
  bool isLoading = true;
  bool isShiftTerbuka = true; // Set ke true jika shift diabaikan untuk admin
  int _tokoId = 1;
  int _userId = 1;
  int _ppnPersen = 0;

  List dataProduk = [];
  List dataKategori = [];
  List filteredProduk = [];
  List<Map<String, dynamic>> keranjang = [];

  int _kategoriTerpilih = 0; // 0 = Semua
  String kataKunci = "";
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    final prefs = await SharedPreferences.getInstance();
    _tokoId = prefs.getInt('toko_id') ?? 1;
    _userId = prefs.getInt('user_id') ?? 1;

    await _ambilDataToko();
    await _ambilDataKategori();
    await _ambilDataProduk();

    setState(() => isLoading = false);
  }

  Future<void> _ambilDataToko() async {
    try {
      final res = await http.get(Uri.parse('$domainUrl/api/detailToko/$_tokoId'), headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        setState(() {
          _ppnPersen = int.tryParse(data['ppn_persen']?.toString() ?? '0') ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Error load toko: $e");
    }
  }

  Future<void> _ambilDataKategori() async {
    try {
      final res = await http.get(Uri.parse('$domainUrl/api/kategori'), headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        setState(() {
          dataKategori = json.decode(res.body)['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error load kategori: $e");
    }
  }

  Future<void> _ambilDataProduk() async {
    try {
      final res = await http.get(Uri.parse('$domainUrl/api/produk?toko_id=$_tokoId'), headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        setState(() {
          List semua = json.decode(res.body)['data'] ?? [];
          dataProduk = semua.where((item) => item['jenis'] != 'jasa').toList();
          filteredProduk = dataProduk;
        });
      }
    } catch (e) {
      debugPrint("Error load produk: $e");
    }
  }

  void _filterProduk() {
    setState(() {
      filteredProduk = dataProduk.where((item) {
        bool matchKategori = _kategoriTerpilih == 0 || (item['kategori_id'] != null && int.parse(item['kategori_id'].toString()) == _kategoriTerpilih);
        bool matchSearch = kataKunci.isEmpty || item['nama'].toString().toLowerCase().contains(kataKunci.toLowerCase());
        return matchKategori && matchSearch;
      }).toList();
    });
  }

  // ==========================================
  // LOGIKA KERANJANG
  // ==========================================
  void _tambahKeKeranjang(Map<String, dynamic> produk) {
    int stokTersedia = int.tryParse(produk['stok'].toString()) ?? 0;
    int index = keranjang.indexWhere((item) => item['id'] == produk['id']);
    int harga = int.tryParse(produk['harga'].toString()) ?? 0;

    setState(() {
      if (index != -1) {
        if (keranjang[index]['qty'] >= stokTersedia) {
          _tampilkanNotif('Stok ${produk['nama']} tidak mencukupi!', AppColors.red);
          return;
        }
        keranjang[index]['qty'] += 1;
        keranjang[index]['subtotal'] = keranjang[index]['qty'] * harga;
      } else {
        if (stokTersedia < 1) {
          _tampilkanNotif('Stok ${produk['nama']} habis!', AppColors.red);
          return;
        }
        keranjang.add({
          'id': produk['id'],
          'nama': produk['nama'],
          'harga': harga,
          'qty': 1,
          'subtotal': harga,
          'stok_maksimal': stokTersedia,
          'divisi_printer': produk['divisi_printer'] ?? 'kasir',
        });
      }
    });
  }

  void _kurangiDariKeranjang(int index) {
    setState(() {
      if (keranjang[index]['qty'] > 1) {
        keranjang[index]['qty'] -= 1;
        int harga = keranjang[index]['harga'];
        keranjang[index]['subtotal'] = keranjang[index]['qty'] * harga;
      } else {
        keranjang.removeAt(index);
      }
    });
  }

  int _getSubtotal() {
    return keranjang.fold(0, (sum, item) => sum + (item['subtotal'] as int));
  }

  int _getPpnNominal() {
    return (_getSubtotal() * _ppnPersen) ~/ 100;
  }

  int _getGrandTotal() {
    return _getSubtotal() + _getPpnNominal();
  }

  void _kosongkanKeranjang() {
    setState(() => keranjang.clear());
  }

  void _tampilkanNotif(String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ==========================================
  // WIDGET UTAMA (RESPONSIVE)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(backgroundColor: AppColors.lightGray, body: Center(child: CircularProgressIndicator(color: AppColors.teal)));

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth >= 800; // Threshold untuk Tablet/Desktop

          if (isDesktop) {
            // MODE HORIZONTAL (Tablet/Web)
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PANEL KIRI: KATEGORI
                Container(
                  width: 250,
                  color: AppColors.white,
                  child: _buildPanelKategori(),
                ),
                // PANEL TENGAH: PRODUK
                Expanded(
                  child: Column(
                    children: [
                      _buildHeaderPencarian(),
                      Expanded(child: _buildGridProduk(isDesktop: true)),
                    ],
                  ),
                ),
                // PANEL KANAN: KERANJANG
                Container(
                  width: 350,
                  color: AppColors.white,
                  child: _buildPanelKeranjang(isDesktop: true),
                ),
              ],
            );
          } else {
            // MODE VERTIKAL (HP)
            return Column(
              children: [
                _buildHeaderPencarian(),
                _buildSliderKategoriHorizontal(),
                Expanded(child: _buildGridProduk(isDesktop: false)),
                _buildBottomBarKeranjangHP(),
              ],
            );
          }
        },
      ),
    );
  }

  // ==========================================
  // KOMPONEN UI
  // ==========================================
  Widget _buildHeaderPencarian() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: AppColors.lightGray,
      child: TextField(
        controller: searchCtrl,
        onChanged: (val) {
          kataKunci = val;
          _filterProduk();
        },
        decoration: InputDecoration(
          hintText: 'Cari produk, kategori...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.slateGray),
          prefixIcon: const Icon(Icons.search, color: AppColors.slateGray, size: 20),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // Panel Kategori (Kiri - Tablet)
  Widget _buildPanelKategori() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            children: [
              _itemKategori(0, 'Semua', Icons.grid_view),
              ...dataKategori.map((k) => _itemKategori(int.parse(k['id'].toString()), k['nama_kategori'], Icons.fastfood_outlined)),
            ],
          ),
        )
      ],
    );
  }

  // Slider Kategori (Atas - HP)
  Widget _buildSliderKategoriHorizontal() {
    return Container(
      height: 50,
      color: AppColors.lightGray,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          _itemKategoriBip(0, 'Semua'),
          ...dataKategori.map((k) => _itemKategoriBip(int.parse(k['id'].toString()), k['nama_kategori'])),
        ],
      ),
    );
  }

  Widget _itemKategori(int id, String nama, IconData icon) {
    bool isSelected = _kategoriTerpilih == id;
    return InkWell(
      onTap: () {
        setState(() => _kategoriTerpilih = id);
        _filterProduk();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.white : AppColors.slateGray, size: 20),
            const SizedBox(width: 15),
            Text(nama, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.white : AppColors.darkText, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _itemKategoriBip(int id, String nama) {
    bool isSelected = _kategoriTerpilih == id;
    return InkWell(
      onTap: () {
        setState(() => _kategoriTerpilih = id);
        _filterProduk();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(nama, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.white : AppColors.slateGray, fontSize: 13)),
      ),
    );
  }

  // Grid Produk (Tengah Tablet / Bawah HP)
  Widget _buildGridProduk({required bool isDesktop}) {
    if (filteredProduk.isEmpty) {
      return const Center(child: Text('Produk tidak ditemukan.', style: TextStyle(color: AppColors.slateGray)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180, // Ukuran kartu produk
        childAspectRatio: 0.8, // Rasio Tinggi vs Lebar
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: filteredProduk.length,
      itemBuilder: (context, index) {
        var p = filteredProduk[index];
        return InkWell(
          onTap: () => _tambahKeKeranjang(p),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Placeholder
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Icon(Icons.fastfood, size: 40, color: AppColors.slateGray),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['nama'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkText)),
                      const SizedBox(height: 6),
                      Text(_formatRupiah(int.parse(p['harga'].toString())), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.smartBlue)),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // Panel Keranjang (Kanan - Tablet)
  Widget _buildPanelKeranjang({bool isDesktop = false}) {
    return Column(
      children: [
        // Header Keranjang
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keranjang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                  Text('${keranjang.length} item', style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                ],
              ),
              if (keranjang.isNotEmpty)
                TextButton(
                  onPressed: _kosongkanKeranjang,
                  child: const Text('Hapus Semua', style: TextStyle(color: AppColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),

        // List Item di Keranjang
        Expanded(
          child: keranjang.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 50, color: AppColors.slateGray),
                      SizedBox(height: 10),
                      Text('Keranjang masih kosong', style: TextStyle(color: AppColors.slateGray)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: keranjang.length,
                  itemBuilder: (context, i) {
                    var item = keranjang[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          Container(
                            width: 45, height: 45,
                            decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.fastfood, size: 20, color: AppColors.slateGray),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['nama'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkText)),
                                const SizedBox(height: 5),
                                Text(_formatRupiah(item['harga']), style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                              ],
                            ),
                          ),
                          // Control Qty
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _kurangiDariKeranjang(i),
                                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.remove, size: 16, color: AppColors.red)),
                              ),
                              Container(
                                width: 25, alignment: Alignment.center,
                                child: Text('${item['qty']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                              InkWell(
                                onTap: () => _tambahKeKeranjang({'id': item['id'], 'nama': item['nama'], 'harga': item['harga'], 'stok': item['stok_maksimal']}),
                                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.add, size: 16, color: AppColors.teal)),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Summary & Tombol Bayar
        if (keranjang.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                _buildRowSummary('Subtotal', _formatRupiah(_getSubtotal())),
                if (_ppnPersen > 0) ...[
                  const SizedBox(height: 8),
                  _buildRowSummary('Pajak ($_ppnPersen%)', _formatRupiah(_getPpnNominal())),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(),
                ),
                _buildRowSummary('Total', _formatRupiah(_getGrandTotal()), isBold: true, size: 18),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _tampilkanDialogPembayaran,
                    child: const Text('Bayar Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
                  ),
                )
              ],
            ),
          )
      ],
    );
  }

  // Floating Bottom Bar untuk HP
  Widget _buildBottomBarKeranjangHP() {
    if (keranjang.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${keranjang.length} item', style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
              Text(_formatRupiah(_getGrandTotal()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.teal)),
            ],
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              // Buka BottomSheet untuk detail keranjang HP
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  child: _buildPanelKeranjang(isDesktop: false),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart, size: 18, color: AppColors.white),
            label: const Text('Lihat Keranjang', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildRowSummary(String label, String value, {bool isBold = false, double size = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? AppColors.darkText : AppColors.slateGray, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: size - 2)),
        Text(value, style: TextStyle(color: AppColors.darkText, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: size)),
      ],
    );
  }

  String _formatRupiah(int angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  // ==========================================
  // LOGIKA PEMBAYARAN & API
  // ==========================================
  void _tampilkanDialogPembayaran() {
    int total = _getGrandTotal();
    TextEditingController bayarCtrl = TextEditingController(text: total.toString());
    String metode = 'tunai';
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int kembalian = (int.tryParse(bayarCtrl.text) ?? 0) - total;
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Proses Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkText)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: metode,
                    decoration: InputDecoration(
                      filled: true, fillColor: AppColors.lightGray,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'tunai', child: Text('Tunai')),
                      DropdownMenuItem(value: 'non_tunai', child: Text('Non-Tunai (QRIS/Transfer)')),
                    ],
                    onChanged: (val) {
                      setDialogState(() {
                        metode = val!;
                        if (metode == 'non_tunai') bayarCtrl.text = total.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  if (metode == 'tunai')
                    TextField(
                      controller: bayarCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Uang Diterima (Rp)',
                        filled: true, fillColor: AppColors.lightGray,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setDialogState(() {}),
                    ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan', style: TextStyle(color: AppColors.slateGray, fontWeight: FontWeight.bold)),
                      Text(_formatRupiah(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.smartBlue)),
                    ],
                  ),
                  if (metode == 'tunai') ...[
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian', style: TextStyle(color: AppColors.slateGray, fontWeight: FontWeight.bold)),
                        Text(_formatRupiah(kembalian > 0 ? kembalian : 0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kembalian < 0 ? AppColors.red : AppColors.emerald)),
                      ],
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: isProcessing ? null : () => Navigator.pop(dialogCtx), child: const Text('Batal', style: TextStyle(color: AppColors.slateGray))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: isProcessing ? null : () async {
                    int bayar = int.tryParse(bayarCtrl.text) ?? 0;
                    if (metode == 'tunai' && bayar < total) {
                      _tampilkanNotif('Uang bayar kurang!', AppColors.red);
                      return;
                    }

                    setDialogState(() => isProcessing = true);
                    
                    // Siapkan Data JSON
                    Map<String, dynamic> payload = {
                      "toko_id": _tokoId,
                      "user_id": _userId,
                      "total_harga": total,
                      "ppn_persen": _ppnPersen,
                      "ppn_nominal": _getPpnNominal(),
                      "uang_bayar": bayar,
                      "kembalian": kembalian > 0 ? kembalian : 0,
                      "metode_pembayaran": metode,
                      "tipe_pesanan": "dine_in",
                      "items": keranjang.map((item) => {
                        "product_id": item['id'],
                        "qty": item['qty'],
                        "harga_satuan": item['harga'],
                        "subtotal": item['subtotal']
                      }).toList()
                    };

                    try {
                      final response = await http.post(
                        Uri.parse('$domainUrl/api/simpanTransaksi'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode(payload),
                      );

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        
                        List<Map<String, dynamic>> keranjangSnapshot = List.from(keranjang);
                        _kosongkanKeranjang();
                        await _ambilDataProduk(); // Update Stok

                        if (context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HalamanStruk(
                            keranjang: keranjangSnapshot,
                            totalBelanja: total,
                            subtotal: _getSubtotal(),
                            ppnNominal: _getPpnNominal(),
                            biayaJasa: 0,
                            uangDiterima: bayar,
                            uangKembalian: kembalian > 0 ? kembalian : 0,
                            noStruk: 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                            tanggal: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
                            metodePembayaran: metode == 'tunai' ? 'Tunai' : 'Non-Tunai',
                          )));
                        }
                      } else {
                        _tampilkanNotif('Gagal menyimpan transaksi', AppColors.red);
                      }
                    } catch (e) {
                      _tampilkanNotif('Kesalahan jaringan: $e', AppColors.red);
                    }
                    if (dialogCtx.mounted) setDialogState(() => isProcessing = false);
                  },
                  child: isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)) : const Text('Simpan & Cetak', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      }
    );
  }
}
