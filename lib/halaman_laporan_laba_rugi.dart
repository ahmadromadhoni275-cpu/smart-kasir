import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'tema.dart';

class HalamanLaporanLabaRugi extends StatefulWidget {
  const HalamanLaporanLabaRugi({super.key});

  @override
  State<HalamanLaporanLabaRugi> createState() => _HalamanLaporanLabaRugiState();
}

class _HalamanLaporanLabaRugiState extends State<HalamanLaporanLabaRugi> {
  final ReportService _service = ReportService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'Bulan Ini';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  // Variabel Keuangan
  double _grossSales = 0;
  double _totalDiscount = 0;
  double _totalReturns = 0;
  double _netSales = 0;
  double _totalCogs = 0;
  double _grossProfit = 0;
  double _totalExpenses = 0;
  double _netProfit = 0;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _setFilterDate('Bulan Ini'); // Default ke bulan ini (lebih relevan untuk laba rugi)
  }

  void _setFilterDate(String filterType) {
    DateTime now = DateTime.now();
    setState(() {
      _selectedFilter = filterType;
      if (filterType == 'Hari Ini') {
        _dateFrom = now;
        _dateTo = now;
      } else if (filterType == '7 Hari') {
        _dateFrom = now.subtract(const Duration(days: 6));
        _dateTo = now;
      } else if (filterType == 'Bulan Ini') {
        _dateFrom = DateTime(now.year, now.month, 1);
        _dateTo = DateTime(now.year, now.month + 1, 0);
      } else if (filterType == 'Kustom') {
        _pilihTanggalKustom();
        return; // Jangan fetch dulu sebelum modal selesai
      }
    });
    _fetchProfitLoss();
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
      _fetchProfitLoss();
    } else {
      setState(() => _selectedFilter = 'Bulan Ini');
      _setFilterDate('Bulan Ini');
    }
  }

  Future<void> _fetchProfitLoss() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final String strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      final data = await _service.getProfitLoss(strDateFrom, strDateTo);
      
      setState(() {
        _grossSales = double.tryParse(data['gross_sales']?.toString() ?? '0') ?? 0;
        _totalDiscount = double.tryParse(data['total_discount']?.toString() ?? '0') ?? 0;
        _totalReturns = double.tryParse(data['total_returns']?.toString() ?? '0') ?? 0;
        _netSales = double.tryParse(data['net_sales']?.toString() ?? '0') ?? 0;
        _totalCogs = double.tryParse(data['total_cogs']?.toString() ?? '0') ?? 0;
        _grossProfit = double.tryParse(data['gross_profit']?.toString() ?? '0') ?? 0;
        _totalExpenses = double.tryParse(data['total_expenses']?.toString() ?? '0') ?? 0;
        _netProfit = double.tryParse(data['net_profit']?.toString() ?? '0') ?? 0;
        _transactionCount = int.tryParse(data['transaction_count']?.toString() ?? '0') ?? 0;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    // Format agar bisa minus (contoh: -Rp50.000)
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return amount < 0 ? "-${format.format(amount.abs())}" : format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laba & Rugi (P&L)', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Column(
        children: [
          // 1. FILTER TANGGAL
          Container(
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
          ),
          
          // 2. KONTEN LAPORAN
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                : _errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : RefreshIndicator(
                        color: AppColors.primaryEmerald,
                        onRefresh: _fetchProfitLoss,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // KARTU LABA BERSIH
                            _buildNetProfitCard(),
                            const SizedBox(height: 24),

                            // DOKUMEN LABA RUGI
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('PENDAPATAN (REVENUE)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, letterSpacing: 1)),
                                  const SizedBox(height: 12),
                                  _buildFinanceRow('Penjualan Kotor', _grossSales),
                                  _buildFinanceRow('Diskon Penjualan', _totalDiscount, isMinus: true),
                                  _buildFinanceRow('Retur Penjualan', _totalReturns, isMinus: true),
                                  const Divider(height: 24, thickness: 1),
                                  _buildFinanceRow('Penjualan Bersih (Net Sales)', _netSales, isBold: true),
                                  
                                  const SizedBox(height: 32),
                                  const Text('HARGA POKOK (COGS)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, letterSpacing: 1)),
                                  const SizedBox(height: 12),
                                  _buildFinanceRow('Harga Pokok Penjualan', _totalCogs, isMinus: true),
                                  const Divider(height: 24, thickness: 1),
                                  _buildFinanceRow('Laba Kotor (Gross Profit)', _grossProfit, isBold: true, color: AppColors.smartBlue),

                                  const SizedBox(height: 32),
                                  const Text('PENGELUARAN (EXPENSES)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, letterSpacing: 1)),
                                  const SizedBox(height: 12),
                                  _buildFinanceRow('Biaya Operasional', _totalExpenses, isMinus: true),
                                  const Divider(height: 24, thickness: 1),
                                  _buildFinanceRow('Laba Bersih Operasional', _netProfit, isBold: true, color: _netProfit >= 0 ? AppColors.primaryEmerald : Colors.red),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            Text('*Dihitung dari $_transactionCount transaksi berstatus selesai (COMPLETED) pada periode yang dipilih.', 
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetProfitCard() {
    bool isRugi = _netProfit < 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRugi ? [Colors.red.shade700, Colors.red.shade500] : [AppColors.primaryEmerald, const Color(0xFF107A4D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: (isRugi ? Colors.red : AppColors.primaryEmerald).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.analytics, color: Colors.white, size: 24)),
              const SizedBox(width: 12),
              Text(isRugi ? 'Total Kerugian Bersih' : 'Total Laba Bersih', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_formatCurrency(_netProfit), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, double value, {bool isMinus = false, bool isBold = false, Color? color}) {
    String valStr = _formatCurrency(value);
    if (isMinus && value > 0) valStr = "-$valStr"; // Tambahkan visual minus jika ini item pengurang
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? (color ?? AppColors.navyActive) : AppColors.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 14 : 13)),
          Text(valStr, style: TextStyle(color: isMinus && value > 0 ? Colors.red : (color ?? AppColors.navyActive), fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: isBold ? 14 : 13)),
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
          ElevatedButton(onPressed: _fetchProfitLoss, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald), child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }
}
