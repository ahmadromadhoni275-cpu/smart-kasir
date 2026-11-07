import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart';
import 'models/return_report_model.dart';
import 'tema.dart';

class HalamanLaporanRetur extends StatefulWidget {
  const HalamanLaporanRetur({super.key});

  @override
  State<HalamanLaporanRetur> createState() => _HalamanLaporanReturState();
}

class _HalamanLaporanReturState extends State<HalamanLaporanRetur> {
  final ReportService _service = ReportService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'Bulan Ini'; 
  late DateTime _dateFrom;
  late DateTime _dateTo;

  List<ReturnReportItem> _returns = [];
  
  // Variabel Rekap
  int _totalTransactions = 0;
  int _totalUnits = 0;
  double _totalReturnValue = 0;
  double _totalRefunded = 0;

  @override
  void initState() {
    super.initState();
    _setFilterDate('Bulan Ini');
  }

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
    if (filterType != 'Kustom') _fetchReturns();
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
      _fetchReturns();
    } else {
      setState(() => _selectedFilter = 'Bulan Ini');
      _setFilterDate('Bulan Ini');
    }
  }

  Future<void> _fetchReturns() async {
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      // ReportService mengembalikan List<ReturnReportItem> jika menggunakan mapping class
      // Jika masih mengembalikan dynamic/map, konversi di sini
      final data = await _service.getReturns(strDateFrom, strDateTo);
      
      final List<ReturnReportItem> parsedData = (data as List).map((e) {
        if (e is ReturnReportItem) return e;
        return ReturnReportItem.fromJson(e);
      }).toList();
      
      int tempUnits = 0;
      double tempValue = 0;
      double tempRefund = 0;
      
      for (var r in parsedData) {
        tempUnits += r.totalQuantity;
        tempValue += r.returnTotal;
        
        // Asumsi jika status COMPLETED, refund sudah dikembalikan
        if (r.returnStatus == 'COMPLETED') {
           tempRefund += r.refundedAmount;
        }
      }

      setState(() {
        _returns = parsedData;
        _totalTransactions = parsedData.length;
        _totalUnits = tempUnits;
        _totalReturnValue = tempValue;
        _totalRefunded = tempRefund;
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

  String _formatDateUI(String dateStr) {
    try {
      if (dateStr.isEmpty || dateStr == 'null') return '-';
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.parse(dateStr));
    } catch (e) { return dateStr; }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
      case 'SELESAI':
      case 'APPROVED':
        return AppColors.primaryEmerald;
      case 'PENDING':
      case 'MENUNGGU':
        return Colors.orange.shade700;
      case 'REJECTED':
      case 'DITOLAK':
      case 'CANCELED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
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
  // CETAK LAPORAN RETUR
  // ==========================================
  Future<void> _cetakLaporanRetur() async {
    if (_isLoading || _returns.isEmpty) return;

    _showNotif('Menyiapkan pencetakan...', AppColors.smartBlue);

    Map<String, dynamic> dataLaporan = {
      'periode': _selectedFilter,
      'Total_Transaksi_Retur': '$_totalTransactions Transaksi',
      'Total_Unit_Retur': '$_totalUnits Unit',
      'Nilai_Barang_Retur': _totalReturnValue,
      'Total_Dana_Refund': _totalRefunded,
      '-- RINCIAN RETUR TERAKHIR --': '',
    };

    int batasCetak = _returns.length > 15 ? 15 : _returns.length;
    for (int i = 0; i < batasCetak; i++) {
      var r = _returns[i];
      dataLaporan['${r.returnNumber} (${r.returnStatus})'] = r.refundedAmount;
    }

    try {
      await PrinterService().cetakLaporan(dataLaporan, "LAPORAN RETUR PENJUALAN");
      if (!mounted) return;
      _showNotif('Laporan Retur berhasil dicetak!', AppColors.primaryEmerald);
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
        title: const Text('Laporan Retur', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.smartBlue),
            tooltip: 'Cetak Laporan',
            onPressed: _isLoading || _returns.isEmpty ? null : _cetakLaporanRetur,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient (Crystal UI)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd],
              ),
            ),
          ),

          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : RefreshIndicator(
                    color: AppColors.primaryEmerald,
                    backgroundColor: Colors.white,
                    onRefresh: _fetchReturns,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight)),
                        
                        // Filter Panel Glass
                        SliverToBoxAdapter(
                          child: ClipRRect(
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
                        ),

                        SliverToBoxAdapter(child: _buildSummaryCards()),
                        
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
                            child: Text('Daftar Transaksi Retur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                          ),
                        ),
                        
                        _returns.isEmpty
                            ? SliverToBoxAdapter(child: _buildEmptyState())
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildReturnItem(_returns[index]),
                                  childCount: _returns.length,
                                ),
                              ),
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricBox('Total Retur', '$_totalTransactions', Icons.assignment_return_outlined, AppColors.smartBlue)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricBox('Total Unit', '$_totalUnits', Icons.inventory_2_outlined, Colors.orange.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red.shade700, Colors.red.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Refund & Nilai Barang', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    Icon(Icons.currency_exchange_outlined, color: Colors.white.withOpacity(0.7), size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Refund', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(_formatCurrency(_totalRefunded), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nilai Barang', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(_formatCurrency(_totalReturnValue), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricBox(String title, String value, IconData icon, Color color) {
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
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.navyActive)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReturnItem(ReturnReportItem r) {
    Color statusColor = _getStatusColor(r.returnStatus);

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.assignment_return_outlined, size: 16, color: Colors.red),
                        ),
                        const SizedBox(width: 10),
                        Text(r.returnNumber, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navyActive, fontSize: 14)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(r.returnStatus, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildDetailRow('Asal Invoice', r.invoiceNumber, Icons.receipt_long_outlined)),
                    Expanded(child: _buildDetailRow('Tgl Retur', _formatDateUI(r.createdAt), Icons.access_time)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.border)),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kasir: ${r.userName}\nAlasan: ${r.reason}', 
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic, height: 1.4)
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6), 
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nilai Barang (${r.totalQuantity} unit)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_formatCurrency(r.returnTotal), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.navyActive)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Dana Dikembalikan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_formatCurrency(r.refundedAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
              child: Icon(Icons.assignment_return_outlined, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada retur di periode ini', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
          ],
        ),
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
              onPressed: _fetchReturns, 
              icon: const Icon(Icons.refresh, color: Colors.white),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
              label: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            )
          ],
        ),
      ),
    );
  }
}
