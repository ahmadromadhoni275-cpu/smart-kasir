import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
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
  List<dynamic> _currentStocks = [];
  int _totalProducts = 0;
  int _totalStockUnits = 0;
  int _lowStockCount = 0;

  // Data Pergerakan
  List<dynamic> _stockMovements = [];
  String _selectedFilter = '7 Hari';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch Stok Terkini saat pertama kali buka
    _fetchCurrentStock();
    
    // Set Tanggal default untuk Riwayat
    _setFilterDate('7 Hari'); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // LOGIKA FETCH STOK TERKINI
  // ==========================================
  Future<void> _fetchCurrentStock() async {
    setState(() { _isLoadingStock = true; _errorMessage = ''; });
    try {
      final data = await _service.getStockReport();
      
      int tempTotalUnits = 0;
      int tempLowStock = 0;
      
      for (var p in data) {
        int stock = int.tryParse(p['stock']?.toString() ?? '0') ?? 0;
        int minStock = int.tryParse(p['min_stock']?.toString() ?? '0') ?? 0;
        
        tempTotalUnits += stock;
        if (stock <= minStock) tempLowStock++;
      }

      setState(() {
        _currentStocks = data;
        _totalProducts = data.length;
        _totalStockUnits = tempTotalUnits;
        _lowStockCount = tempLowStock;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoadingStock = false);
    }
  }

  // ==========================================
  // LOGIKA FETCH PERGERAKAN STOK & FILTER
  // ==========================================
  void _setFilterDate(String filterType) {
    DateTime now = DateTime.now();
    setState(() {
      _selectedFilter = filterType;
      if (filterType == 'Hari Ini') {
        _dateFrom = now; _dateTo = now;
      } else if (filterType == '7 Hari') {
        _dateFrom = now.subtract(const Duration(days: 6)); _dateTo = now;
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
      setState(() { _stockMovements = data; });
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

  // ==========================================
  // BUILDER UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Stok & Persediaan', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryEmerald,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryEmerald,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [Tab(text: 'Stok Terkini'), Tab(text: 'Riwayat Pergerakan')],
        ),
      ),
      body: _errorMessage.isNotEmpty
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabCurrentStock(),
                _buildTabMovements(),
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
            onRefresh: _fetchCurrentStock,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(child: _buildMetricCard('Total Produk', '$_totalProducts', Icons.inventory_2, Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricCard('Total Unit', '$_totalStockUnits', Icons.layers, Colors.purple)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricCard('Stok Menipis', '$_lowStockCount', Icons.warning_amber_rounded, Colors.orange)),
                      ],
                    ),
                  ),
                ),
                if (_lowStockCount > 0)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Ada $_lowStockCount produk yang mencapai batas minimum stok. Segera restok!', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12))),
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
                            int stock = int.tryParse(item['stock']?.toString() ?? '0') ?? 0;
                            int minStock = int.tryParse(item['min_stock']?.toString() ?? '0') ?? 0;
                            bool isLow = stock <= minStock;

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isLow ? Colors.orange.shade300 : Colors.grey.shade200)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: (isLow ? Colors.orange : AppColors.primaryEmerald).withOpacity(0.1),
                                  child: Icon(Icons.inventory, color: isLow ? Colors.orange : AppColors.primaryEmerald, size: 20),
                                ),
                                title: Text(item['product_name'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('${item['sku'] ?? '-'} • ${item['category_name'] ?? 'Umum'}', style: const TextStyle(fontSize: 12)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$stock ${item['unit'] ?? 'Pcs'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isLow ? Colors.orange.shade700 : AppColors.navyActive)),
                                    if (isLow) Text('Min: $minStock', style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
                                  ],
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
        // Panel Filter (Khusus Tab Riwayat)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
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
                    onSelected: (val) { if (val) filter == 'Kustom' ? _pilihTanggalKustom() : _setFilterDate(filter); },
                  ),
                );
              }).toList(),
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
                      onRefresh: _fetchStockMovements,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 40),
                        itemCount: _stockMovements.length,
                        itemBuilder: (context, index) {
                          final mv = _stockMovements[index];
                          String type = mv['type']?.toString().toUpperCase() ?? 'ADJUSTMENT';
                          String ref = mv['reference_type']?.toString().replaceAll('_', ' ') ?? '-';
                          int qty = int.tryParse(mv['quantity']?.toString() ?? '0') ?? 0;
                          
                          // Styling berdasarkan Type (IN, OUT, ADJUSTMENT)
                          Color iconColor = Colors.grey;
                          IconData iconData = Icons.sync;
                          String prefix = '';
                          
                          if (type == 'IN') { iconColor = Colors.green; iconData = Icons.arrow_downward; prefix = '+'; } 
                          else if (type == 'OUT') { iconColor = Colors.red; iconData = Icons.arrow_upward; prefix = '-'; } 
                          else if (type == 'ADJUSTMENT') { iconColor = Colors.blue; iconData = Icons.tune; }

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: iconColor.withOpacity(0.1),
                                    child: Icon(iconData, color: iconColor, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(mv['product_name'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyActive)),
                                        const SizedBox(height: 4),
                                        Text('$ref • Oleh: ${mv['user_name'] ?? 'Sistem'}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        Text(_formatDateUI(mv['created_at']), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('$prefix$qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: iconColor)),
                                      const SizedBox(height: 4),
                                      Text('${mv['stock_before']} ➔ ${mv['stock_after']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navyActive)),
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade300),
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
          ElevatedButton(onPressed: _fetchCurrentStock, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald), child: const Text('Muat Ulang', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }
}
