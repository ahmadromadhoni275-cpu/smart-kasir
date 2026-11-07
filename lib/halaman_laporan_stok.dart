import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart';
import 'models/stock_report_model.dart';
import 'tema.dart';

class HalamanLaporanStok extends StatefulWidget {
  const HalamanLaporanStok({super.key});

  @override
  State<HalamanLaporanStok> createState() => _HalamanLaporanStokState();
}

class _HalamanLaporanStokState extends State<HalamanLaporanStok> with SingleTickerProviderStateMixin {
  final ReportService _service = ReportService();
  late TabController _tabController;
  
  bool _isLoadingStock = true;
  bool _isLoadingMovements = true;
  String _errorMessage = '';
  
  // Data Stok Terkini
  List<CurrentStockItem> _currentStocks = [];
  int _totalProducts = 0;
  int _totalStockUnits = 0;
  int _lowStockCount = 0;
  int _outOfStockCount = 0;

  // Data Pergerakan
  List<StockMovementItem> _stockMovements = [];
  String _selectedFilter = '7 Hari';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Sinkronisasi tombol print dengan perubahan tab
    _tabController.addListener(() {
      setState(() {}); 
    });
    
    _fetchCurrentStock();
    _setFilterDate('7 Hari'); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // FETCH STOK TERKINI
  // ==========================================
  Future<void> _fetchCurrentStock() async {
    setState(() { _isLoadingStock = true; _errorMessage = ''; });
    try {
      final data = await _service.getStockReport();
      final List<CurrentStockItem> parsedData = (data as List).map((e) => CurrentStockItem.fromJson(e)).toList();
      
      int tempTotalUnits = 0;
      int tempLowStock = 0;
      int tempOutOfStock = 0;
      
      for (var p in parsedData) {
        tempTotalUnits += p.stock;
        if (p.isOutOfStock) {
          tempOutOfStock++;
        } else if (p.isLowStock) {
          tempLowStock++;
        }
      }

      setState(() {
        _currentStocks = parsedData;
        _totalProducts = parsedData.length;
        _totalStockUnits = tempTotalUnits;
        _lowStockCount = tempLowStock;
        _outOfStockCount = tempOutOfStock;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoadingStock = false);
    }
  }

  // ==========================================
  // FETCH PERGERAKAN STOK & FILTER
  // ==========================================
  void _setFilterDate(String filterType) {
    DateTime now = DateTime.now();
    // 1. Ubah state UI tombol yang aktif
    setState(() {
      _selectedFilter = filterType;
    });

    // 2. Jika Kustom, HANYA buka kalender lalu stop proses ini
    if (filterType == 'Kustom') {
      _pilihTanggalKustom();
      return; 
    }

    // 3. Jika bukan Kustom, set tanggal otomatis lalu jalankan fetch API
    setState(() {
      if (filterType == 'Hari Ini') {
        _dateFrom = now; 
        _dateTo = now;
      } else if (filterType == '7 Hari') {
        _dateFrom = now.subtract(const Duration(days: 6)); 
        _dateTo = now;
      } else if (filterType == 'Bulan Ini') {
        _dateFrom = DateTime(now.year, now.month, 1);
        _dateTo = DateTime(now.year, now.month + 1, 0);
      }
    });
    if (filterType != 'Kustom') _fetchStockMovements();
  }

  Future<void> _pilihTanggalKustom() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dateFrom, end: _dateTo),
      builder: (ctx, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryEmerald)), child: child!),
    );
    if (picked != null) {
      setState(() { _selectedFilter = 'Kustom'; _dateFrom = picked.start; _dateTo = picked.end; });
      _fetchStockMovements();
    }
  }

  Future<void> _fetchStockMovements() async {
    setState(() { _isLoadingMovements = true; _errorMessage = ''; });
    try {
      final strFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final strTo = DateFormat('yyyy-MM-dd').format(_dateTo);
      final data = await _service.getStockMovements(strFrom, strTo);
      
      final List<StockMovementItem> parsedMovements = (data as List).map((e) => StockMovementItem.fromJson(e)).toList();
      
      setState(() { _stockMovements = parsedMovements; });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoadingMovements = false);
    }
  }

  String _formatDateUI(String dateStr) {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.parse(dateStr));
    } catch (e) { return dateStr; }
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
  // CETAK LAPORAN STOK
  // ==========================================
  Future<void> _cetakLaporanStok() async {
    if (_tabController.index == 0 && _isLoadingStock) return;
    if (_tabController.index == 1 && _isLoadingMovements) return;

    _showNotif('Menyiapkan pencetakan...', AppColors.smartBlue);

    try {
      if (_tabController.index == 0) {
        // CETAK TAB 1: STOK TERKINI
        Map<String, dynamic> dataLaporan = {
          'periode': DateFormat('dd MMM yyyy').format(DateTime.now()),
          'Total_Produk': '$_totalProducts Varian',
          'Total_Unit_Tersedia': '$_totalStockUnits Unit',
          'Status_Stok_Menipis': '$_lowStockCount Produk',
          'Status_Stok_Habis': '$_outOfStockCount Produk',
          '-- RINCIAN STOK TERKINI --': '',
        };

        int batasCetak = _currentStocks.length > 30 ? 30 : _currentStocks.length;
        for (int i = 0; i < batasCetak; i++) {
          var p = _currentStocks[i];
          dataLaporan[p.productName] = '${p.stock} ${p.unit}';
        }
        await PrinterService().cetakLaporan(dataLaporan, "LAPORAN STOK GUDANG");
      } else {
        // CETAK TAB 2: RIWAYAT PERGERAKAN
        Map<String, dynamic> dataLaporan = {
          'periode': _selectedFilter,
          '-- RIWAYAT PERGERAKAN --': '',
        };

        int batasCetak = _stockMovements.length > 30 ? 30 : _stockMovements.length;
        for (int i = 0; i < batasCetak; i++) {
          var mv = _stockMovements[i];
          String prefix = mv.type == 'IN' ? '+' : mv.type == 'OUT' ? '-' : '';
          dataLaporan['${mv.productName} (${mv.type})'] = '$prefix${mv.quantity} Unit';
        }
        await PrinterService().cetakLaporan(dataLaporan, "LAPORAN PERGERAKAN STOK");
      }

      if (!mounted) return;
      _showNotif('Laporan berhasil dicetak!', AppColors.primaryEmerald);
    } catch (e) {
      if (!mounted) return;
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
  }

  // ==========================================
  // WIDGET BUILDER DENGAN CRYSTAL UI
  // ==========================================
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
        title: const Text('Persediaan Stok', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.smartBlue),
            tooltip: 'Cetak Laporan',
            onPressed: (_tabController.index == 0 && (_isLoadingStock || _currentStocks.isEmpty)) || 
                       (_tabController.index == 1 && (_isLoadingMovements || _stockMovements.isEmpty)) 
                ? null 
                : _cetakLaporanStok,
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
          tabs: const [Tab(text: 'Stok Terkini'), Tab(text: 'Riwayat Pergerakan')],
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

          _errorMessage.isNotEmpty
            ? _buildErrorState()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTabCurrentStock(),
                  _buildTabMovements(),
                ],
              ),
        ],
      ),
    );
  }

  // --- TAB 1: STOK TERKINI ---
  Widget _buildTabCurrentStock() {
    return _isLoadingStock
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : RefreshIndicator(
            color: AppColors.primaryEmerald,
            backgroundColor: Colors.white,
            onRefresh: _fetchCurrentStock,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 48 + 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(child: _buildMetricCard('Total Produk', '$_totalProducts', Icons.inventory_2_outlined, AppColors.smartBlue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricCard('Total Unit', '$_totalStockUnits', Icons.layers_outlined, Colors.purple.shade600)),
                      ],
                    ),
                  ),
                ),
                
                if (_lowStockCount > 0 || _outOfStockCount > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                      child: Row(
                        children: [
                          if (_lowStockCount > 0)
                            Expanded(child: _buildAlertCard('$_lowStockCount Menipis', Icons.warning_amber_rounded, Colors.orange.shade700)),
                          if (_lowStockCount > 0 && _outOfStockCount > 0) const SizedBox(width: 12),
                          if (_outOfStockCount > 0)
                            Expanded(child: _buildAlertCard('$_outOfStockCount Habis', Icons.error_outline_rounded, AppColors.error)),
                        ],
                      ),
                    ),
                  ),

                _currentStocks.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmptyState('Belum ada data stok produk'))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _currentStocks[index];
                            
                            Color statusColor = AppColors.primaryEmerald;
                            String statusText = 'Aman';
                            
                            if (item.isOutOfStock) {
                              statusColor = AppColors.error;
                              statusText = 'Habis';
                            } else if (item.isLowStock) {
                              statusColor = Colors.orange.shade700;
                              statusText = 'Menipis';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
                                      decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                                      child: Icon(Icons.inventory_2_outlined, color: statusColor, size: 24),
                                    ),
                                    title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.category_outlined, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(item.categoryName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${item.stock} ${item.unit}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: statusColor)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                          child: Text(statusText, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _currentStocks.length,
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          );
  }

  // --- TAB 2: RIWAYAT PERGERAKAN ---
  Widget _buildTabMovements() {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 48),

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
        
        Expanded(
          child: _isLoadingMovements
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _stockMovements.isEmpty
                  ? _buildEmptyState('Tidak ada pergerakan stok di periode ini')
                  : RefreshIndicator(
                      color: AppColors.primaryEmerald,
                      backgroundColor: Colors.white,
                      onRefresh: _fetchStockMovements,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 16, bottom: 40),
                        itemCount: _stockMovements.length,
                        itemBuilder: (context, index) {
                          final mv = _stockMovements[index];
                          
                          Color iconColor = AppColors.textSecondary;
                          IconData iconData = Icons.sync;
                          String prefix = '';
                          
                          if (mv.type == 'IN' || mv.type == 'RETURN') { 
                            iconColor = AppColors.primaryEmerald; iconData = Icons.arrow_downward_rounded; prefix = '+'; 
                          } else if (mv.type == 'OUT') { 
                            iconColor = AppColors.error; iconData = Icons.arrow_upward_rounded; prefix = '-'; 
                          } else if (mv.type == 'ADJUSTMENT') { 
                            iconColor = AppColors.smartBlue; iconData = Icons.tune_rounded; 
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                                        child: Icon(iconData, color: iconColor, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(mv.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyActive)),
                                            const SizedBox(height: 4),
                                            Text('${mv.referenceType} • Oleh: ${mv.userName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                            const SizedBox(height: 2),
                                            Text(_formatDateUI(mv.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('$prefix${mv.quantity}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: iconColor)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: AppColors.lightGray.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                                            child: Text('${mv.stockBefore} ➔ ${mv.stockAfter}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // --- WIDGET BANTUAN ---
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.navyActive)),
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(Icons.assignment_outlined, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
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
              onPressed: _tabController.index == 0 ? _fetchCurrentStock : _fetchStockMovements, 
              icon: const Icon(Icons.refresh, color: Colors.white),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
              label: const Text('Muat Ulang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }
}
