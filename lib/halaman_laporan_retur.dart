import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
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
  
  String _selectedFilter = 'Bulan Ini'; // Retur biasanya direkap bulanan
  late DateTime _dateFrom;
  late DateTime _dateTo;

  List<dynamic> _returns = [];
  
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

      final data = await _service.getReturns(strDateFrom, strDateTo);
      
      int tempUnits = 0;
      double tempValue = 0;
      double tempRefund = 0;
      
      for (var r in data) {
        tempUnits += int.tryParse(r['total_quantity']?.toString() ?? '0') ?? 0;
        tempValue += double.tryParse(r['return_total']?.toString() ?? '0') ?? 0;
        tempRefund += double.tryParse(r['refunded_amount']?.toString() ?? '0') ?? 0;
      }

      setState(() {
        _returns = data;
        _totalTransactions = data.length;
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
        return Colors.green;
      case 'PENDING':
      case 'MENUNGGU':
        return Colors.orange;
      case 'REJECTED':
      case 'DITOLAK':
      case 'CANCELED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Retur', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
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
                  onRefresh: _fetchReturns,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildFilterPanel()),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMetricBox('Total Retur', '$_totalTransactionsx', Icons.assignment_return, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricBox('Total Unit', '$_totalUnits', Icons.inventory, Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricBox('Nilai Barang Diretur', _formatCurrency(_totalReturnValue), Icons.shopping_cart_checkout, Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red.shade600, Colors.red.shade400], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Dana Dikembalikan (Refund)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Text(_formatCurrency(_totalRefunded), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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

  Widget _buildReturnItem(dynamic r) {
    String retNum = r['return_number']?.toString() ?? 'RET-???';
    String invNum = r['invoice_number']?.toString() ?? '-';
    String kasir = r['user_name']?.toString() ?? 'Kasir';
    String status = r['return_status']?.toString().toUpperCase() ?? 'PENDING';
    String reason = r['reason']?.toString() ?? 'Tidak ada keterangan';
    
    int qty = int.tryParse(r['total_quantity']?.toString() ?? '0') ?? 0;
    double retValue = double.tryParse(r['return_total']?.toString() ?? '0') ?? 0;
    double refund = double.tryParse(r['refunded_amount']?.toString() ?? '0') ?? 0;

    Color statusColor = _getStatusColor(status);

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
                    const Icon(Icons.assignment_return, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(retNum, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDetailRow('Asal Invoice', invNum)),
                Expanded(child: _buildDetailRow('Tgl Retur', _formatDateUI(r['created_at']))),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            Text('Oleh: $kasir • Alasan: $reason', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nilai Barang ($qty unit)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(_formatCurrency(retValue), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Dana Dikembalikan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(_formatCurrency(refund), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyActive)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_turned_in, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Belum ada retur di periode ini', style: TextStyle(color: AppColors.textSecondary)),
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
          ElevatedButton(onPressed: _fetchReturns, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald), child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }
}
