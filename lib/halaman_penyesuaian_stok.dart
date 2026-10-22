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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(color: Colors.white)), backgroundColor: warna));
  }

  Future<void> _simpanPenyesuaian() async {
    if (_selectedProduct == null || _actualCtrl.text.isEmpty) {
      _showNotif('Data tidak lengkap', Colors.orange);
      return;
    }
    if (_noteCtrl.text.trim().isEmpty) {
      _showNotif('Alasan penyesuaian wajib diisi!', Colors.red);
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
      await _muatProduk(); // Refresh stok sistem terbaru
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Penyesuaian Stok (Opname)', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: _isLoading && _products.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Produk', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<dynamic>(
                      value: _selectedProduct,
                      decoration: InputDecoration(filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
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
                        decoration: BoxDecoration(color: AppColors.navyActive, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Stok Sistem Saat Ini', style: TextStyle(color: Colors.white70)),
                            Text('${_selectedProduct['stock']} ${_selectedProduct['unit'] ?? 'Pcs'}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const Text('Stok Fisik Aktual (Dihitung)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _actualCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _hitungSelisih(),
                      decoration: InputDecoration(hintText: 'Masukkan jumlah fisik yang ada di toko', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 12),

                    if (_selectedProduct != null && _actualCtrl.text.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Selisih: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_selisih > 0 ? '+ $_selisih' : '$_selisih', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _selisih == 0 ? Colors.green : (_selisih < 0 ? Colors.red : Colors.blue))),
                        ],
                      ),
                    const SizedBox(height: 20),

                    const Text('Alasan Penyesuaian (Wajib)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      decoration: InputDecoration(hintText: 'Misal: Barang rusak, hilang, dsb', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _isLoading ? null : _simpanPenyesuaian,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN PENYESUAIAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
