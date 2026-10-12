import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core/services/product_service.dart';
import 'tema.dart';

class HalamanProduk extends StatefulWidget {
  const HalamanProduk({super.key});

  @override
  State<HalamanProduk> createState() => _HalamanProdukState();
}

class _HalamanProdukState extends State<HalamanProduk> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<Product> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final result = await _productService.getProducts(search: _searchCtrl.text.trim());
      setState(() => _products = result);
    } catch (e) {
      _showNotif(e.toString(), Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hapusProduk(int id) async {
    // Konfirmasi Hapus
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: const Text('Data produk tidak dapat dikembalikan setelah dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await _productService.deleteProduct(id);
      _showNotif('Produk berhasil dihapus', AppColors.primaryEmerald);
      _fetchProducts();
    } catch (e) {
      _showNotif(e.toString(), Colors.red);
    }
  }

  // --- FORM TAMBAH / EDIT (Meluncur dari bawah) ---
  void _tampilFormProduk({Product? produk}) {
    final bool isEdit = produk != null;
    final skuCtrl = TextEditingController(text: produk?.sku ?? '');
    final nameCtrl = TextEditingController(text: produk?.name ?? '');
    final priceCtrl = TextEditingController(text: produk?.price.toInt().toString() ?? '');
    final stockCtrl = TextEditingController(text: produk?.stock.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24, left: 24, right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 20),
            TextField(controller: skuCtrl, decoration: _inputDecor('SKU / Barcode', Icons.qr_code)),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: _inputDecor('Nama Produk', Icons.shopping_bag)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _inputDecor('Harga Jual (Rp)', Icons.monetization_on))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: _inputDecor('Stok', Icons.inventory))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                    _showNotif('Nama dan Harga wajib diisi', Colors.red);
                    return;
                  }
                  
                  final data = {
                    'sku': skuCtrl.text,
                    'name': nameCtrl.text,
                    'price': priceCtrl.text,
                    'stock': stockCtrl.text.isEmpty ? '0' : stockCtrl.text,
                  };

                  Navigator.pop(context); // Tutup form
                  setState(() => _isLoading = true);

                  try {
                    if (isEdit) {
                      await _productService.updateProduct(produk.id, data);
                      _showNotif('Produk diperbarui', AppColors.primaryEmerald);
                    } else {
                      await _productService.createProduct(data);
                      _showNotif('Produk ditambahkan', AppColors.primaryEmerald);
                    }
                    _fetchProducts(); // Refresh list
                  } catch (e) {
                    setState(() => _isLoading = false);
                    _showNotif(e.toString(), Colors.red);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Simpan Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.slateGray, size: 20),
      filled: true,
      fillColor: AppColors.lightGray,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);
  }

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan), backgroundColor: warna, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Data Produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilFormProduk(),
        backgroundColor: AppColors.primaryEmerald,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // PANEL PENCARIAN
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama atau SKU produk...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primaryEmerald),
                  onPressed: _fetchProducts,
                ),
                filled: true,
                fillColor: AppColors.lightGray,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (_) => _fetchProducts(),
            ),
          ),

          // DAFTAR PRODUK
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _products.isEmpty
                ? const Center(child: Text('Tidak ada data produk.', style: TextStyle(color: AppColors.slateGray)))
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80), // bottom padding buat FAB
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final p = _products[index];
                      // Indikator Stok Menipis
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
                            child: const Icon(Icons.inventory_2, color: Color(0xFFB8860B)), // Ikon warna Champagne
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(p.sku.isNotEmpty ? p.sku : 'Tanpa SKU', style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(_formatCurrency(p.price), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: stokMenipis ? Colors.red.shade50 : AppColors.lightGray, borderRadius: BorderRadius.circular(4)),
                                    child: Text('Stok: ${p.stock}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stokMenipis ? Colors.red : AppColors.textSecondary)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: AppColors.slateGray),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _tampilFormProduk(produk: p);
                              } else if (value == 'hapus') {
                                _hapusProduk(p.id);
                              }
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
