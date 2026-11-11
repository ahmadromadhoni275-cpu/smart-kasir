import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart';
import 'models/report_model.dart'; // Tempat di mana ProductReportData berada
import 'models/product_report_model.dart';
import 'tema.dart';

class HalamanLaporanProduk extends StatefulWidget {
  const HalamanLaporanProduk({super.key});

  @override
  State<HalamanLaporanProduk> createState() => _HalamanLaporanProdukState();
}

class _HalamanLaporanProdukState extends State<HalamanLaporanProduk> with SingleTickerProviderStateMixin {
  final ReportService _service = ReportService();
  late TabController _tabController;
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'Hari Ini';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  List<ProductPerformanceItem> _products = [];
  List<CategoryPerformanceItem> _categories = [];
  
  // Variabel Rekap
  double _totalRevenue = 0;
  int _totalItemQty = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setFilterDate('Hari Ini');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryEmerald)), 
        child: child!
      ),
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

      // PERBAIKAN: Tangkap respon sebagai dynamic (Map) terlebih dahulu
      final dynamic rawData = await _service.getProductSales(strDateFrom, strDateTo);
      
      // PERBAIKAN: Konversi Map JSON mentah menjadi objek ProductReportData 
      // menggunakan fungsi bawaan fromJson
      final ProductReportData data = ProductReportData.fromJson(rawData as Map<String, dynamic>);
      
      // Karena class ProductReportData sudah menangani mapping List di dalam fungsi fromJson-nya,
      // kita tidak perlu me-map ulang list produk dan kategori di sini.
      final List<ProductPerformanceItem> parsedProducts = (data.products as List).map((e) => e as ProductPerformanceItem).toList();
      final List<CategoryPerformanceItem> parsedCategories = (data.categories as List).map((e) => e as CategoryPerformanceItem).toList();
      
      double tempRevenue = 0;
      int tempQty = 0;
      
      for (var p in parsedProducts) {
        tempRevenue += p.revenue;
        tempQty += p.qty;
      }

      setState(() {
        _products = parsedProducts;
        _categories = parsedCategories;
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

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ==========================================
  // LOGIKA CETAK LAPORAN PRODUK
  // ==========================================
  Future<void> _cetakLaporanProduk() async {
    if (_isLoading || _products.isEmpty) return;

    _showNotif('Menyiapkan pencetakan...', AppColors.smartBlue);

    Map<String, dynamic> dataLaporan = {
      'periode': _selectedFilter,
      'total_item_terjual': '$_totalItemQty Unit',
      'total_omzet_produk': _totalRevenue,
      '-- PRODUK TERLARIS --': '',
    };

    int batasCetak = _products.length > 10 ? 10 : _products.length;
    for (int i = 0; i < batasCetak; i++) {
      var item = _products[i];
      dataLaporan['${item.qty} x ${item.productName}'] = item.revenue;
    }

    try {
      await PrinterService().cetakLaporan(dataLaporan, "LAPORAN PRODUK");
      if (!mounted) return;
      _showNotif('Laporan produk berhasil dicetak!', AppColors.primaryEmerald);
    } catch (e) {
      if (!mounted) return;
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
  }

  Widget _buildGlassFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => _setFilterDate(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyActive : Colors.white.withOpacity(0.5),
          border: Border.all(color: isSelected ? AppColors.navyActive : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.navyActive.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Laporan Produk', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.smartBlue),
            tooltip: 'Cetak Laporan',
            onPressed: _isLoading || _products.isEmpty ? null : _cetakLaporanProduk,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryEmerald,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryEmerald,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          dividerColor: Colors.grey.withOpacity(0.2),
          tabs: const [
            Tab(text: 'Performa Produk'),
            Tab(text: 'Performa Kategori'),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Crystal
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd],
              ),
            ),
          ),

          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 48), // +48 for TabBar height

              // Filter Glass Bar
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5)))),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildGlassFilterChip('Hari Ini'),
                          _buildGlassFilterChip('7 Hari'),
                          _buildGlassFilterChip('Bulan Ini'),
                          _buildGlassFilterChip('Kustom'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (!_isLoading && _errorMessage.isEmpty) _buildSummaryCards(),

              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                  : _errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildProductList(),
                            _buildCategoryList(),
                          ],
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.purple.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Omzet Produk', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_formatCurrency(_totalRevenue), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Item Terjual', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$_totalItemQty Unit', style: const TextStyle(color: AppColors.navyActive, fontSize: 18, fontWeight: FontWeight.w900)),
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
    if (_products.isEmpty) return _buildEmptyState('Belum ada produk terjual di periode ini');
    
    return RefreshIndicator(
      color: AppColors.primaryEmerald,
      backgroundColor: Colors.white,
      onRefresh: _fetchProductSales,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 40),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final item = _products[index];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
              boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: index == 0 ? AppColors.goldPremium.withOpacity(0.2) : Colors.purple.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Center(
                      child: Text(
                        '#${index + 1}', 
                        style: TextStyle(fontWeight: FontWeight.w900, color: index == 0 ? AppColors.goldPremium : Colors.purple.shade700)
                      )
                    ),
                  ),
                  title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(item.categoryName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatCurrency(item.revenue), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryEmerald)),
                      const SizedBox(height: 4),
                      Text('${item.qty} Terjual', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 2: LIST KATEGORI ---
  Widget _buildCategoryList() {
    if (_categories.isEmpty) return _buildEmptyState('Data performa kategori kosong');
    
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 40),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final item = _categories[index];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.category_outlined, color: AppColors.smartBlue),
                ),
                title: Text(item.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatCurrency(item.revenue), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryEmerald)),
                    const SizedBox(height: 4),
                    Text('${item.qty} Unit Terjual', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ],
                ),
              ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
          ),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProductSales,
              icon: const Icon(Icons.refresh, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              ),
              label: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
