import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
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

  List<dynamic> _shifts = [];
  
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
      
      int tempCount = data.length;
      double tempOpening = 0;
      double tempSales = 0;
      double tempActual = 0;
      double tempDiff = 0;
      
      for (var s in data) {
        String status = s['status']?.toString().toUpperCase() ?? 'OPEN';
        
        // Parsing nominal uang
        double opening = double.tryParse(s['opening_cash']?.toString() ?? '0') ?? 0;
        double sales = double.tryParse(s['cash_sales']?.toString() ?? '0') ?? 0;
        double cashIn = double.tryParse(s['cash_in']?.toString() ?? '0') ?? 0;
        double cashOut = double.tryParse(s['cash_out']?.toString() ?? '0') ?? 0;
        double withdraw = double.tryParse(s['withdrawal']?.toString() ?? '0') ?? 0;
        double actual = double.tryParse(s['actual_cash']?.toString() ?? '0') ?? 0;
        
        // RUMUS: Kas Diharapkan = Modal Awal + Penjualan Tunai + Kas Masuk - Kas Keluar - Penarikan
        double expected = double.tryParse(s['expected_cash']?.toString() ?? '0') ?? 0;
        if (s['expected_cash'] == null) {
          expected = opening + sales + cashIn - cashOut - withdraw;
        }

        // RUMUS: Selisih = Kas Aktual - Kas Diharapkan (Hanya dihitung jika shift sudah CLOSED)
        double diff = double.tryParse(s['difference']?.toString() ?? '0') ?? 0;
        if (s['difference'] == null && status == 'CLOSED') {
          diff = actual - expected;
        }

        tempOpening += opening;
        tempSales += sales;
        if (status == 'CLOSED') {
          tempActual += actual;
          tempDiff += diff;
        }
      }

      setState(() {
        _shifts = data;
        _totalShifts = tempCount;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Shift', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : RefreshIndicator(
                  color: AppColors.primaryEmerald,
                  onRefresh: _fetchShifts,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildFilterPanel()),
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
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
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
              Expanded(child: _buildMetricBox('Total Shift', '$_totalShifts', Icons.lock_clock, Colors.indigo)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricBox('Total Pemasukan Tunai', _formatCurrency(_totalCashSales), Icons.payments, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isSelisihMinus ? [Colors.red.shade700, Colors.red.shade500] : [AppColors.primaryEmerald, const Color(0xFF107A4D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: (isSelisihMinus ? Colors.red : AppColors.primaryEmerald).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Selisih Kas', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(_formatCurrency(_totalDifference), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Icon(isSelisihMinus ? Icons.trending_down : Icons.trending_up, color: Colors.white, size: 28),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyActive)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildShiftItem(dynamic s) {
    String kasir = s['user_name']?.toString() ?? 'Kasir';
    String status = s['status']?.toString().toUpperCase() ?? 'OPEN';
    bool isClosed = status == 'CLOSED';

    double opening = double.tryParse(s['opening_cash']?.toString() ?? '0') ?? 0;
    double sales = double.tryParse(s['cash_sales']?.toString() ?? '0') ?? 0;
    double cashIn = double.tryParse(s['cash_in']?.toString() ?? '0') ?? 0;
    double cashOut = double.tryParse(s['cash_out']?.toString() ?? '0') ?? 0;
    double withdraw = double.tryParse(s['withdrawal']?.toString() ?? '0') ?? 0;
    double actual = double.tryParse(s['actual_cash']?.toString() ?? '0') ?? 0;

    double expected = double.tryParse(s['expected_cash']?.toString() ?? '0') ?? 0;
    if (s['expected_cash'] == null) expected = opening + sales + cashIn - cashOut - withdraw;

    double diff = double.tryParse(s['difference']?.toString() ?? '0') ?? 0;
    if (s['difference'] == null && isClosed) diff = actual - expected;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
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
                    CircleAvatar(backgroundColor: AppColors.lightGray, radius: 16, child: const Icon(Icons.person, size: 16, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Text(kasir, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isClosed ? Colors.grey.shade200 : Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(isClosed ? 'DITUTUP' : 'BERJALAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isClosed ? Colors.grey.shade700 : Colors.green.shade700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTimeRow('Buka', _formatDateUI(s['opened_at']?.toString() ?? ''))),
                Expanded(child: _buildTimeRow('Tutup', isClosed ? _formatDateUI(s['closed_at']?.toString() ?? '') : 'Belum Ditutup')),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            _buildDetailRow('Modal Awal', _formatCurrency(opening)),
            _buildDetailRow('Pemasukan Tunai', '+ ${_formatCurrency(sales)}'),
            if (cashIn > 0) _buildDetailRow('Kas Masuk Lainnya', '+ ${_formatCurrency(cashIn)}'),
            if (cashOut > 0) _buildDetailRow('Kas Keluar', '- ${_formatCurrency(cashOut)}', color: Colors.red),
            if (withdraw > 0) _buildDetailRow('Penarikan', '- ${_formatCurrency(withdraw)}', color: Colors.red),
            
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  _buildDetailRow('Kas yang Diharapkan (Sistem)', _formatCurrency(expected), isBold: true),
                  if (isClosed) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Kas Aktual (Dihitung Kasir)', _formatCurrency(actual), isBold: true),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Selisih', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          _formatCurrency(diff),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: diff < 0 ? Colors.red : (diff > 0 ? Colors.green : AppColors.navyActive)),
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
    );
  }

  Widget _buildTimeRow(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyActive)),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isBold ? AppColors.navyActive : AppColors.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, color: color ?? (isBold ? AppColors.navyActive : AppColors.textPrimary), fontWeight: isBold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.lock_clock, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Belum ada riwayat shift di periode ini', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
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
          ElevatedButton(onPressed: _fetchShifts, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald), child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }
}
