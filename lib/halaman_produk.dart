import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart';
import 'services/api_service.dart';
import 'dart:convert';

class HalamanProduk extends StatefulWidget {
  const HalamanProduk({super.key});

  @override
  State<HalamanProduk> createState() => _HalamanProdukState();
}

class _HalamanProdukState extends State<HalamanProduk> {
  bool _isLoading = true;
  List<dynamic> _products = [];
  String _searchQuery = '';
  String _filterType = 'ALL'; // ALL, PRODUCT, SERVICE, LOW_STOCK

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muatProduk();
  }

  Future<void> _muatProduk() async {
    setState(() => _isLoading = true);
    try {
      String url = 'products?search=$_searchQuery';
      if (_filterType == 'PRODUCT' || _filterType == 'SERVICE') {
        url += '&type=$_filterType';
      }
      
      final response = await ApiService.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _products = json.decode(response.body)['data'];
          // Filter lokal untuk LOW_STOCK (bisa juga via API)
          if (_filterType == 'LOW_STOCK') {
            _products = _products.where((p) => p['product_type'] == 'PRODUCT' && p['stock'] <= p['min_stock']).toList();
          }
        });
      }
    } catch (e) {
      debugPrint("Gagal muat produk: $e");
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(dynamic angka) {
    num val = (angka is String) ? double.tryParse(angka) ?? 0 : angka;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(val);
  }

  // =================================================================
  // MODAL FORM TAMBAH PRODUK / JASA
  // =================================================================
  void _tampilkanFormTambah() {
    String jenisProduk = 'PRODUCT';
    TextEditingController namaCtrl = TextEditingController();
    TextEditingController barcodeCtrl = TextEditingController();
    TextEditingController hppCtrl = TextEditingController();
    TextEditingController hargaCtrl = TextEditingController();
    TextEditingController stokCtrl = TextEditingController(text: '0');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setFormState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tambah Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 20),
                
                // PILIHAN JENIS (BARANG / JASA)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setFormState(() => jenisProduk = 'PRODUCT'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: jenisProduk == 'PRODUCT' ? AppColors.primaryEmerald : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text('📦 BARANG', style: TextStyle(color: jenisProduk == 'PRODUCT' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setFormState(() => jenisProduk = 'SERVICE'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: jenisProduk == 'SERVICE' ? AppColors.goldPremium : AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text('✂️ JASA', style: TextStyle(color: jenisProduk == 'SERVICE' ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Expanded(
                  child: ListView(
                    children: [
                      _buildInput('Nama Produk / Jasa *', namaCtrl),
                      
                      // Barcode dengan tombol Scanner Kamera
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _buildInput('Barcode (Scan USB otomatis masuk sini)', barcodeCtrl)),
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                            child: IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryEmerald),
                              onPressed: () {
                                // TODO: Buka Halaman Scanner Kamera & Set State barcodeCtrl.text
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buka Kamera HP')));
                              },
                            ),
                          )
                        ],
                      ),
                      
                      _buildInput('Harga Jual *', hargaCtrl, type: TextInputType.number),
                      
                      // JIKA BARANG, TAMPILKAN HPP DAN STOK
                      if (jenisProduk == 'PRODUCT') ...[
                        _buildInput('HPP (Harga Modal)', hppCtrl, type: TextInputType.number),
                        _buildInput('Stok Awal', stokCtrl, type: TextInputType.number),
                      ]
                    ],
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      if (namaCtrl.text.isEmpty || hargaCtrl.text.isEmpty) return;
                      // Simpan via API
                      final res = await ApiService.post('products', {
                        'name': namaCtrl.text,
                        'product_type': jenisProduk,
                        'barcode': barcodeCtrl.text,
                        'selling_price': int.tryParse(hargaCtrl.text) ?? 0,
                        'purchase_price': int.tryParse(hppCtrl.text) ?? 0,
                        'stock': int.tryParse(stokCtrl.text) ?? 0,
                      });
                      if (res.statusCode == 201) {
                        Navigator.pop(ctx);
                        _muatProduk();
                      }
                    },
                    child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // =================================================================
  // WIDGET UTAMA (BODY)
  // =================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // HEADER PENCARIAN & FILTER
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.card,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onSubmitted: (val) {
                          _searchQuery = val;
                          _muatProduk();
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari nama, SKU, Barcode (Scan USB di sini)',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryEmerald),
                            onPressed: () {}, // Tombol scan HP
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: _tampilkanFormTambah,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                // TAB FILTER (Semua, Produk, Jasa, Menipis)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 'ALL'),
                      _buildFilterChip('Produk', 'PRODUCT'),
                      _buildFilterChip('Jasa', 'SERVICE'),
                      _buildFilterChip('Menipis', 'LOW_STOCK'),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // DAFTAR LIST PRODUK
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                : _products.isEmpty 
                    ? const Center(child: Text('Data tidak ditemukan', style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (ctx, index) {
                          var p = _products[index];
                          bool isJasa = p['product_type'] == 'SERVICE';
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                            child: Row(
                              children: [
                                Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(color: isJasa ? AppColors.goldPremium.withOpacity(0.1) : AppColors.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(isJasa ? Icons.cut : Icons.inventory_2, color: isJasa ? AppColors.goldPremium : AppColors.primaryEmerald),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                      const SizedBox(height: 4),
                                      Text('Barcode: ${p['barcode'] ?? '-'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(_formatRupiah(p['selling_price']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    isJasa 
                                      ? const Text('JASA', style: TextStyle(color: AppColors.goldPremium, fontSize: 12, fontWeight: FontWeight.bold))
                                      : Text('Stok: ${p['stock']} ${p['unit']}', style: TextStyle(color: (p['stock'] <= p['min_stock']) ? AppColors.error : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type) {
    bool isActive = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() => _filterType = type);
          _muatProduk();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.navyActive : AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppColors.navyActive : AppColors.border),
          ),
          child: Text(label, style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}
