import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

import 'tema.dart';
import 'core/services/product_service.dart';
import 'core/services/payment_service.dart';
import 'core/services/shift_service.dart';
import 'core/services/transaction_service.dart';
import 'core/services/printer_service.dart';

import 'models/product_model.dart';
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
  List<ProductModel> _products = [];
  String _searchQuery = '';
  
  final List<TransactionItemModel> _cart = [];
  final TextEditingController _noMejaCtrl = TextEditingController(); 
  final TextEditingController _searchCtrl = TextEditingController();
  
  double _discount = 0;
  bool _enableTableNumber = false;
  bool _enableServices = false;

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
    _loadStoreSettings(); 
    _cekShiftAktif();
  }

  Future<void> _loadStoreSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableTableNumber = prefs.getBool('enable_table_number') ?? false;
      _enableServices = prefs.getBool('enable_services') ?? false;
    });
  }

  Future<void> _cekShiftAktif() async {
    setState(() => _isCheckingShift = true);
    try {
      final shiftData = await _shiftService.getCurrentShift();
      if (shiftData != null && shiftData['status'] == 'OPEN') {
        _activeShiftId = int.tryParse(shiftData['shift_id'].toString());
        _muatProduk(); 
        _fetchMetodePembayaran(); 
      } else {
        _activeShiftId = null;
        if (mounted) _tampilNotifShiftTutup();
      }
    } catch (e) {
      _activeShiftId = null;
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
    setState(() => _isLoading = true);
    try {
      final res = await _productService.getProducts(search: _searchQuery);
      if (mounted) setState(() => _products = res);
    } catch (e) {
      debugPrint('Gagal memuat produk: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  // --- LOGIKA KERANJANG ---
  void _addToCart(ProductModel product) {
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
          price: product.sellingPrice,
          purchasePrice: product.purchasePrice,
          quantity: 1,
          maxStock: product.stock,
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
    TextEditingController namaCtrl = TextEditingController();
    TextEditingController hargaCtrl = TextEditingController();
    TextEditingController qtyCtrl = TextEditingController(text: '1');
    TextEditingController catatanCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Jasa Manual', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        content: SizedBox(
          width: 350,
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
                  Expanded(flex: 2, child: TextField(controller: catatanCtrl, decoration: const InputDecoration(labelText: 'Catatan (Opsional)', isDense: true, border: OutlineInputBorder()))),
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
                _cart.add(TransactionItemModel(
                  productId: null, 
                  name: namaCtrl.text,
                  price: double.tryParse(hargaCtrl.text) ?? 0,
                  purchasePrice: 0,
                  quantity: int.tryParse(qtyCtrl.text) ?? 1,
                  itemType: 'SERVICE',
                  note: catatanCtrl.text.isEmpty ? null : catatanCtrl.text,
                  maxStock: 9999, 
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Tambahkan', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- DIALOG PEMBAYARAN (SPLIT PAYMENT) ---
  void _tampilkanModalPembayaran() {
    if (_cart.isEmpty) return;
    
    // PERBAIKAN DYNAMIC: Menggunakan List<dynamic> untuk fleksibilitas tipe
    List<dynamic> appliedPayments = [
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Text('TOTAL TAGIHAN', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(_formatRupiah(_grandTotal), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
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
                                items: _paymentMethods.map((m) => DropdownMenuItem<String>(value: m.type, child: Text(m.name, style: const TextStyle(fontSize: 13)))).toList(),
                                onChanged: (val) => setModalState(() => payItem['method'] = val!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: payItem['ctrl'] as TextEditingController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(prefixText: 'Rp ', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
                        label: const Text('Split Pembayaran', style: TextStyle(color: AppColors.smartBlue))
                      ),
                    ),
                    
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sisa Kurang:', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        Text(_formatRupiah(kurang), style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: isProcessing ? null : () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
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
                    // 1. Panggil Service dan simpan kembalian datanya
                    final dataTransaksi = await _transactionService.createTransaction(payload);
                    
                    Navigator.pop(ctx); // Tutup modal pembayaran
                    
                    // 2. Reset Keranjang & Refresh Stok
                    setState(() { _cart.clear(); _noMejaCtrl.clear(); });
                    _muatProduk(); 

                    // 3. Tampilkan Popup Sukses yang memiliki tombol Cetak Struk
                    _tampilSuksesCetak(dataTransaksi);
                    
                  } catch (e) {
                    Navigator.pop(ctx);
                    _tampilPopupCantik('Gagal Membayar', e.toString().replaceAll('Exception: ', ''), Icons.warning, AppColors.error);
                  }
                },
                child: isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('PROSES BAYAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: warna.withOpacity(0.1), shape: BoxShape.circle), child: Icon(ikon, color: warna, size: 48)),
              const SizedBox(height: 20),
              Text(judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 12),
              Text(pesan, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: warna, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text('Kosongkan Keranjang?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Semua item di keranjang akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () { setState(() => _cart.clear()); Navigator.pop(ctx); },
            child: const Text('Kosongkan', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  void _tampilNotifShiftTutup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: Icon(Icons.lock_clock, size: 60, color: Colors.red.shade400)),
              const SizedBox(height: 24),
              const Text('SHIFT BELUM DIBUKA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 12),
              const Text('Anda harus membuka shift kasir terlebih dahulu sebelum melayani pelanggan.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HalamanShift())).then((_) => _cekShiftAktif());
                  },
                  icon: const Icon(Icons.lock_open, color: Colors.white),
                  label: const Text('Buka Shift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.1), shape: BoxShape.circle), 
                child: const Icon(Icons.check_circle, color: AppColors.primaryEmerald, size: 60)
              ),
              const SizedBox(height: 16),
              const Text('TRANSAKSI BERHASIL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 4),
              Text(invoice, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.smartBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () async {
                        try {
                          _showNotif('Mencetak struk...', AppColors.smartBlue);
                          // PANGGIL SERVICE PRINTER DI SINI
                          await PrinterService().cetakStruk(dataTransaksi);
                        } catch (e) {
                          _showNotif('Gagal mencetak: ${e.toString().replaceAll('Exception: ', '')}', AppColors.error);
                        }
                      }, 
                      icon: const Icon(Icons.print, color: AppColors.smartBlue, size: 18), 
                      label: const Text('Cetak Struk', style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold))
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
                      child: const Text('Selesai', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
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

  // Helper untuk notifikasi saat proses mencetak
  void _showNotif(String pesan, Color warna) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
      backgroundColor: warna, 
      behavior: SnackBarBehavior.floating
    ));
  }


  Widget _buildProductGrid() {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
      : GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 180, childAspectRatio: 0.8, crossAxisSpacing: 16, mainAxisSpacing: 16),
          itemCount: _products.length,
          itemBuilder: (ctx, i) {
            ProductModel p = _products[i];
            bool isJasa = p.productType == 'SERVICE';
            bool habis = !isJasa && p.stock <= 0;

            return InkWell(
              onTap: habis ? null : () => _addToCart(p),
              borderRadius: BorderRadius.circular(16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: habis ? Colors.red.shade200 : AppColors.border)),
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
                      Text(p.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: habis ? Colors.grey : AppColors.navyActive)),
                      const SizedBox(height: 4),
                      Text(_formatRupiah(p.sellingPrice), style: TextStyle(color: habis ? Colors.grey : AppColors.primaryEmerald, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (isJasa)
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.goldPremium.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Text('JASA', style: TextStyle(fontSize: 10, color: AppColors.goldPremium, fontWeight: FontWeight.bold)))
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
      width: 400, 
      decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.navyActive,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('KERANJANG (${_cart.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                if (_cart.isNotEmpty)
                  InkWell(onTap: _tampilKonfirmasiKosongkan, child: const Text('Kosongkan', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)))
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
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyActive))),
                              Text(_formatRupiah(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ChoiceChip(label: const Text('Dine In', style: TextStyle(fontSize: 10)), selected: item.orderType == 'DINE_IN', selectedColor: AppColors.smartBlue.withOpacity(0.2), onSelected: (v) => setState(() => item.orderType = 'DINE_IN')),
                              const SizedBox(width: 8),
                              ChoiceChip(label: const Text('Takeaway', style: TextStyle(fontSize: 10)), selected: item.orderType == 'TAKEAWAY', selectedColor: AppColors.smartBlue.withOpacity(0.2), onSelected: (v) => setState(() => item.orderType = 'TAKEAWAY')),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TextFormField(
                              initialValue: item.note,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(hintText: '+ Tambah catatan', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), filled: true, fillColor: AppColors.lightGray, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              onChanged: (val) => item.note = val.isEmpty ? null : val,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.error), onPressed: () => setState(() { if (item.quantity > 1) item.quantity--; else _cart.removeAt(i); })),
                              Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.smartBlue),
                                onPressed: () => setState(() {
                                  if (item.itemType == 'PRODUCT' && item.quantity >= item.maxStock) {
                                    _tampilPopupCantik('Batas Stok', 'Maksimal stok tercapai.', Icons.warning, AppColors.warning); return;
                                  }
                                  item.quantity++;
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: Column(
              children: [
                if (_enableTableNumber) ...[
                  TextField(
                    controller: _noMejaCtrl,
                    decoration: InputDecoration(labelText: 'No / Nama Meja (Opsional)', hintText: 'Cth: Meja 12', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), prefixIcon: const Icon(Icons.table_restaurant, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal', style: TextStyle(color: Colors.grey)), Text(_formatRupiah(_subtotal), style: const TextStyle(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Diskon', style: TextStyle(color: Colors.grey)), Text('- ${_formatRupiah(_discount)}', style: const TextStyle(color: Colors.red))]),
                const Divider(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL BAYAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyActive)), Text(_formatRupiah(_grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primaryEmerald))]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    onPressed: _cart.isEmpty ? null : _tampilkanModalPembayaran,
                    child: const Text('BAYAR SEKARANG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
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
    if (_activeShiftId == null) return const Scaffold(backgroundColor: Colors.white, body: Center()); // UI diambil alih oleh Popup

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

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
                      onSubmitted: (val) { setState(() => _searchQuery = val); _muatProduk(); },
                      decoration: InputDecoration(hintText: 'Cari nama produk / barcode...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 0)),
                    ),
                  ),
                  
                  if (_enableServices) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPremium, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      onPressed: _tampilkanFormJasaManual,
                      icon: const Icon(Icons.design_services, color: Colors.white, size: 20),
                      label: const Text('Jasa Manual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
            ),
            Expanded(child: _buildProductGrid()),
          ],
        );

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Kasir Pintar', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: AppColors.navyActive), elevation: 1),
            body: Row(children: [Expanded(child: mainContent), _buildCartPanel()]),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Kasir Pintar', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: AppColors.navyActive), elevation: 1),
          body: mainContent,
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
