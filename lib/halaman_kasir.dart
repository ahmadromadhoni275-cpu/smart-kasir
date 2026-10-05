import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'tema.dart';
import 'services/api_service.dart';
import 'halaman_shift.dart'; // <-- Pastikan import halaman shift

class HalamanKasir extends StatefulWidget {
  const HalamanKasir({super.key});

  @override
  State<HalamanKasir> createState() => _HalamanKasirState();
}

class _HalamanKasirState extends State<HalamanKasir> {
  bool _isCheckingShift = true; // State khusus untuk mengecek shift awal
  bool _hasActiveShift = false; 

  bool _isLoading = true;
  List<dynamic> _products = [];
  String _searchQuery = '';
  
  // State Keranjang
  List<Map<String, dynamic>> _cart = [];
  String? _selectedTable;
  double _discount = 0;
  
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 1. Cek Shift terlebih dahulu sebelum memuat produk
    _cekShiftAktif();
  }

  // =========================================================
  // CEK STATUS SHIFT
  // =========================================================
  Future<void> _cekShiftAktif() async {
    setState(() => _isCheckingShift = true);
    try {
      final response = await ApiService.get('shifts/current');
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['data'] != null) {
          _hasActiveShift = true;
          _muatProduk(); // Lanjut muat produk jika shift ada
        } else {
          _hasActiveShift = false;
        }
      }
    } catch (e) {
      _hasActiveShift = false;
    }
    setState(() => _isCheckingShift = false);
  }

  Future<void> _muatProduk() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('cashier/products?search=$_searchQuery');
      if (response.statusCode == 200) {
        setState(() {
          _products = json.decode(response.body)['data'];
        });
      }
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  // =========================================================
  // LOGIKA KERANJANG
  // =========================================================
  void _addToCart(dynamic product) {
    if (product['product_type'] == 'PRODUCT' && product['stock'] <= 0) {
      _showNotif('Stok habis!', AppColors.error);
      return;
    }

    setState(() {
      int index = _cart.indexWhere((item) => item['product_id'] == product['product_id'] && item['order_type'] == 'DINE_IN' && item['note'] == null);
      if (index != -1) {
        if (product['product_type'] == 'PRODUCT' && _cart[index]['quantity'] >= product['stock']) {
          _showNotif('Melebihi batas stok', AppColors.error);
          return;
        }
        _cart[index]['quantity']++;
      } else {
        _cart.add({
          'product_id': product['product_id'],
          'name': product['name'],
          'price': double.parse(product['selling_price'].toString()),
          'quantity': 1,
          'order_type': 'DINE_IN', // Default
          'note': null,
          'type': product['product_type'],
          'max_stock': product['stock']
        });
      }
    });
  }

  double get _subtotal {
    double total = 0;
    for (var item in _cart) { total += (item['price'] * item['quantity']); }
    return total;
  }

  double get _grandTotal => _subtotal - _discount;

  // =========================================================
  // MODAL JASA MANUAL
  // =========================================================
  void _tampilkanFormJasaManual() {
    TextEditingController namaCtrl = TextEditingController();
    TextEditingController hargaCtrl = TextEditingController();
    TextEditingController qtyCtrl = TextEditingController(text: '1');
    TextEditingController catatanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Jasa Manual', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Jasa', isDense: true, border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: hargaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (Rp)', isDense: true, border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: TextField(controller: catatanCtrl, decoration: const InputDecoration(labelText: 'Catatan Opsional', isDense: true, border: OutlineInputBorder()))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald),
            onPressed: () {
              if (namaCtrl.text.isEmpty || hargaCtrl.text.isEmpty) return;
              setState(() {
                _cart.add({
                  'product_id': null, // Menandakan ini Jasa Manual
                  'name': namaCtrl.text,
                  'price': double.tryParse(hargaCtrl.text) ?? 0,
                  'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                  'order_type': 'DINE_IN',
                  'note': catatanCtrl.text.isEmpty ? null : catatanCtrl.text,
                  'type': 'SERVICE',
                  'max_stock': 9999 // Tidak ada limit stok
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('Tambahkan', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // =========================================================
  // MODAL PEMBAYARAN & CHECKOUT KE CI4
  // =========================================================
  void _tampilkanModalPembayaran() {
    if (_cart.isEmpty) return;
    String metode = 'CASH';
    TextEditingController uangCtrl = TextEditingController(text: _grandTotal.toInt().toString());
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('TOTAL TAGIHAN', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(_formatRupiah(_grandTotal), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                  const SizedBox(height: 24),
                  
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: ['CASH', 'QRIS', 'TRANSFER'].map((m) {
                      return ChoiceChip(
                        label: Text(m),
                        selected: metode == m,
                        selectedColor: AppColors.primaryEmerald.withOpacity(0.2),
                        onSelected: (val) {
                          if(val) setModalState(() => metode = m);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  if (metode == 'CASH')
                    TextField(
                      controller: uangCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Uang Diterima',
                        prefixText: 'Rp ',
                        filled: true, fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isProcessing ? null : () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: isProcessing ? null : () async {
                  double paidAmount = double.tryParse(uangCtrl.text) ?? 0;
                  if (metode == 'CASH' && paidAmount < _grandTotal) {
                    _showNotif('Uang kurang!', AppColors.error);
                    return;
                  }

                  setModalState(() => isProcessing = true);
                  
                  final payload = {
                    "table_id": _selectedTable != null ? int.tryParse(_selectedTable!.replaceAll('Meja ', '')) : null,
                    "discount": _discount,
                    "tax": 0,
                    "payment_method": metode,
                    "paid_amount": paidAmount,
                    "items": _cart.map((c) => {
                      "product_id": c['product_id'],
                      "name": c['name'], 
                      "price": c['price'], 
                      "quantity": c['quantity'],
                      "order_type": c['order_type'],
                      "note": c['note']
                    }).toList()
                  };

                  final res = await ApiService.post('cashier/transactions', payload);
                  if (res.statusCode == 201) {
                    final data = json.decode(res.body)['data'];
                    Navigator.pop(ctx);
                    setState(() { _cart.clear(); _selectedTable = null; });
                    _tampilkanSukses(data['invoice'], data['kembalian']);
                    _muatProduk(); // Refresh stok
                  } else {
                    _showNotif('Gagal: ${json.decode(res.body)['message']}', AppColors.error);
                    setModalState(() => isProcessing = false);
                  }
                },
                child: isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Text('SELESAIKAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      ),
    );
  }

  void _tampilkanSukses(String invoice, dynamic kembalian) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.greenAccent, size: 60),
            const SizedBox(height: 16),
            const Text('TRANSAKSI BERHASIL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(invoice, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            if (kembalian > 0) ...[
              const Text('Kembalian:', style: TextStyle(color: AppColors.textSecondary)),
              Text(_formatRupiah(kembalian), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.print), label: const Text('Cetak'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald), onPressed: () => Navigator.pop(ctx), child: const Text('Transaksi Baru', style: TextStyle(color: Colors.white)))),
              ],
            )
          ],
        ),
      )
    );
  }

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan), backgroundColor: warna, behavior: SnackBarBehavior.floating));
  }

  // =========================================================
  // UI KOMPONEN
  // =========================================================
  Widget _buildProductGrid() {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
      : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _products.length,
          itemBuilder: (ctx, i) {
            var p = _products[i];
            bool isJasa = p['product_type'] == 'SERVICE';
            bool habis = !isJasa && p['stock'] <= 0;

            return InkWell(
              onTap: habis ? null : () => _addToCart(p),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: habis ? AppColors.error.withOpacity(0.5) : AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isJasa ? Icons.cut : Icons.fastfood, size: 40, color: habis ? AppColors.border : AppColors.primaryEmerald),
                    const SizedBox(height: 12),
                    Text(p['name'], textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontWeight: FontWeight.bold, color: habis ? AppColors.textSecondary : AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_formatRupiah(double.parse(p['selling_price'].toString())), style: const TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (isJasa)
                      const Text('JASA', style: TextStyle(fontSize: 10, color: AppColors.goldPremium, fontWeight: FontWeight.bold))
                    else
                      Text(habis ? 'HABIS' : 'Stok: ${p['stock']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: habis ? AppColors.error : AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          },
        );
  }

  Widget _buildCartPanel() {
    return Container(
      width: 350,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.navyActive,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KERANJANG (${_cart.length} Item)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                if (_cart.isNotEmpty)
                  InkWell(onTap: () => setState(() => _cart.clear()), child: const Icon(Icons.delete_sweep, color: Colors.white70))
              ],
            ),
          ),
          Expanded(
            child: _cart.isEmpty 
              ? const Center(child: Text('Keranjang Kosong', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (ctx, i) {
                    var item = _cart[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      border: const Border(bottom: BorderSide(color: AppColors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                              Text(_formatRupiah(item['price'] * item['quantity']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ChoiceChip(label: const Text('Dine In', style: TextStyle(fontSize: 10)), selected: item['order_type'] == 'DINE_IN', onSelected: (v) => setState(() => item['order_type'] = 'DINE_IN')),
                              const SizedBox(width: 8),
                              ChoiceChip(label: const Text('Takeaway', style: TextStyle(fontSize: 10)), selected: item['order_type'] == 'TAKEAWAY', onSelected: (v) => setState(() => item['order_type'] = 'TAKEAWAY')),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: TextFormField(
                              initialValue: item['note'],
                              style: const TextStyle(fontSize: 12),
                              decoration: const InputDecoration(hintText: '+ Tambah catatan opsional', isDense: true, border: InputBorder.none, icon: Icon(Icons.edit_note, size: 16)),
                              onChanged: (val) => item['note'] = val.isEmpty ? null : val,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary), onPressed: () => setState(() { if (item['quantity'] > 1) item['quantity']--; else _cart.removeAt(i); })),
                              Text('${item['quantity']}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryEmerald),
                                onPressed: () => setState(() {
                                  if (item['type'] == 'PRODUCT' && item['quantity'] >= item['max_stock']) return;
                                  item['quantity']++;
                                }),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
          ),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTable,
                  decoration: const InputDecoration(labelText: 'No. Meja', border: OutlineInputBorder(), isDense: true),
                  items: ['Meja 01', 'Meja 02', 'Meja 03'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setState(() => _selectedTable = val),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text(_formatRupiah(_subtotal))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon'), Text(_formatRupiah(_discount))]),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(_formatRupiah(_grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryEmerald))]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _cart.isEmpty ? null : _tampilkanModalPembayaran,
                    child: const Text('BAYAR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. TAMPILAN LOADING AWAL SAAT CEK SHIFT
    if (_isCheckingShift) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)),
      );
    }

    // 2. TAMPILAN TERKUNCI JIKA SHIFT BELUM DIBUKA
    if (!_hasActiveShift) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock, size: 80, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('SHIFT BELUM DIBUKA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 8),
              const Text('Anda harus membuka shift kasir terlebih dahulu\nsebelum dapat melakukan transaksi penjualan.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Arahkan ke halaman shift, dan cek ulang saat kembali
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanShift())).then((_) => _cekShiftAktif());
                },
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text('Buka Shift Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      );
    }

    // 3. TAMPILAN NORMAL (SHIFT SUDAH AKTIF)
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

        Widget mainContent = Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.card,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onSubmitted: (val) {
                        setState(() => _searchQuery = val);
                        _muatProduk(); 
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari produk / SKU / scan barcode di sini...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(icon: const Icon(Icons.camera_alt), onPressed: () {}),
                        filled: true, fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyActive,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: _tampilkanFormJasaManual,
                    icon: const Icon(Icons.design_services, color: Colors.white, size: 18),
                    label: const Text('Jasa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            Expanded(child: _buildProductGrid()),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                Expanded(child: mainContent),
                _buildCartPanel(),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: mainContent,
          floatingActionButton: _cart.isNotEmpty
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primaryEmerald,
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => Container(
                        height: MediaQuery.of(context).size.height * 0.9,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                        child: _buildCartPanel(),
                      )
                    );
                  },
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  label: Text('${_cart.length} Item - ${_formatRupiah(_grandTotal)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null,
        );
      }
    );
  }
}
