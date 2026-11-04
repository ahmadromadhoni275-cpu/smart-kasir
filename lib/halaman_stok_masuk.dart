import 'dart:ui';
import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/stock_service.dart';

class HalamanStokMasuk extends StatefulWidget {
  const HalamanStokMasuk({super.key});

  @override
  State<HalamanStokMasuk> createState() => _HalamanStokMasukState();
}

class _HalamanStokMasukState extends State<HalamanStokMasuk> {
  bool _isLoading = false;
  List<dynamic> _products = [];
  dynamic _selectedProduct;
  
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muatProduk();
  }

  Future<void> _muatProduk() async {
    setState(() => _isLoading = true);
    try {
      final prods = await StockService.getProducts();
      setState(() => _products = prods);
    } catch (e) {
      _showNotif(e.toString(), AppColors.error);
    }
    setState(() => _isLoading = false);
  }

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
      backgroundColor: warna, 
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
    ));
  }

  Future<void> _simpanStokMasuk() async {
    if (_selectedProduct == null) {
      _showNotif('Pilih produk terlebih dahulu', Colors.orange);
      return;
    }
    if (_qtyCtrl.text.isEmpty || int.tryParse(_qtyCtrl.text) == null || int.parse(_qtyCtrl.text) <= 0) {
      _showNotif('Jumlah stok harus lebih dari 0', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await StockService.stockIn(
        int.parse(_selectedProduct['product_id'].toString()),
        int.parse(_qtyCtrl.text),
        _noteCtrl.text,
      );
      _showNotif('Stok berhasil ditambahkan!', AppColors.primaryEmerald);
      
      setState(() {
        _selectedProduct = null;
        _qtyCtrl.clear();
        _noteCtrl.clear();
      });
      await _muatProduk(); // Refresh daftar agar stok dropdown ter-update
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _glassInputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label, 
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.smartBlue, size: 20), 
      filled: true, 
      fillColor: Colors.white.withOpacity(0.7), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.smartBlue, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Catat Stok Masuk', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.withOpacity(0.2), height: 1)),
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
          
          SafeArea(
            child: _isLoading && _products.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6), 
                      borderRadius: BorderRadius.circular(24), 
                      border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                      boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pilih Produk', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<dynamic>(
                              value: _selectedProduct,
                              decoration: _glassInputDecor('Produk', Icons.inventory_2_outlined),
                              hint: const Text('Pilih produk dari daftar...'),
                              isExpanded: true,
                              items: _products.map((p) => DropdownMenuItem(value: p, child: Text('${p['name']} (Stok: ${p['stock']} ${p['unit'] ?? 'Pcs'})'))).toList(),
                              onChanged: (val) => setState(() => _selectedProduct = val),
                            ),
                            const SizedBox(height: 20),

                            const Text('Jumlah Masuk', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _qtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _glassInputDecor('Cth: 10', Icons.add_circle_outline),
                            ),
                            const SizedBox(height: 20),

                            const Text('Catatan / No Referensi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _noteCtrl,
                              decoration: _glassInputDecor('Misal: Restok Supplier (INV-001)', Icons.note_alt_outlined),
                            ),
                            const SizedBox(height: 40),

                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.smartBlue, 
                                  elevation: 5,
                                  shadowColor: AppColors.smartBlue.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                ),
                                onPressed: _isLoading ? null : _simpanStokMasuk,
                                child: _isLoading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                  : const Text('SIMPAN STOK MASUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
