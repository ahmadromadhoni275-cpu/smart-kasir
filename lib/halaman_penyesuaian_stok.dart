import 'dart:ui';
import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/stock_service.dart';

class HalamanPenyesuaianStok extends StatefulWidget {
  const HalamanPenyesuaianStok({super.key});

  @override
  State<HalamanPenyesuaianStok> createState() => _HalamanPenyesuaianStokState();
}

class _HalamanPenyesuaianStokState extends State<HalamanPenyesuaianStok> {
  bool _isLoading = false;
  List<dynamic> _products = [];
  dynamic _selectedProduct;
  
  final TextEditingController _actualCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  
  int _selisih = 0;

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
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  void _hitungSelisih() {
    if (_selectedProduct != null && _actualCtrl.text.isNotEmpty) {
      int systemStock = int.tryParse(_selectedProduct['stock'].toString()) ?? 0;
      int actualStock = int.tryParse(_actualCtrl.text) ?? 0;
      setState(() {
        _selisih = actualStock - systemStock;
      });
    }
  }

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
      backgroundColor: warna, 
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
    ));
  }

  Future<void> _simpanPenyesuaian() async {
    if (_selectedProduct == null || _actualCtrl.text.isEmpty) {
      _showNotif('Data fisik aktual wajib diisi', Colors.orange);
      return;
    }
    if (_noteCtrl.text.trim().isEmpty) {
      _showNotif('Alasan penyesuaian (catatan) wajib diisi!', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await StockService.adjustStock(
        int.parse(_selectedProduct['product_id'].toString()),
        int.parse(_actualCtrl.text),
        _noteCtrl.text,
      );
      _showNotif('Penyesuaian stok berhasil disimpan', AppColors.primaryEmerald);
      
      setState(() {
        _selectedProduct = null;
        _actualCtrl.clear();
        _noteCtrl.clear();
        _selisih = 0;
      });
      await _muatProduk(); 
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _glassInputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label, 
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.orange.shade700, size: 20), 
      filled: true, 
      fillColor: Colors.white.withOpacity(0.7), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.orange.shade700, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Penyesuaian Stok (Opname)', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.withOpacity(0.2), height: 1)),
      ),
      body: Stack(
        children: [
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
              ? const Center(child: CircularProgressIndicator(color: Colors.orange))
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.bottom(16),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                                  const SizedBox(width: 8),
                                  const Expanded(child: Text('Gunakan fitur ini jika ada perbedaan antara stok fisik dan sistem.', style: TextStyle(fontSize: 12, color: Colors.black87))),
                                ],
                              ),
                            ),
                            
                            const Text('Pilih Produk', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<dynamic>(
                              value: _selectedProduct,
                              decoration: _glassInputDecor('Produk', Icons.inventory_2_outlined),
                              hint: const Text('Pilih produk...'),
                              isExpanded: true,
                              items: _products.map((p) => DropdownMenuItem(value: p, child: Text('${p['name']}'))).toList(),
                              onChanged: (val) {
                                setState(() { _selectedProduct = val; _actualCtrl.clear(); _selisih = 0; });
                              },
                            ),
                            const SizedBox(height: 20),

                            if (_selectedProduct != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppColors.navyActive, AppColors.smartBlue]),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: AppColors.navyActive.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Stok Sistem Saat Ini:', style: TextStyle(color: Colors.white70)),
                                    Text('${_selectedProduct['stock']} ${_selectedProduct['unit'] ?? 'Pcs'}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            const Text('Stok Fisik Aktual', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _actualCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (v) => _hitungSelisih(),
                              decoration: _glassInputDecor('Jumlah fisik yang ada di toko', Icons.calculate_outlined),
                            ),
                            const SizedBox(height: 12),

                            if (_selectedProduct != null && _actualCtrl.text.isNotEmpty)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: _selisih == 0 ? Colors.green.withOpacity(0.1) : (_selisih < 0 ? AppColors.error.withOpacity(0.1) : AppColors.smartBlue.withOpacity(0.1)), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Selisih: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                                      Text(_selisih > 0 ? '+ $_selisih' : '$_selisih', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _selisih == 0 ? Colors.green : (_selisih < 0 ? AppColors.error : AppColors.smartBlue))),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),

                            const Text('Alasan Penyesuaian (Wajib)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _noteCtrl,
                              decoration: _glassInputDecor('Misal: Barang kedaluwarsa, hilang, dsb', Icons.note_alt_outlined),
                            ),
                            const SizedBox(height: 40),

                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade700, 
                                  elevation: 5,
                                  shadowColor: Colors.orange.withOpacity(0.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                                ),
                                onPressed: _isLoading ? null : _simpanPenyesuaian,
                                child: _isLoading 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                  : const Text('SIMPAN PENYESUAIAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
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
