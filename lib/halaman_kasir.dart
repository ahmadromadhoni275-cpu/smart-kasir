import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import 'tema.dart';
import 'core/services/product_service.dart';
import 'core/services/payment_service.dart';
import 'core/services/shift_service.dart';
import 'core/services/transaction_service.dart';
import 'core/services/printer_service.dart';

import 'models/transaction_item_model.dart';
import 'models/payment_method_model.dart';
import 'halaman_shift.dart'; 

class HalamanKasir extends StatefulWidget {
  const HalamanKasir({super.key});

  @override
  State<HalamanKasir> createState() => _HalamanKasirState();
}

class _HalamanKasirState extends State<HalamanKasir> {
  bool _isCheckingShift = true; 
  int? _activeShiftId; 

  bool _isLoading = true;
  List<dynamic> _products = []; // FIX: Diubah ke dynamic agar tidak bentrok dengan Model
  String _searchQuery = '';
  
  final List<TransactionItemModel> _cart = [];
  final TextEditingController _noMejaCtrl = TextEditingController(); 
  final TextEditingController _searchCtrl = TextEditingController();
  
  double _discount = 0;
  
  // --- STATE PENGATURAN TOKO LOKAL ---
  bool _enableProducts = true;
  bool _enableTableNumber = false;
  bool _enableServices = false;
  bool _enableOrderType = false;

  List<PaymentMethodModel> _paymentMethods = [
    PaymentMethodModel(type: 'CASH', name: 'Tunai (Cash)')
  ];
  
