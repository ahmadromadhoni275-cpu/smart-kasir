import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'tema.dart';

class HalamanLaporanPembayaran extends StatefulWidget {
  const HalamanLaporanPembayaran({super.key});

  @override
  State<HalamanLaporanPembayaran> createState() => _HalamanLaporanPembayaranState();
}

class _HalamanLaporanPembayaranState extends State<HalamanLaporanPembayaran> {
  final ReportService _service = ReportService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'Hari Ini';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  List<dynamic> _payments = [];
  
  // Variabel Rekap
  double _totalAmount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _setFilterDate('Hari Ini');
  }

  // ==========================================
  // LOGIKA FILTER TANGGAL
  // ==========================================
  void _setFilterDate(String filterType) {
    DateTime now = DateTime.now();
    setState(() {
      _selectedFilter = filterType;
      if (filterType == 'Hari Ini') {
        _dateFrom = now;
        _dateTo = now;
        _fetchPayments();
      } else if (filterType == '7 Hari') {
        _dateFrom = now.subtract(const Duration(days: 6));
        _dateTo = now;
        _fetchPayments();
      } else if (filterType == 'Bulan Ini') {
        _dateFrom = DateTime(now.year, now.month, 1);
        _dateTo = DateTime(now.year, now.month + 1, 0);
        _fetchPayments();
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryEmerald)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
      _fetchPayments();
    } else {
      setState(() => _selectedFilter = 'Hari Ini');
      _setFilterDate('Hari Ini');
    }
  }

  // ==========================================
  // FETCH DATA API
  // ==========================================
  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final String strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      final data = await _service.getPayments(strDateFrom, strDateTo);
      
      double tempNominal = 0;
      int tempCount = 0;
      
      for (var pay in data) {
        tempNominal += double.tryParse(pay['total_amount']?.toString() ?? '0') ?? 0.0;
        tempCount += int.tryParse(pay['payment_count']?.toString() ?? '0') ?? 0;
      }

      setState(() {
        _payments = data;
        _totalAmount = tempNominal;
        _totalCount = tempCount;
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

  // Mengambil Ikon dan Warna berdasarkan Grup Pembayaran
  Map<String, dynamic> _getPaymentStyle(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return {'icon': Icons.money, 'color': Colors.green};
      case 'QRIS':
        return {'icon': Icons.qr_code_2, 'color': Colors.blue};
      case 'TRANSFER':
        return {'icon': Icons.account_balance, 'color': Colors.orange};
      case 'EWALLET':
        return {'icon': Icons.account_balance_wallet, 'color': Colors.purple};
      default:
        return {'icon': Icons.payment, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Pembayaran', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
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
                  onRefresh: _fetchPayments,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildFilterPanel()),
                      SliverToBoxAdapter(child: _buildSummaryCards()),
                      
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
                          child: const Text('Rincian Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                        ),
                      ),
                      
                      _payments.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyState())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildPaymentItem(_payments[index]),
                                childCount: _payments.length,
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
                onSelected: (val) {
                  if (val) _setFilterDate(filter);
                },
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
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade600, // Warna berbeda dari penjualan agar fresh
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pembayaran', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(_formatCurrency(_totalAmount), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Jumlah (x)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$_totalCount', style: const TextStyle(color: AppColors.navyActive, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(dynamic pay) {
    String method = pay['payment_group']?.toString() ?? 'LAINNYA';
    double total = double.tryParse(pay['total_amount']?.toString() ?? '0') ?? 0.0;
    int count = int.tryParse(pay['payment_count']?.toString() ?? '0') ?? 0;
    
    // Hitung persentase
    double percentage = _totalAmount > 0 ? (total / _totalAmount) : 0;
    String strPercentage = (percentage * 100).toStringAsFixed(1);
    
    final style = _getPaymentStyle(method);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: style['color'].withOpacity(0.1),
                  child: Icon(style['icon'], color: style['color'], size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                      const SizedBox(height: 4),
                      Text('$count Transaksi', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryEmerald)),
                    const SizedBox(height: 4),
                    Text('$strPercentage%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: style['color'])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar Visualisasi Persentase
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade200,
                color: style['color'],
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.payment, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Belum ada pembayaran sukses di periode ini', style: TextStyle(color: AppColors.textSecondary)),
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
            Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPayments,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
