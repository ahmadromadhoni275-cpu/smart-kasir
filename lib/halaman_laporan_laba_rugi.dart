import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart';
import 'models/profit_loss_report_model.dart'; // Import model
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

  ProfitLossData _plData = ProfitLossData(
    grossSales: 0, totalDiscount: 0, totalReturns: 0, netSales: 0, 
    totalCogs: 0, grossProfit: 0, totalExpenses: 0, netProfit: 0, transactionCount: 0
  );

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
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final String strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final String strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      // PERBAIKAN 1: Tangkap respon JSON mentah (Map) ke dalam variabel rawData
      final dynamic rawData = await _service.getProfitLoss(strDateFrom, strDateTo);
      
      // PERBAIKAN 2: Konversi Map JSON mentah tersebut menggunakan fungsi fromJson
      final ProfitLossData parsedData = ProfitLossData.fromJson(rawData as Map<String, dynamic>);
      
      setState(() {
        _plData = parsedData;
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
  // CETAK LAPORAN LABA RUGI
  // ==========================================
  Future<void> _cetakLaporanLabaRugi() async {
    if (_isLoading) return;

    _showNotif('Menyiapkan pencetakan...', AppColors.smartBlue);

    Map<String, dynamic> dataLaporan = {
      'periode': _selectedFilter,
      '-- PENDAPATAN --': '',
      'Penjualan_Kotor': _plData.grossSales,
      'Diskon_Penjualan': _plData.totalDiscount > 0 ? -(_plData.totalDiscount) : 0,
      'Retur_Penjualan': _plData.totalReturns > 0 ? -(_plData.totalReturns) : 0,
      'Penjualan_Bersih_(Net)': _plData.netSales,
      '-- HPP & BIAYA --': '',
      'Harga_Pokok_(COGS)': _plData.totalCogs > 0 ? -(_plData.totalCogs) : 0,
      'Laba_Kotor_(Gross)': _plData.grossProfit,
      'Biaya_Operasional': _plData.totalExpenses > 0 ? -(_plData.totalExpenses) : 0,
      '-- LABA BERSIH --': '',
      'LABA_RUGI_BERSIH': _plData.netProfit,
    };

    try {
      await PrinterService().cetakLaporan(dataLaporan, "LAPORAN LABA RUGI");
      if (!mounted) return;
      _showNotif('Laporan Laba Rugi berhasil dicetak!', AppColors.primaryEmerald);
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
        title: const Text('Laba & Rugi (P&L)', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.smartBlue),
            tooltip: 'Cetak Laporan',
            onPressed: _isLoading ? null : _cetakLaporanLabaRugi,
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

          CustomScrollView(
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

              SliverFillRemaining(
                hasScrollBody: false,
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                    : _errorMessage.isNotEmpty
                        ? _buildErrorState()
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildNetProfitCard(),
                                const SizedBox(height: 24),
                                _buildPLDocument(),
                                
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Dihitung dari ${_plData.transactionCount} transaksi berstatus selesai (COMPLETED) pada periode yang dipilih.', 
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetProfitCard() {
    bool isRugi = _plData.isLoss;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRugi ? [Colors.red.shade700, Colors.red.shade400] : [AppColors.primaryEmerald, AppColors.navyActive],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: (isRugi ? Colors.red : AppColors.navyActive).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), 
                child: Row(
                  children: [
                    Icon(isRugi ? Icons.trending_down : Icons.trending_up, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(isRugi ? 'Total Kerugian Bersih' : 'Total Laba Bersih', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              ),
              Icon(Icons.account_balance_wallet_outlined, color: Colors.white.withOpacity(0.5), size: 32),
            ],
          ),
          const SizedBox(height: 24),
          Text(_formatCurrency(_plData.netProfit), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPLDocument() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('PENDAPATAN (REVENUE)'),
                const SizedBox(height: 16),
                _buildFinanceRow('Penjualan Kotor', _plData.grossSales),
                _buildFinanceRow('Diskon Penjualan', _plData.totalDiscount, isMinus: true),
                _buildFinanceRow('Retur Penjualan', _plData.totalReturns, isMinus: true),
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.border)),
                _buildFinanceRow('Penjualan Bersih (Net Sales)', _plData.netSales, isBold: true),
                
                const SizedBox(height: 32),
                _buildSectionHeader('HARGA POKOK (COGS)'),
                const SizedBox(height: 16),
                _buildFinanceRow('Harga Pokok Penjualan', _plData.totalCogs, isMinus: true),
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.border)),
                _buildFinanceRow('Laba Kotor (Gross Profit)', _plData.grossProfit, isBold: true, color: AppColors.smartBlue),

                const SizedBox(height: 32),
                _buildSectionHeader('PENGELUARAN (EXPENSES)'),
                const SizedBox(height: 16),
                _buildFinanceRow('Biaya Operasional', _plData.totalExpenses, isMinus: true),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 2, color: AppColors.navyActive)),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Laba Bersih Operasional', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.w900, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _plData.isLoss ? Colors.red.withOpacity(0.1) : AppColors.primaryEmerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        _formatCurrency(_plData.netProfit), 
                        style: TextStyle(color: _plData.isLoss ? AppColors.error : AppColors.primaryEmerald, fontWeight: FontWeight.w900, fontSize: 16)
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.navyActive, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navyActive, fontSize: 13, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildFinanceRow(String label, double value, {bool isMinus = false, bool isBold = false, Color? color}) {
    String valStr = _formatCurrency(value);
    if (isMinus && value > 0) valStr = "-$valStr";
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? (color ?? AppColors.navyActive) : AppColors.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, fontSize: isBold ? 14 : 13)),
          Text(valStr, style: TextStyle(color: isMinus && value > 0 ? AppColors.error : (color ?? AppColors.navyActive), fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, fontSize: isBold ? 15 : 14)),
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
              onPressed: _fetchProfitLoss, 
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
