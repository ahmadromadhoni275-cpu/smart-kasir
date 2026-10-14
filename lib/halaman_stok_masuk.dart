import 'package:flutter/material.dart';
import 'tema.dart';
import 'services/stock_service.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(color: Colors.white)), backgroundColor: warna));
  }

  Future<void> _simpanStokMasuk() async {
    if (_selectedProduct == null) {
      _showNotif('Pilih produk terlebih dahulu', Colors.orange);
      return;
    }
    if (_qtyCtrl.text.isEmpty || int.tryParse(_qtyCtrl.text) == null || int.parse(_qtyCtrl.text) <= 0) {
      _showNotif('Jumlah barang tidak valid', Colors.orange);
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
      
      // Reset Form
      setState(() {
        _selectedProduct = null;
        _qtyCtrl.clear();
        _noteCtrl.clear();
      });
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
        title: const Text('Catat Stok Masuk', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
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
                      hint: const Text('Pilih produk dari daftar...'),
                      isExpanded: true,
                      items: _products.map((p) => DropdownMenuItem(value: p, child: Text('${p['sku']} - ${p['name']} (Stok: ${p['stock']})'))).toList(),
                      onChanged: (val) => setState(() => _selectedProduct = val),
                    ),
                    const SizedBox(height: 20),

                    const Text('Jumlah Masuk', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: 'Contoh: 10', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 20),

                    const Text('Catatan / Nomor Referensi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      decoration: InputDecoration(hintText: 'Misal: Restok dari Supplier A (INV-001)', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: _isLoading ? null : _simpanStokMasuk,
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN STOK MASUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
