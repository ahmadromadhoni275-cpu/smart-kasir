import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/product_service.dart';
import 'core/services/category_service.dart'; 
import 'models/category_model.dart';          
import 'tema.dart';

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
  
  List<Product> _products = [];
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
        _products = results[0] as List<Product>;
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline, color: AppColors.error, size: 40)),
                  const SizedBox(height: 16),
                  const Text('Hapus Produk?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                  const SizedBox(height: 8),
                  const Text('Data produk hanya akan dinonaktifkan (Soft Delete) agar tidak merusak riwayat transaksi lama.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Colors.grey)))),
                      Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Hapus', style: TextStyle(color: Colors.white)))),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _productService.deleteProduct(id);
      _showNotif('Produk berhasil dihapus', AppColors.primaryEmerald);
      _fetchInitialData();
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
      setState(() => _isLoading = false);
    }
  }

  void _tampilFormProduk({Product? produk}) {
    final bool isEdit = produk != null;
    
    final nameCtrl = TextEditingController(text: isEdit ? produk.name : '');
    final skuCtrl = TextEditingController(text: isEdit ? produk.sku : '');
    // Asumsi model Product sudah ditambahkan properti baru berikut:
    final barcodeCtrl = TextEditingController(text: isEdit ? (produk.barcode ?? '') : '');
    final unitCtrl = TextEditingController(text: isEdit ? (produk.unit ?? 'Pcs') : 'Pcs');
    final purchasePriceCtrl = TextEditingController(text: isEdit ? (produk.purchasePrice?.toInt().toString() ?? '0') : '');
    final priceCtrl = TextEditingController(text: isEdit ? produk.sellingPrice.toInt().toString() : '');
    final stockCtrl = TextEditingController(text: isEdit ? produk.stock.toString() : '');
    
    String selectedType = isEdit ? produk.productType : 'PRODUCT';
    bool isActive = isEdit ? (produk.status == 'ACTIVE') : true;
    
    int? selectedCategoryId;
    if (isEdit && produk.categoryId != null) {
      if (_categories.any((c) => c.categoryId == produk.categoryId)) {
        selectedCategoryId = produk.categoryId;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isJasa = selectedType == 'SERVICE';
          
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5))),
                ),
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, top: 24, left: 24, right: 24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 16),
                      Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                      const SizedBox(height: 24),
                      
                      // -- UPLOAD GAMBAR (UI Placeholder) --
                      Center(
                        child: InkWell(
                          onTap: () {
                            // TODO: Implement ImagePicker
                            _showNotif('Fitur unggah gambar akan segera hadir.', AppColors.smartBlue);
                          },
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.smartBlue.withOpacity(0.3), style: BorderStyle.solid)),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.add_a_photo, color: AppColors.smartBlue, size: 30), SizedBox(height: 8), Text('Foto', style: TextStyle(color: AppColors.smartBlue, fontSize: 12, fontWeight: FontWeight.bold))],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- PILIH TIPE (BARANG FISIK / JASA) ---
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: AppColors.lightGray.withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setModalState(() => selectedType = 'PRODUCT'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(color: !isJasa ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: !isJasa ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : []),
                                  child: Center(child: Text('Barang Fisik', style: TextStyle(fontWeight: FontWeight.bold, color: !isJasa ? AppColors.smartBlue : AppColors.textSecondary))),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setModalState(() => selectedType = 'SERVICE'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(color: isJasa ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isJasa ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] : []),
                                  child: Center(child: Text('Jasa / Layanan', style: TextStyle(fontWeight: FontWeight.bold, color: isJasa ? AppColors.goldPremium : AppColors.textSecondary))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        decoration: _glassInputDecor('Kategori', Icons.category),
                        hint: const Text('Pilih Kategori'),
                        items: _categories.map((cat) => DropdownMenuItem<int>(value: cat.categoryId, child: Text(cat.name))).toList(),
                        onChanged: (val) => setModalState(() => selectedCategoryId = val),
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(controller: nameCtrl, decoration: _glassInputDecor('Nama Produk *', isJasa ? Icons.design_services : Icons.shopping_bag)),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(child: TextField(controller: skuCtrl, decoration: _glassInputDecor('SKU', Icons.tag))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: barcodeCtrl, decoration: _glassInputDecor('Barcode', Icons.qr_code_scanner))),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: TextField(controller: purchasePriceCtrl, keyboardType: TextInputType.number, decoration: _glassInputDecor('Harga Modal (HPP)', Icons.account_balance_wallet_outlined))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: _glassInputDecor('Harga Jual *', Icons.monetization_on))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (!isJasa) Row(
                        children: [
                          Expanded(child: TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: _glassInputDecor('Stok Awal', Icons.inventory_2_outlined))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: unitCtrl, decoration: _glassInputDecor('Satuan (Pcs, Kg)', Icons.scale))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Toggle Status Aktif/Nonaktif
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status Produk Aktif', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                            Switch(
                              value: isActive,
                              activeColor: AppColors.primaryEmerald,
                              onChanged: (val) => setModalState(() => isActive = val),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity, height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                              _showNotif('Nama dan Harga Jual wajib diisi', AppColors.warning);
                              return;
                            }
                            
                            final data = {
                              'sku': skuCtrl.text,
                              'barcode': barcodeCtrl.text,
                              'name': nameCtrl.text,
                              'purchase_price': purchasePriceCtrl.text.isEmpty ? '0' : purchasePriceCtrl.text,
                              'selling_price': priceCtrl.text,
                              'stock': isJasa ? '0' : (stockCtrl.text.isEmpty ? '0' : stockCtrl.text),
                              'unit': isJasa ? 'Layanan' : unitCtrl.text,
                              'status': isActive ? 'ACTIVE' : 'INACTIVE',
                              'category_id': selectedCategoryId, 
                              'product_type': selectedType,
                            };

                            Navigator.pop(context); 
                            setState(() => _isLoading = true);

                            try {
                              if (isEdit) {
                                await _productService.updateProduct(produk!.id, data);
                                _showNotif('Produk berhasil diperbarui', AppColors.primaryEmerald);
                              } else {
                                await _productService.createProduct(data);
                                _showNotif('Produk berhasil ditambahkan', AppColors.primaryEmerald);
                              }
                              _fetchInitialData(); 
                            } catch (e) {
                              String err = e.toString().replaceAll('Exception: ', '');
                              if(err.toLowerCase().contains('duplicate')) {
                                _showNotif('Gagal: SKU atau Barcode sudah digunakan.', AppColors.error);
                              } else {
                                _showNotif(err, AppColors.error);
                              }
                              setState(() => _isLoading = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryEmerald,
                            elevation: 5,
                            shadowColor: AppColors.primaryEmerald.withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                          child: const Text('SIMPAN PRODUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  InputDecoration _glassInputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label, 
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.smartBlue, size: 20), 
      filled: true, 
      fillColor: Colors.white.withOpacity(0.6), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.smartBlue, width: 1.5)),
    );
  }

  String _formatCurrency(double amount) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);
  void _showNotif(String pesan, Color warna) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: warna, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  Widget _buildGlassMenuButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), 
              border: Border.all(color: color.withOpacity(0.3)), 
              borderRadius: BorderRadius.circular(12)
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color), 
                const SizedBox(width: 8), 
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color))
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Data Produk & Stok', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.withOpacity(0.2), height: 1)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilFormProduk(),
        backgroundColor: AppColors.primaryEmerald,
        elevation: 8,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Produk Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          // Background Gradient (Crystal UI Vibe)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]
              ),
            ),
          ),
          
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              
              // Top Action Panel
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.4)))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Cari nama, SKU, atau Barcode...',
                            prefixIcon: const Icon(Icons.search, color: AppColors.smartBlue),
                            filled: true, fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                          onSubmitted: (_) => _fetchInitialData(),
                        ),
                        
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildGlassMenuButton(Icons.add_box_outlined, 'Stok Masuk', AppColors.smartBlue, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanStokMasuk())).then((_) => _fetchInitialData());
                              }),
                              const SizedBox(width: 12),
                              _buildGlassMenuButton(Icons.tune, 'Opname Stok', Colors.orange.shade700, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanPenyesuaianStok())).then((_) => _fetchInitialData());
                              }),
                              const SizedBox(width: 12),
                              _buildGlassMenuButton(Icons.history, 'Riwayat', AppColors.primaryEmerald, () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanRiwayatStok()));
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Product List
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                  : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.textSecondary.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            const Text('Belum ada data produk.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100), 
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final p = _products[index];
                          final bool isJasa = p.productType == 'SERVICE';
                          final bool isInactive = (p.status ?? 'ACTIVE') == 'INACTIVE';
                          final bool stokHabis = !isJasa && p.stock <= 0;
                          final bool stokMenipis = !isJasa && p.stock > 0 && p.stock <= 5; // Asumsi min_stock 5

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(isInactive ? 0.4 : 0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                              boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Icon/Gambar Produk
                                      Container(
                                        width: 60, height: 60,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isJasa 
                                              ? [const Color(0xFFF7E7CE), const Color(0xFFEED5A6)] 
                                              : [AppColors.smartBlue.withOpacity(0.2), AppColors.skyBlue.withOpacity(0.2)],
                                            begin: Alignment.topLeft, end: Alignment.bottomRight
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white),
                                        ),
                                        child: Icon(isJasa ? Icons.design_services : Icons.inventory_2_outlined, color: isJasa ? const Color(0xFFB8860B) : AppColors.smartBlue, size: 28), 
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Detail Produk
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(child: Text(p.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isInactive ? AppColors.textSecondary : AppColors.navyActive, decoration: isInactive ? TextDecoration.lineThrough : null))),
                                                if (isJasa)
                                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFB8860B).withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: const Text('JASA', style: TextStyle(fontSize: 10, color: Color(0xFFB8860B), fontWeight: FontWeight.w900)))
                                                else if (isInactive)
                                                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Text('NONAKTIF', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w900)))
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            
                                            Text(p.categoryName ?? 'Tanpa Kategori', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            if (p.sku.isNotEmpty || (p.barcode?.isNotEmpty ?? false))
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text('SKU: ${p.sku} | Barcode: ${p.barcode ?? '-'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ),
                                            
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('Harga Jual', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                                    Text(_formatCurrency(p.sellingPrice), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isInactive ? AppColors.textSecondary : AppColors.primaryEmerald)),
                                                  ],
                                                ),
                                                if (!isJasa)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: stokHabis ? AppColors.error.withOpacity(0.1) : (stokMenipis ? Colors.orange.withOpacity(0.1) : AppColors.lightGray.withOpacity(0.5)), 
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: stokHabis ? AppColors.error.withOpacity(0.3) : Colors.transparent)
                                                    ),
                                                    child: Text(stokHabis ? 'HABIS' : 'Stok: ${p.stock} ${p.unit ?? 'Pcs'}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: stokHabis ? AppColors.error : (stokMenipis ? Colors.orange.shade800 : AppColors.textSecondary))),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Menu Aksi
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        color: Colors.white.withOpacity(0.95),
                                        elevation: 8,
                                        onSelected: (value) {
                                          if (value == 'edit') _tampilFormProduk(produk: p);
                                          if (value == 'hapus') _hapusProduk(p.id);
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: AppColors.smartBlue), SizedBox(width: 12), Text('Edit', style: TextStyle(fontWeight: FontWeight.w500))])),
                                          const PopupMenuItem(value: 'hapus', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.error), SizedBox(width: 12), Text('Hapus', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.error))])),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
