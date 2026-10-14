import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core/services/product_service.dart';
import 'core/services/category_service.dart'; 
import 'models/category_model.dart';          
import 'tema.dart';

// --- IMPORT HALAMAN STOK ---
import 'halaman_stok_masuk.dart';
import 'halaman_penyesuaian_stok.dart';
import 'halaman_riwayat_stok.dart';

class HalamanProduk extends StatefulWidget {
  const HalamanProduk({super.key});

  @override
  State<HalamanProduk> createState() => _HalamanProdukState();
}

class _HalamanProdukState extends State<HalamanProduk> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<dynamic> _products = [];
  List<Category> _categories = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _productService.getProducts(search: _searchCtrl.text.trim()),
        _categoryService.getCategories(),
      ]);
      
      setState(() {
        _products = results[0] as List;
        _categories = (results[1] as List<Category>).where((c) => c.status == 'ACTIVE').toList();
      });
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hapusProduk(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: const Text('Data produk tidak dapat dikembalikan setelah dihapus.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _productService.deleteProduct(id);
      _showNotif('Produk berhasil dihapus', AppColors.greenAccent);
      _fetchInitialData();
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
      setState(() => _isLoading = false);
    }
  }

  void _tampilFormProduk({dynamic produk}) {
    final bool isEdit = produk != null;
    final skuCtrl = TextEditingController(text: isEdit ? produk.sku : '');
    final nameCtrl = TextEditingController(text: isEdit ? produk.name : '');
    final priceCtrl = TextEditingController(text: isEdit ? produk.price.toInt().toString() : '');
    final stockCtrl = TextEditingController(text: isEdit ? produk.stock.toString() : '');
    
    int? selectedCategoryId;
    if (isEdit && produk.categoryId != null) {
      bool exists = _categories.any((c) => c.categoryId == produk.categoryId);
      if (exists) selectedCategoryId = produk.categoryId;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                const SizedBox(height: 20),
                
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: InputDecoration(labelText: 'Kategori Produk', prefixIcon: const Icon(Icons.category), filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  hint: const Text('Pilih Kategori'),
                  items: _categories.map((cat) {
                    return DropdownMenuItem<int>(
                      value: cat.categoryId,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setModalState(() => selectedCategoryId = val);
                  },
                ),
                const SizedBox(height: 12),
                
                TextField(controller: skuCtrl, decoration: _inputDecor('SKU / Barcode', Icons.qr_code)),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: _inputDecor('Nama Produk *', Icons.shopping_bag)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _inputDecor('Harga Jual *', Icons.monetization_on))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: _inputDecor('Stok', Icons.inventory))),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                        _showNotif('Nama dan Harga wajib diisi', AppColors.error);
                        return;
                      }
                      
                      final data = {
                        'sku': skuCtrl.text,
                        'name': nameCtrl.text,
                        'price': priceCtrl.text,
                        'stock': stockCtrl.text.isEmpty ? '0' : stockCtrl.text,
                        'category_id': selectedCategoryId, 
                      };

                      Navigator.pop(context); 
                      setState(() => _isLoading = true);

                      try {
                        if (isEdit) {
                          await _productService.updateProduct(produk.id, data);
                          _showNotif('Produk diperbarui', AppColors.greenAccent);
                        } else {
                          await _productService.createProduct(data);
                          _showNotif('Produk ditambahkan', AppColors.greenAccent);
                        }
                        _fetchInitialData(); 
                      } catch (e) {
                        _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
                        setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Simpan Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20), filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
  }

  String _formatCurrency(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);
  void _showNotif(String pesan, Color warna) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: warna, behavior: SnackBarBehavior.floating));

  // --- WIDGET TOMBOL SUBMENU STOK ---
  Widget _buildStockMenuButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Data Produk & Stok', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilFormProduk(),
        backgroundColor: AppColors.primaryEmerald,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau SKU produk...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(icon: const Icon(Icons.send, color: AppColors.primaryEmerald), onPressed: _fetchInitialData),
                    filled: true, fillColor: AppColors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (_) => _fetchInitialData(),
                ),
                
                // --- SUBMENU STOK ---
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStockMenuButton(Icons.add_box, 'Stok Masuk', Colors.blue, () {
                        // Refresh data saat kembali untuk update jumlah stok di UI
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanStokMasuk())).then((_) => _fetchInitialData());
                      }),
                      const SizedBox(width: 8),
                      _buildStockMenuButton(Icons.tune, 'Penyesuaian (Opname)', Colors.orange, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanPenyesuaianStok())).then((_) => _fetchInitialData());
                      }),
                      const SizedBox(width: 8),
                      _buildStockMenuButton(Icons.history, 'Riwayat Stok', AppColors.primaryEmerald, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanRiwayatStok()));
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _products.isEmpty
                ? const Center(child: Text('Tidak ada data produk.', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), 
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      final bool stokMenipis = p.stock <= 5;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: const Color(0xFFF7E7CE).withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.inventory_2, color: Color(0xFFB8860B)), 
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))),
                              if (p.categoryName != null) 
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(p.categoryName, style: const TextStyle(fontSize: 10, color: AppColors.primaryEmerald, fontWeight: FontWeight.bold)),
                                )
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(p.sku.isNotEmpty ? p.sku : 'Tanpa SKU', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(_formatCurrency(p.price), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: stokMenipis ? Colors.red.shade50 : AppColors.lightGray, borderRadius: BorderRadius.circular(4)),
                                    child: Text('Stok: ${p.stock}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stokMenipis ? AppColors.error : AppColors.textSecondary)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                            onSelected: (value) {
                              if (value == 'edit') _tampilFormProduk(produk: p);
                              if (value == 'hapus') _hapusProduk(p.id);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Edit')])),
                              const PopupMenuItem(value: 'hapus', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus')])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
