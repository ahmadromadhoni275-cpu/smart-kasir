import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Package Cetak
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'tema.dart';
import 'core/services/api_service.dart';
import 'core/services/payment_method_service.dart'; // Pastikan path service metode pembayaran benar
import 'halaman_shift.dart'; 

class HalamanKasir extends StatefulWidget {
  const HalamanKasir({super.key});

  @override
  State<HalamanKasir> createState() => _HalamanKasirState();
}

class _HalamanKasirState extends State<HalamanKasir> {
  bool _isCheckingShift = true; 
  bool _hasActiveShift = false; 
  bool _hasAutoRedirected = false; // Mencegah infinite loop redirect

  bool _isLoading = true;
  List<dynamic> _products = [];
  String _searchQuery = '';
  
  // State Keranjang
  List<Map<String, dynamic>> _cart = [];
  String? _selectedTable;
  double _discount = 0;
  
  // State Metode Pembayaran Aktif (Dinamis dari Backend)
  List<Map<String, dynamic>> _activePaymentMethods = [
    {'type': 'CASH', 'name': 'Tunai (Cash)'} // Default selalu ada
  ];
  
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cekShiftAktif();
  }

  // =========================================================
  // CEK STATUS SHIFT, PRODUK, & METODE BAYAR
  // =========================================================
  Future<void> _cekShiftAktif() async {
    setState(() => _isCheckingShift = true);
    try {
      final response = await ApiService.get('shifts/current');
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        if (resData['data'] != null) {
          // SHIFT AKTIF -> Tampilkan Kasir
          _hasActiveShift = true;
          _muatProduk(); 
          _fetchMetodePembayaran(); // Ambil metode pembayaran aktif toko
        } else {
          // SHIFT TUTUP
          _hasActiveShift = false;
          
          if (!_hasAutoRedirected && mounted) {
            _hasAutoRedirected = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const HalamanShift())
              ).then((_) => _cekShiftAktif());
            });
          }
        }
      }
    } catch (e) {
      _hasActiveShift = false;
    }
    
    if (mounted) {
      setState(() => _isCheckingShift = false);
    }
  }

  Future<void> _fetchMetodePembayaran() async {
    try {
      final methods = await PaymentMethodService.getPaymentMethods();
      final activeMethods = methods.where((m) => m['status'] == 'ACTIVE').toList();
      setState(() {
        _activePaymentMethods = [
          {'type': 'CASH', 'name': 'Tunai (Cash)'},
          ...activeMethods.map((m) => {'type': m['type'], 'name': m['name']})
        ];
      });
    } catch (e) {
      debugPrint('Gagal memuat metode bayar: $e');
    }
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
    } catch (e) {
      debugPrint('Gagal memuat produk: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  // =========================================================
  // LOGIKA KERANJANG
  // =========================================================
  void _addToCart(dynamic product) {
    if (product['product_type'] == 'PRODUCT' && product['stock'] <= 0) {
      _showNotif('Stok habis!', Colors.red);
      return;
    }

    setState(() {
      int index = _cart.indexWhere((item) => item['product_id'] == product['product_id'] && item['order_type'] == 'DINE_IN' && item['note'] == null);
      if (index != -1) {
        if (product['product_type'] == 'PRODUCT' && _cart[index]['quantity'] >= product['stock']) {
          _showNotif('Melebihi batas stok', Colors.orange);
          return;
        }
        _cart[index]['quantity']++;
      } else {
        _cart.add({
          'product_id': product['product_id'],
          'name': product['name'],
          'price': double.parse(product['selling_price'].toString()),
          'quantity': 1,
          'order_type': 'DINE_IN', 
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald),
            onPressed: () {
              if (namaCtrl.text.isEmpty || hargaCtrl.text.isEmpty) return;
              setState(() {
                _cart.add({
                  'product_id': null, 
                  'name': namaCtrl.text,
                  'price': double.tryParse(hargaCtrl.text) ?? 0,
                  'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                  'order_type': 'DINE_IN',
                  'note': catatanCtrl.text.isEmpty ? null : catatanCtrl.text,
                  'type': 'SERVICE',
                  'max_stock': 9999 
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
  // MODAL PEMBAYARAN & CHECKOUT KE CI4 (MENDUKUNG SPLIT PAYMENT)
  // =========================================================
  void _tampilkanModalPembayaran() {
    if (_cart.isEmpty) return;
    
    // State Pembayaran Dinamis
    List<Map<String, dynamic>> appliedPayments = [
      {'method': 'CASH', 'ctrl': TextEditingController(text: _grandTotal.toInt().toString())}
    ];
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          
          double totalBayarInput = 0;
          for (var p in appliedPayments) {
            totalBayarInput += double.tryParse(p['ctrl'].text) ?? 0;
          }
          double kurang = _grandTotal - totalBayarInput;
          if (kurang < 0) kurang = 0; // Jika ada kembalian

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Pembayaran Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          const Text('TOTAL TAGIHAN', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(_formatRupiah(_grandTotal), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // List Metode Pembayaran
                    ...appliedPayments.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Map<String, dynamic> payItem = entry.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: payItem['method'],
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                                items: _activePaymentMethods.map((m) => DropdownMenuItem<String>(value: m['type'], child: Text(m['name'], style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) => setModalState(() => payItem['method'] = val!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: payItem['ctrl'],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(prefixText: 'Rp ', isDense: true, border: OutlineInputBorder()),
                                onChanged: (_) => setModalState((){}), // Trigger hitung ulang
                              ),
                            ),
                            if (appliedPayments.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => setModalState(() => appliedPayments.removeAt(idx)),
                              )
                          ],
                        ),
                      );
                    }),
                    
                    // Tombol Split Payment
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            appliedPayments.add({'method': _activePaymentMethods.first['type'], 'ctrl': TextEditingController(text: kurang.toInt().toString())});
                          });
                        }, 
                        icon: const Icon(Icons.add, size: 16), 
                        label: const Text('Tambah Pembayaran Gabungan (Split)')
                      ),
                    ),
                    
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sisa Kurang:', style: TextStyle(color: Colors.red)),
                        Text(_formatRupiah(kurang), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: isProcessing ? null : () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                onPressed: isProcessing ? null : () async {
                  if (totalBayarInput < _grandTotal) {
                    _showNotif('Uang pembayaran masih kurang!', Colors.red);
                    return;
                  }

                  setModalState(() => isProcessing = true);
                  
                  // Format payments payload untuk Backend
                  List<Map<String, dynamic>> paymentsPayload = appliedPayments.map((p) => {
                    "method": p['method'],
                    "amount": double.tryParse(p['ctrl'].text) ?? 0
                  }).toList();
                  
                  final payload = {
                    "table_id": _selectedTable != null ? int.tryParse(_selectedTable!.replaceAll('Meja ', '')) : null,
                    "discount": _discount,
                    "tax": 0,
                    "payments": paymentsPayload, // Mengirimkan array payments
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
                    
                    // SIMPAN DATA KERANJANG UNTUK DICETAK SEBELUM DIKOSONGKAN
                    final itemsToPrint = List<Map<String, dynamic>>.from(_cart);
                    final totalToPrint = _grandTotal;
                    
                    setState(() { _cart.clear(); _selectedTable = null; });
                    
                    // Tampilkan Sukses & Siapkan Cetak
                    _tampilkanSukses(data['invoice'], data['kembalian'], itemsToPrint, totalToPrint, paymentsPayload);
                    _muatProduk(); 
                  } else {
                    _showNotif('Gagal: ${json.decode(res.body)['message']}', Colors.red);
                    setModalState(() => isProcessing = false);
                  }
                },
                child: isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('SELESAIKAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          );
        }
      ),
    );
  }

  // =========================================================
  // LOGIKA CETAK STRUK BLUETOOTH DARI KASIR
  // =========================================================
  Future<void> _cetakStruk(String invoice, List<Map<String, dynamic>> items, double total, List<Map<String, dynamic>> payments, dynamic kembalian) async {
    if (kIsWeb || Platform.isIOS) {
      _showNotif('Platform tidak didukung.', Colors.red);
      return;
    }
    _showNotif('Mencetak struk...', AppColors.smartBlue);
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text("SMART KASIR", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.row([PosColumn(text: "No", width: 4), PosColumn(text: ": $invoice", width: 8)]);
      bytes += generator.row([PosColumn(text: "Tgl", width: 4), PosColumn(text: ": ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}", width: 8)]);
      
      if (_selectedTable != null) {
        bytes += generator.row([PosColumn(text: "Meja", width: 4), PosColumn(text: ": $_selectedTable", width: 8)]);
      }
      
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

      for (var item in items) {
        String namaMenu = item['name'];
        if (item['order_type'] == 'TAKEAWAY') namaMenu += ' (TA)';
        
        bytes += generator.text(namaMenu, styles: const PosStyles(align: PosAlign.left));
        if (item['note'] != null) {
          bytes += generator.text(" * ${item['note']}", styles: const PosStyles(align: PosAlign.left));
        }
        bytes += generator.row([
          PosColumn(text: "${item['quantity']} x ${_formatRupiah(item['price'])}", width: 8),
          PosColumn(text: _formatRupiah(item['price'] * item['quantity']), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.row([PosColumn(text: "TOTAL TAGIHAN", width: 7, styles: const PosStyles(bold: true)), PosColumn(text: _formatRupiah(total), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true))]);
      
      // CETAK SETIAP METODE PEMBAYARAN GABUNGAN
      for (var pay in payments) {
        bytes += generator.row([PosColumn(text: "BAYAR (${pay['method']})", width: 7), PosColumn(text: _formatRupiah(pay['amount']), width: 5, styles: const PosStyles(align: PosAlign.right))]);
      }
      
      if (kembalian > 0) {
        bytes += generator.row([PosColumn(text: "KEMBALI", width: 7), PosColumn(text: _formatRupiah(kembalian), width: 5, styles: const PosStyles(align: PosAlign.right))]);
      }
      bytes += generator.text("================================", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("Terima Kasih", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);

      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected) {
        await PrintBluetoothThermal.writeBytes(bytes);
        _showNotif('Berhasil mencetak!', AppColors.primaryEmerald);
      } else {
        _showNotif('Printer tidak terhubung.', Colors.red);
      }
    } catch (e) {
      _showNotif('Gagal mencetak: $e', Colors.red);
    }
  }

  void _tampilkanSukses(String invoice, dynamic kembalian, List<Map<String, dynamic>> itemsToPrint, double totalToPrint, List<Map<String, dynamic>> paymentsPayload) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primaryEmerald, size: 80),
            const SizedBox(height: 16),
            const Text('TRANSAKSI BERHASIL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text(invoice, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            if (kembalian > 0) ...[
              const Text('Kembalian:', style: TextStyle(color: Colors.grey)),
              Text(_formatRupiah(kembalian), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF1E293B)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    onPressed: () => _cetakStruk(invoice, itemsToPrint, totalToPrint, paymentsPayload, kembalian), 
                    icon: const Icon(Icons.print, color: Color(0xFF1E293B)), 
                    label: const Text('Cetak', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold))
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryEmerald,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ), 
                    onPressed: () => Navigator.pop(ctx), 
                    child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                  )
                ),
              ],
            )
          ],
        ),
      )
    );
  }

  void _showNotif(String pesan, Color warna) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: warna, behavior: SnackBarBehavior.floating));
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
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.80,
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
              borderRadius: BorderRadius.circular(16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: habis ? Colors.red.shade200 : Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: isJasa ? const Color(0xFFF7E7CE).withOpacity(0.5) : AppColors.lightGray,
                            shape: BoxShape.circle
                          ),
                          child: Center(child: Icon(isJasa ? Icons.design_services : Icons.inventory_2, size: 40, color: habis ? Colors.grey : isJasa ? const Color(0xFFB8860B) : AppColors.primaryEmerald)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(p['name'], textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: habis ? Colors.grey : const Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(_formatRupiah(double.parse(p['selling_price'].toString())), style: TextStyle(color: habis ? Colors.grey : AppColors.primaryEmerald, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (isJasa)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFF7E7CE), borderRadius: BorderRadius.circular(12)), child: const Text('JASA', style: TextStyle(fontSize: 10, color: Color(0xFFB8860B), fontWeight: FontWeight.bold)))
                      else
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: habis ? Colors.red.shade50 : AppColors.lightGray, borderRadius: BorderRadius.circular(12)), child: Text(habis ? 'HABIS' : 'Stok: ${p['stock']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: habis ? Colors.red : Colors.grey.shade700))),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }

  Widget _buildCartPanel() {
    return Container(
      width: 380, // Dibuat sedikit lebih lebar agar lega di tablet
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KERANJANG (${_cart.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                if (_cart.isNotEmpty)
                  InkWell(onTap: () => setState(() => _cart.clear()), child: const Text('Kosongkan', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)))
              ],
            ),
          ),
          Expanded(
            child: _cart.isEmpty 
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300), const SizedBox(height: 12), const Text('Keranjang Kosong', style: TextStyle(color: Colors.grey))]))
              : ListView.builder(
                  itemCount: _cart.length,
                  itemBuilder: (ctx, i) {
                    var item = _cart[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)))),
                              Text(_formatRupiah(item['price'] * item['quantity']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ChoiceChip(label: const Text('Dine In', style: TextStyle(fontSize: 10)), selected: item['order_type'] == 'DINE_IN', selectedColor: AppColors.primaryEmerald.withOpacity(0.2), onSelected: (v) => setState(() => item['order_type'] = 'DINE_IN')),
                              const SizedBox(width: 8),
                              ChoiceChip(label: const Text('Takeaway', style: TextStyle(fontSize: 10)), selected: item['order_type'] == 'TAKEAWAY', selectedColor: AppColors.primaryEmerald.withOpacity(0.2), onSelected: (v) => setState(() => item['order_type'] = 'TAKEAWAY')),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextFormField(
                              initialValue: item['note'],
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(hintText: '+ Tambah catatan (Opsional)', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), filled: true, fillColor: AppColors.lightGray, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              onChanged: (val) => item['note'] = val.isEmpty ? null : val,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => setState(() { if (item['quantity'] > 1) item['quantity']--; else _cart.removeAt(i); })),
                              Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryEmerald),
                                onPressed: () => setState(() {
                                  if (item['type'] == 'PRODUCT' && item['quantity'] >= item['max_stock']) {
                                    _showNotif('Maksimal stok tercapai', Colors.orange);
                                    return;
                                  }
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTable,
                  decoration: InputDecoration(labelText: 'No. Meja', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.table_restaurant)),
                  items: ['Meja 01', 'Meja 02', 'Meja 03', 'Meja 04', 'Meja 05'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setState(() => _selectedTable = val),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(color: Colors.grey)), Text(_formatRupiah(_subtotal), style: const TextStyle(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon', style: TextStyle(color: Colors.grey)), Text('- ${_formatRupiah(_discount)}', style: const TextStyle(color: Colors.red))]),
                const Divider(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))), Text(_formatRupiah(_grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppColors.primaryEmerald))]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
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
    if (_isCheckingShift) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));
    }

    // JIKA SHIFT BELUM DIBUKA
    if (!_hasActiveShift) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: Icon(Icons.lock_clock, size: 80, color: Colors.red.shade400)),
              const SizedBox(height: 24),
              const Text('SHIFT BELUM DIBUKA', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              const Text('Anda harus membuka shift kasir terlebih dahulu\nsebelum dapat melayani pelanggan.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
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

    // JIKA SHIFT AKTIF -> TAMPILKAN KASIR UTAMA
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 600;

        Widget mainContent = Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
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
                        hintText: 'Cari nama produk / scan barcode...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true, fillColor: AppColors.lightGray,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0)
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8860B), 
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0
                    ),
                    onPressed: _tampilkanFormJasaManual,
                    icon: const Icon(Icons.design_services, color: Colors.white, size: 20),
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
            appBar: AppBar(
              title: const Text('Kasir Pintar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xFF1E293B),
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
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
          appBar: AppBar(
            title: const Text('Kasir Pintar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1E293B),
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
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
                        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
