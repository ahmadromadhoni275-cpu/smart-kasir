import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart'; // <-- Import Printer Service
import 'tema.dart';

class HalamanLaporanProduk extends StatefulWidget {
  const HalamanLaporanProduk({super.key});

  @override
  State<HalamanLaporanProduk> createState() => _HalamanLaporanProdukState();
}

class _HalamanLaporanProdukState extends State<HalamanLaporanProduk> {
  final ReportService _service = ReportService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'Hari Ini';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  
  // Variabel Rekap
  double _totalRevenue = 0;
  int _totalItemQty = 0;

  @override
  void initState() {
    super.initState();
    _setFilterDate('Hari Ini');
  }

  void _setFilterDate(String filterType) {
    DateTime now = DateTime.now();
    setState(() {
      _selectedFilter = filterType;
      if (filterType == 'Hari Ini') {
        _dateFrom = now;
        _dateTo = now;
        _fetchProductSales();
      } else if (filterType == '7 Hari') {
        _dateFrom = now.subtract(const Duration(days: 6));
        _dateTo = now;
        _fetchProductSales();
      } else if (filterType == 'Bulan Ini') {
        _dateFrom = DateTime(now.year, now.month, 1);
        _dateTo = DateTime(now.year, now.month + 1, 0);
        _fetchProductSales();
      } else if (filterType == 'Kustom') {
        _pilihTanggalKustom();
      }
    });
  }

  Future<void> _pilihTanggalKustom() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
      builder: (context, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryEmerald)), child: child!),
    );

    if (picked != null) {
      setState(() { _dateFrom = picked.start; _dateTo = picked.end; });
      _fetchProductSales();
    } else {
      setState(() => _selectedFilter = 'Hari Ini');
      _setFilterDate('Hari Ini');
    }
  }

  Future<void> _fetchProductSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final String strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      final data = await _service.getProductSales(strDateFrom, strDateTo);
      
      final productsList = data['products'] ?? [];
      
      double tempRevenue = 0;
      int tempQty = 0;
      
      for (var p in productsList) {
        tempRevenue += double.tryParse(p['revenue']?.toString() ?? '0') ?? 0.0;
        tempQty += int.tryParse(p['qty']?.toString() ?? '0') ?? 0;
      }

      setState(() {
        _products = productsList;
        _categories = data['categories'] ?? [];
        _totalRevenue = tempRevenue;
        _totalItemQty = tempQty;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);
  }

  // ==========================================
  // LOGIKA CETAK LAPORAN PRODUK
  // ==========================================
  Future<void> _cetakLaporanProduk() async {
    if (_isLoading) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menyiapkan pencetakan...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.blue)
    );

    // Menyusun metrik utama
    Map<String, dynamic> dataLaporan = {
      'periode': _selectedFilter,
      'total_item_terjual': '$_totalItemQty Unit',
      'total_omzet_produk': _totalRevenue,
      '-- PRODUK TERLARIS --': '', // Sebagai pembatas/judul sub-bagian
    };

    // Menyusun Top 10 Produk ke dalam struktur map agar bisa di-looping otomatis oleh PrinterService
    int batasCetak = _products.length > 10 ? 10 : _products.length;
    for (int i = 0; i < batasCetak; i++) {
      var item = _products[i];
      String nama = item['product_name']?.toString() ?? 'Produk';
      String qty = item['qty']?.toString() ?? '0';
      
      // Format Key: "Qty x Nama Produk", Value: Total Revenue-nya
      dataLaporan['$qty x $nama'] = double.tryParse(item['revenue']?.toString() ?? '0') ?? 0.0;
    }

    try {
      await PrinterService().cetakLaporan(dataLaporan, "LAPORAN PRODUK");
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan produk berhasil dicetak!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: AppColors.primaryEmerald)
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Laporan Produk', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.navyActive),
          // --- TOMBOL CETAK DI SUDUT KANAN ATAS ---
          actions: [
            IconButton(
              icon: const Icon(Icons.print, color: AppColors.primaryEmerald),
              tooltip: 'Cetak Laporan',
              onPressed: _isLoading ? null : _cetakLaporanProduk,
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primaryEmerald,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryEmerald,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Performa Produk'),
              Tab(text: 'Performa Kategori'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildFilterPanel(),
            if (!_isLoading && _errorMessage.isEmpty) _buildSummaryCards(),
            
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                : _errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : TabBarView(
                        children: [
                          _buildProductList(),
                          _buildCategoryList(),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Hari Ini', '7 Hari', 'Bulan Ini', 'Kustom'].map((filter) {
            bool isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selected: isSelected,
                selectedColor: AppColors.primaryEmerald,
                backgroundColor: AppColors.lightGray,
                showCheckmark: false,
                onSelected: (val) { if (val) _setFilterDate(filter); },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.purple.shade600, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Omzet Produk', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(_formatCurrency(_totalRevenue), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Item Terjual', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$_totalItemQty Unit', style: const TextStyle(color: AppColors.navyActive, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: LIST PRODUK ---
  Widget _buildProductList() {
    if (_products.isEmpty) return _buildEmptyState('Belum ada produk terjual');
    
    return RefreshIndicator(
      color: AppColors.primaryEmerald,
      onRefresh: _fetchProductSales,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final item = _products[index];
          String nama = item['product_name']?.toString() ?? 'Produk';
          String kategori = item['category_name']?.toString() ?? 'Tanpa Kategori';
          int qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
          double rev = double.tryParse(item['revenue']?.toString() ?? '0') ?? 0;
          
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
              ),
              title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(kategori, style: const TextStyle(fontSize: 12)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatCurrency(rev), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                  const SizedBox(height: 4),
                  Text('$qty Terjual', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 2: LIST KATEGORI ---
  Widget _buildCategoryList() {
    if (_categories.isEmpty) return _buildEmptyState('Data kategori kosong');
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final item = _categories[index];
        String kategori = item['category_name']?.toString() ?? 'Tanpa Kategori';
        int qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
        double rev = double.tryParse(item['revenue']?.toString() ?? '0') ?? 0;
        
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: const CircleAvatar(backgroundColor: AppColors.lightGray, child: Icon(Icons.category, color: AppColors.textSecondary, size: 20)),
            title: Text(kategori, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatCurrency(rev), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                const SizedBox(height: 4),
                Text('$qty Unit', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchProductSales,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald),
            child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