  final ProductService _productService = ProductService();
  final ShiftService _shiftService = ShiftService();
  final PaymentService _paymentService = PaymentService();
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _loadStoreSettings().then((_) => _cekShiftAktif());
  }

  // --- SINKRONISASI PENGATURAN LOKAL ---
  Future<void> _loadStoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableProducts = prefs.getBool('enable_products') ?? true;
      _enableTableNumber = prefs.getBool('enable_table_number') ?? false;
      _enableServices = prefs.getBool('enable_services') ?? false;
      _enableOrderType = prefs.getBool('enable_order_type') ?? false;
    });
  }

  // --- 1. PROTEKSI SHIFT AKTIF ---
  Future<void> _cekShiftAktif() async {
    setState(() => _isCheckingShift = true);
    try {
      final shiftData = await _shiftService.getCurrentShift();
      if (shiftData != null && shiftData.status == 'OPEN') {
        _activeShiftId = shiftData.shiftId;
        if (_enableProducts) _muatProduk(); 
        _fetchMetodePembayaran(); 
      } else {
        _activeShiftId = null;
        if (mounted) _tampilNotifShiftTutup();
      }
    } catch (e) {
      _activeShiftId = null;
      if (mounted) _tampilNotifShiftTutup();
    }
    if (mounted) setState(() => _isCheckingShift = false);
  }

  Future<void> _fetchMetodePembayaran() async {
    try {
      final methods = await _paymentService.getActiveMethods();
      setState(() {
        _paymentMethods = [
          PaymentMethodModel(type: 'CASH', name: 'Tunai (Cash)'),
          ...methods
        ];
      });
    } catch (e) {
      debugPrint('Gagal memuat metode bayar: $e');
    }
  }

  Future<void> _muatProduk() async {
    if (!_enableProducts) return;
    
    setState(() => _isLoading = true);
    try {
      final res = await _productService.getProducts(search: _searchQuery);
      // FIX: Perbaikan syntax error pada assignment state
      if (mounted) setState(() => _products = res);
    } catch (e) {
      debugPrint('Gagal memuat produk: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  // --- LOGIKA KERANJANG ---
  // FIX: parameter product diubah ke dynamic
  void _addToCart(dynamic product) {
    if (_activeShiftId == null) {
      _tampilNotifShiftTutup();
      return;
    }

    if (product.productType == 'PRODUCT' && product.stock <= 0) {
      _tampilPopupCantik('Stok Habis!', 'Produk ini tidak dapat ditambahkan karena stok kosong.', Icons.remove_shopping_cart, AppColors.error);
      return;
    }

    setState(() {
      int index = _cart.indexWhere((item) => 
        item.productId == product.productId && 
        item.orderType == 'DINE_IN' && 
        item.note == null
      );
      
      if (index != -1) {
        if (product.productType == 'PRODUCT' && _cart[index].quantity >= product.stock) {
           _tampilPopupCantik('Batas Stok!', 'Maksimal stok yang tersedia hanya ${product.stock}.', Icons.warning_amber_rounded, AppColors.warning);
          return;
        }
        _cart[index].quantity++;
      } else {
        _cart.add(TransactionItemModel(
          productId: product.productId,
          itemType: product.productType,
          name: product.name,
          price: (product.sellingPrice as num).toDouble(),
          purchasePrice: (product.purchasePrice as num).toDouble(),
          quantity: 1,
          maxStock: (product.stock as num).toInt(),
          orderType: _enableOrderType ? 'DINE_IN' : 'TAKEAWAY', 
        ));
      }
    });
  }

  double get _subtotal {
    double total = 0;
    for (var item in _cart) { total += (item.price * item.quantity); }
    return total;
  }
  
  double get _grandTotal => _subtotal - _discount;

  // --- DIALOG JASA MANUAL ---
  void _tampilkanFormJasaManual() {
    if (_activeShiftId == null) {
      _tampilNotifShiftTutup();
      return;
    }

    TextEditingController namaCtrl = TextEditingController();
    TextEditingController hargaCtrl = TextEditingController();
    TextEditingController qtyCtrl = TextEditingController(text: '1');
    TextEditingController catatanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.design_services, color: AppColors.navyActive),
            SizedBox(width: 8),
            Text('Tambah Jasa Manual', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: namaCtrl, decoration: InputDecoration(labelText: 'Nama Jasa', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: AppColors.lightGray)),
              const SizedBox(height: 12),
              TextField(controller: hargaCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Harga (Rp)', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: AppColors.lightGray)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Qty', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: AppColors.lightGray))),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: TextField(controller: catatanCtrl, decoration: InputDecoration(labelText: 'Catatan (Opsional)', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: AppColors.lightGray))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (namaCtrl.text.isEmpty || hargaCtrl.text.isEmpty) return;
              setState(() {
                _cart.add(TransactionItemModel(
                  productId: null, 
                  name: namaCtrl.text,
                  price: double.tryParse(hargaCtrl.text) ?? 0,
                  purchasePrice: 0,
                  quantity: int.tryParse(qtyCtrl.text) ?? 1,
                  itemType: 'SERVICE',
                  note: catatanCtrl.text.isEmpty ? null : catatanCtrl.text,
                  maxStock: 9999, 
                  orderType: _enableOrderType ? 'DINE_IN' : 'TAKEAWAY'
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Tambahkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- DIALOG PEMBAYARAN (SPLIT PAYMENT) ---
  void _tampilkanModalPembayaran() {
    if (_activeShiftId == null) {
      _tampilNotifShiftTutup();
      return;
    }
    if (_cart.isEmpty) return;
    
    List> appliedPayments = [
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
            totalBayarInput += double.tryParse((p['ctrl'] as TextEditingController).text) ?? 0;
          }
          double kurang = _grandTotal - totalBayarInput;
          if (kurang < 0) kurang = 0; 

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Pembayaran Tagihan', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.navyActive)),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.navyActive, AppColors.primaryEmerald], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: Column(
                        children: [
                          const Text('TOTAL TAGIHAN', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_formatRupiah(_grandTotal), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    ...appliedPayments.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var payItem = entry.value;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: payItem['method'].toString(),
                                decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                                items: _paymentMethods.map((m) => DropdownMenuItem<String>(value: m.type, child: Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
                                onChanged: (val) => setModalState(() => payItem['method'] = val!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: payItem['ctrl'] as TextEditingController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: InputDecoration(prefixText: 'Rp ', isDense: true, filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                                onChanged: (_) => setModalState((){}), 
                              ),
                            ),
                            if (appliedPayments.length > 1)
                              IconButton(icon: const Icon(Icons.remove_circle, color: AppColors.error), onPressed: () => setModalState(() => appliedPayments.removeAt(idx)))
                          ],
                        ),
                      );
                    }),
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          setModalState(() {
                            appliedPayments.add({
                              'method': _paymentMethods.first.type, 
                              'ctrl': TextEditingController(text: kurang.toInt().toString())
                            });
                          });
                        }, 
                        icon: const Icon(Icons.add, size: 16, color: AppColors.smartBlue), 
                        label: const Text('Split Pembayaran', style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold))
                      ),
                    ),
                    
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sisa Kurang:', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        Text(_formatRupiah(kurang), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: isProcessing ? null : () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), elevation: 4),
                onPressed: isProcessing ? null : () async {
                  if (totalBayarInput < _grandTotal) {
                    _tampilPopupCantik('Pembayaran Kurang!', 'Uang yang diinput belum menutupi total tagihan.', Icons.error_outline, AppColors.error);
                    return;
                  }

                  setModalState(() => isProcessing = true);
                  
                  final payload = {
                    "shift_id": _activeShiftId, 
                    "table_number": _enableTableNumber && _noMejaCtrl.text.isNotEmpty ? _noMejaCtrl.text : null,
                    "discount": _discount,
                    "tax": 0,
                    "payments": appliedPayments.map((p) => {
                      "method": p['method'].toString(),
                      "amount": double.tryParse((p['ctrl'] as TextEditingController).text) ?? 0
                    }).toList(), 
                    "items": _cart.map((c) => c.toJson()).toList()
                  };

                  try {
                    final dataTransaksi = await _transactionService.createTransaction(payload);
                    
                    if (mounted) Navigator.pop(ctx); 
                    setState(() { _cart.clear(); _noMejaCtrl.clear(); });
                    if (_enableProducts) _muatProduk(); 

                    _tampilSuksesCetak(dataTransaksi);
                  } catch (e) {
                    if (mounted) Navigator.pop(ctx);
                    _tampilPopupCantik('Gagal Membayar', e.toString().replaceAll('Exception: ', ''), Icons.warning, AppColors.error);
                  }
                },
                child: isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('PROSES BAYAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              )
            ],
          );
        }
      ),
    );
  }

  // --- POPUP NOTIFIKASI CANTIK ---
  void _tampilPopupCantik(String judul, String pesan, IconData ikon, Color warna) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: warna.withOpacity(0.15), shape: BoxShape.circle), child: Icon(ikon, color: warna, size: 56)),
              const SizedBox(height: 24),
              Text(judul, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navyActive)),
              const SizedBox(height: 12),
              Text(pesan, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: warna, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Mengerti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  void _tampilKonfirmasiKosongkan() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kosongkan Keranjang?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        content: const Text('Semua item di keranjang akan dihapus dan direset kembali.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () { setState(() => _cart.clear()); Navigator.pop(ctx); },
            child: const Text('Kosongkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  // --- 3. MODAL PAKSAAN BUKA SHIFT ---
  void _tampilNotifShiftTutup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: Icon(Icons.lock_clock, size: 60, color: Colors.red.shade400)),
              const SizedBox(height: 24),
              const Text('SHIFT BELUM DIBUKA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navyActive)),
              const SizedBox(height: 12),
              const Text('Anda harus membuka shift kasir terlebih dahulu sebelum dapat memproses transaksi pelanggan.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanShift())).then((_) => _cekShiftAktif());
                  },
                  icon: const Icon(Icons.lock_open, color: Colors.white),
                  label: const Text('Buka Shift Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
  
  void _tampilSuksesCetak(Map<String, dynamic> dataTransaksi) {
    String invoice = dataTransaksi['invoice_number'] ?? '-';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20), 
                decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.15), shape: BoxShape.circle), 
                child: const Icon(Icons.check_circle, color: AppColors.primaryEmerald, size: 64)
              ),
              const SizedBox(height: 24),
              const Text('TRANSAKSI BERHASIL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navyActive)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)),
                child: Text(invoice, style: const TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.smartBlue, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: () async {
                        try {
                          _showNotif('Mencetak struk...', AppColors.smartBlue);
                          await PrinterService().cetakStruk(dataTransaksi);
                        } catch (e) {
                          _showNotif('Gagal mencetak: ${e.toString().replaceAll('Exception: ', '')}', AppColors.error);
                        }
                      }, 
                      icon: const Icon(Icons.print, color: AppColors.smartBlue, size: 20), 
                      label: const Text('Cetak Struk', style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold))
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryEmerald,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4
                      ), 
                      onPressed: () => Navigator.pop(ctx), 
                      child: const Text('Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                    )
                  ),
                ],
              )
            ],
          ),
        ),
      )
    );
  }

  void _showNotif(String pesan, Color warna) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
      backgroundColor: warna, 
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }


  Widget _buildProductGrid() {
    if (!_enableProducts) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Modul Produk Dinonaktifkan', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Anda hanya dapat menggunakan Jasa Manual.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return _isLoading 
      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
      : GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, childAspectRatio: 0.8, crossAxisSpacing: 16, mainAxisSpacing: 16),
          itemCount: _products.length,
          itemBuilder: (ctx, i) {
            // FIX: Menggunakan tipe dynamic
            final p = _products[i];
            bool isJasa = p.productType == 'SERVICE';
            bool habis = !isJasa && (p.stock as num) <= 0;

            return InkWell(
              onTap: habis ? null : () => _addToCart(p),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: habis ? Colors.red.shade200 : Colors.white),
                  boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: isJasa ? AppColors.goldPremium.withOpacity(0.1) : AppColors.smartBlue.withOpacity(0.1), shape: BoxShape.circle),
                          child: Center(child: Icon(isJasa ? Icons.design_services : Icons.inventory_2, size: 40, color: habis ? Colors.grey : isJasa ? AppColors.goldPremium : AppColors.smartBlue)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(p.name.toString(), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: habis ? Colors.grey : AppColors.navyActive)),
                      const SizedBox(height: 4),
                      Text(_formatRupiah(p.sellingPrice as num), style: TextStyle(color: habis ? Colors.grey : AppColors.primaryEmerald, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (isJasa)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.goldPremium.withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Text('JASA', style: TextStyle(fontSize: 10, color: AppColors.goldPremium, fontWeight: FontWeight.bold)))
                      else
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: habis ? Colors.red.shade50 : AppColors.lightGray, borderRadius: BorderRadius.circular(12)), child: Text(habis ? 'HABIS' : 'Stok: ${p.stock}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: habis ? Colors.red : Colors.grey.shade700))),
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
      width: 420, 
      decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(color: AppColors.navyActive),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('KERANJANG (${_cart.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                  ],
                ),
                if (_cart.isNotEmpty)
                  InkWell(
                    onTap: _tampilKonfirmasiKosongkan, 
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Kosongkan', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))
                    )
                  )
              ],
            ),
          ),
          Expanded(
            child: _cart.isEmpty 
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('Keranjang Kosong', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))]))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _cart.length,
                  itemBuilder: (ctx, i) {
                    var item = _cart[i];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.navyActive))),
                              const SizedBox(width: 8),
                              Text(_formatRupiah(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryEmerald, fontSize: 15)),
                            ],
                          ),
                          
                          // FITUR DINAMIS: Jenis Pesanan
                          if (_enableOrderType) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('Dine In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), 
                                  selected: item.orderType == 'DINE_IN', 
                                  selectedColor: AppColors.smartBlue.withOpacity(0.2),
                                  backgroundColor: AppColors.lightGray,
                                  showCheckmark: false,
                                  onSelected: (v) => setState(() => item.orderType = 'DINE_IN')
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Takeaway', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), 
                                  selected: item.orderType == 'TAKEAWAY', 
                                  selectedColor: AppColors.smartBlue.withOpacity(0.2), 
                                  backgroundColor: AppColors.lightGray,
                                  showCheckmark: false,
                                  onSelected: (v) => setState(() => item.orderType = 'TAKEAWAY')
                                ),
                              ],
                            ),
                          ],
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: TextFormField(
                              initialValue: item.note,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Tambah catatan pesanan...', 
                                prefixIcon: const Icon(Icons.edit_note, size: 18, color: AppColors.textSecondary),
                                isDense: true, 
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                                filled: true, fillColor: AppColors.lightGray, 
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                              ),
                              onChanged: (val) => item.note = val.isEmpty ? null : val,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.remove, color: AppColors.error, size: 20), onPressed: () => setState(() { if (item.quantity > 1) item.quantity--; else _cart.removeAt(i); })),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: AppColors.smartBlue, size: 20),
                                      onPressed: () => setState(() {
                                        if (item.itemType == 'PRODUCT' && item.quantity >= item.maxStock) {
                                          _tampilPopupCantik('Batas Stok', 'Maksimal stok tercapai.', Icons.warning, AppColors.warning); return;
                                        }
                                        item.quantity++;
                                      }),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
          ),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Column(
              children: [
                // FITUR DINAMIS: Nomor Meja
                if (_enableTableNumber) ...[
                  TextField(
                    controller: _noMejaCtrl,
                    decoration: InputDecoration(
                      labelText: 'No / Nama Meja (Opsional)', 
                      hintText: 'Cth: Meja 12', 
                      filled: true, fillColor: AppColors.lightGray, 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), 
                      prefixIcon: const Icon(Icons.table_restaurant, color: AppColors.textSecondary)
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)), Text(_formatRupiah(_subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)), Text('- ${_formatRupiah(_discount)}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))]),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL BAYAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.navyActive)), Text(_formatRupiah(_grandTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: AppColors.primaryEmerald))]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4, shadowColor: AppColors.primaryEmerald.withOpacity(0.4)),
                    onPressed: _cart.isEmpty ? null : _tampilkanModalPembayaran,
                    icon: const Icon(Icons.point_of_sale, color: Colors.white),
                    label: const Text('BAYAR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
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
    if (_isCheckingShift) return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));
    if (_activeShiftId == null) return const Scaffold(backgroundColor: Colors.white, body: Center()); 

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

        Widget mainContent = Stack(
          children: [
            // Background Gradient 
            Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]))),
            
            Column(
              children: [
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onSubmitted: (val) { setState(() => _searchQuery = val); _muatProduk(); },
                              decoration: InputDecoration(
                                hintText: 'Cari nama produk / barcode...', 
                                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary), 
                                filled: true, fillColor: Colors.white.withOpacity(0.8), 
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), 
                                contentPadding: const EdgeInsets.symmetric(vertical: 0)
                              ),
                            ),
                          ),
                          
                          // FITUR DINAMIS: Jasa Manual
                          if (_enableServices) ...[
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPremium, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
                              onPressed: _tampilkanFormJasaManual,
                              icon: const Icon(Icons.design_services, color: Colors.white, size: 20),
                              label: const Text('Jasa Manual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildProductGrid()),
              ],
            ),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(title: const Text('Kasir Pintar', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)), backgroundColor: Colors.white.withOpacity(0.7), flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))), iconTheme: const IconThemeData(color: AppColors.navyActive), elevation: 0),
            body: Row(children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
                  child: mainContent,
                )
              ), 
              _buildCartPanel()
            ]),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(title: const Text('Kasir Pintar', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)), backgroundColor: Colors.white.withOpacity(0.7), flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))), iconTheme: const IconThemeData(color: AppColors.navyActive), elevation: 0),
          body: Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
            child: mainContent,
          ),
          floatingActionButton: _cart.isNotEmpty
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primaryEmerald,
                  onPressed: () {
                    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => Container(height: MediaQuery.of(context).size.height * 0.9, clipBehavior: Clip.antiAlias, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: _buildCartPanel()));
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
