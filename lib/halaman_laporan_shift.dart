import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart';
import 'models/shift_report_model.dart';
import 'tema.dart';

class HalamanLaporanShift extends StatefulWidget {
  const HalamanLaporanShift({super.key});

  @override
  State<HalamanLaporanShift> createState() => _HalamanLaporanShiftState();
}

class _HalamanLaporanShiftState extends State<HalamanLaporanShift> {
  final ReportService _service = ReportService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'Hari Ini';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  List<ShiftReportItem> _shifts = [];
  
  // Variabel Ringkasan Kas (Rekapitulasi)
  int _totalShifts = 0;
  double _totalOpeningCash = 0;
  double _totalCashSales = 0;
  double _totalActualCash = 0;
  double _totalDifference = 0;

  @override
  void initState() {
    super.initState();
    _setFilterDate('Hari Ini');
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
    if (filterType != 'Kustom') _fetchShifts();
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
      _fetchShifts();
    } else {
      setState(() => _selectedFilter = 'Hari Ini');
      _setFilterDate('Hari Ini');
    }
  }

  Future<void> _fetchShifts() async {
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      final data = await _service.getShifts(strDateFrom, strDateTo);
      final List<ShiftReportItem> parsedData = (data as List).map((e) => ShiftReportItem.fromJson(e)).toList();
      
      double tempOpening = 0;
      double tempSales = 0;
      double tempActual = 0;
      double tempDiff = 0;
      
      for (var s in parsedData) {
        tempOpening += s.openingCash;
        tempSales += s.cashSales;
        if (s.isClosed) {
          tempActual += s.actualCash;
          tempDiff += s.difference;
        }
      }

      setState(() {
        _shifts = parsedData;
        _totalShifts = parsedData.length;
        _totalOpeningCash = tempOpening;
        _totalCashSales = tempSales;
        _totalActualCash = tempActual;
        _totalDifference = tempDiff;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return amount < 0 ? "-${format.format(amount.abs())}" : format.format(amount);
  }

  String _formatDateUI(String dateStr) {
    try {
      if (dateStr.isEmpty || dateStr == 'null') return '-';
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(dateStr));
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
  // CETAK LAPORAN REKAP SHIFT
  // ==========================================
  Future<void> _cetakLaporanShift() async {
    if (_isLoading || _shifts.isEmpty) return;

    _showNotif('Menyiapkan pencetakan...', AppColors.smartBlue);

    Map<String, dynamic> dataLaporan = {
      'periode': _selectedFilter,
      'Total_Shift': '$_totalShifts Shift',
      'Total_Pemasukan_Tunai': _totalCashSales,
      'Total_Selisih_Kas': _totalDifference < 0 ? -(_totalDifference) : _totalDifference, 
      '-- RINCIAN SHIFT TERAKHIR --': '',
    };

    int batasCetak = _shifts.length > 15 ? 15 : _shifts.length;
    for (int i = 0; i < batasCetak; i++) {
      var s = _shifts[i];
      
      String tgl = '-';
      if (s.openedAt.isNotEmpty) {
        try {
          tgl = DateFormat('dd MMM').format(DateTime.parse(s.openedAt));
        } catch (_) {}
      }

      if (s.isClosed) {
        dataLaporan['${s.userName} ($tgl)'] = s.difference < 0 ? -(s.difference) : s.difference;
      } else {
        dataLaporan['${s.userName} ($tgl)'] = 'MASIH BERJALAN';
      }
    }

    try {
      await PrinterService().cetakLaporan(dataLaporan, "REKAP LAPORAN SHIFT");
      if (!mounted) return;
      _showNotif('Laporan Shift berhasil dicetak!', AppColors.primaryEmerald);
    } catch (e) {
      if (!mounted) return;
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
  }

  // ==========================================
  // WIDGET BUILDER
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
        title: const Text('Laporan Shift', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.smartBlue),
            tooltip: 'Cetak Laporan',
            onPressed: _isLoading || _shifts.isEmpty ? null : _cetakLaporanShift,
          ),
          const SizedBox(width: 8),
        ],
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

          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : RefreshIndicator(
                    color: AppColors.primaryEmerald,
                    backgroundColor: Colors.white,
                    onRefresh: _fetchShifts,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight)),
                        
                        // Filter Panel
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
                            child: Text('Rincian Shift Kasir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                          ),
                        ),
                        
                        _shifts.isEmpty
                            ? SliverToBoxAdapter(child: _buildEmptyState())
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildShiftItem(_shifts[index]),
                                  childCount: _shifts.length,
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
    bool isSelisihMinus = _totalDifference < 0;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricBox('Total Shift', '$_totalShifts', Icons.lock_clock_outlined, Colors.indigo.shade600)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricBox('Pemasukan Tunai', _formatCurrency(_totalCashSales), Icons.payments_outlined, AppColors.smartBlue)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelisihMinus ? [Colors.red.shade700, Colors.red.shade400] : [AppColors.primaryEmerald, const Color(0xFF107A4D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: (isSelisihMinus ? Colors.red : AppColors.primaryEmerald).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Selisih Kas', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_formatCurrency(_totalDifference), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: Icon(isSelisihMinus ? Icons.trending_down_rounded : Icons.trending_up_rounded, color: Colors.white, size: 32),
                )
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
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.navyActive)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftItem(ShiftReportItem s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
                        CircleAvatar(backgroundColor: AppColors.smartBlue.withOpacity(0.15), radius: 18, child: const Icon(Icons.person_outline, size: 20, color: AppColors.smartBlue)),
                        const SizedBox(width: 10),
                        Text(s.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 15)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: s.isClosed ? Colors.grey.shade200 : AppColors.primaryEmerald.withOpacity(0.15), 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        s.isClosed ? 'DITUTUP' : 'BERJALAN', 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: s.isClosed ? Colors.grey.shade700 : AppColors.primaryEmerald)
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTimeRow('Waktu Buka', _formatDateUI(s.openedAt), Icons.play_circle_outline)),
                    Expanded(child: _buildTimeRow('Waktu Tutup', s.isClosed ? _formatDateUI(s.closedAt) : '-', Icons.stop_circle_outlined)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: AppColors.border)),
                
                _buildDetailRow('Modal Awal', _formatCurrency(s.openingCash)),
                _buildDetailRow('Pemasukan Tunai', '+ ${_formatCurrency(s.cashSales)}', color: AppColors.primaryEmerald),
                if (s.cashIn > 0) _buildDetailRow('Kas Masuk Lainnya', '+ ${_formatCurrency(s.cashIn)}', color: AppColors.primaryEmerald),
                if (s.cashOut > 0) _buildDetailRow('Kas Keluar', '- ${_formatCurrency(s.cashOut)}', color: AppColors.error),
                if (s.withdrawal > 0) _buildDetailRow('Penarikan', '- ${_formatCurrency(s.withdrawal)}', color: AppColors.error),
                
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6), 
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white)
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Kas Diharapkan (Sistem)', _formatCurrency(s.expectedCash), isBold: true),
                      if (s.isClosed) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow('Kas Aktual (Dihitung Kasir)', _formatCurrency(s.actualCash), isBold: true),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, color: Colors.grey.shade300)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Selisih', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                            Text(
                              _formatCurrency(s.difference),
                              style: TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 18, 
                                color: s.difference < 0 ? AppColors.error : (s.difference > 0 ? AppColors.primaryEmerald : AppColors.navyActive)
                              ),
                            ),
                          ],
                        ),
                      ]
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

  Widget _buildTimeRow(String label, String time, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isBold ? AppColors.navyActive : AppColors.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, color: color ?? (isBold ? AppColors.navyActive : AppColors.textPrimary), fontWeight: isBold ? FontWeight.w900 : FontWeight.bold)),
        ],
      ),
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
              child: Icon(Icons.lock_clock_outlined, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada riwayat shift di periode ini', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
              onPressed: _fetchShifts, 
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
