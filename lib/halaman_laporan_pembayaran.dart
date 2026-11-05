import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart';
import 'models/payment_report_model.dart'; // Import model
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

  List<PaymentReportItem> _payments = [];
  
  double _totalAmount = 0;
  int _totalCount = 0;

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
      } else if (filterType == 'Kustom') {
        _pilihTanggalKustom();
        return;
      }
    });
    _fetchPayments();
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
      _fetchPayments();
    } else {
      setState(() => _selectedFilter = 'Hari Ini');
      _setFilterDate('Hari Ini');
    }
  }

  Future<void> _fetchPayments() async {
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      final String strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final String strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      // Gunakan casting/mapping List dari API ke Model
      final data = await _service.getPayments(strDateFrom, strDateTo);
      final List<PaymentReportItem> parsedData = (data as List).map((e) {
        if (e is PaymentReportItem) return e;
        return PaymentReportItem.fromJson(e);
      }).toList();
      
      double tempNominal = 0;
      int tempCount = 0;
      
      for (var pay in parsedData) {
        tempNominal += pay.totalAmount;
        tempCount += pay.paymentCount;
      }

      setState(() {
        _payments = parsedData;
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

  Map<String, dynamic> _getPaymentStyle(String method) {
    switch (method.toUpperCase()) {
      case 'CASH':
        return {'icon': Icons.payments_outlined, 'color': const Color(0xFF107A4D)};
      case 'QRIS':
        return {'icon': Icons.qr_code_2_outlined, 'color': AppColors.smartBlue};
      case 'TRANSFER':
        return {'icon': Icons.account_balance_outlined, 'color': Colors.orange.shade700};
      case 'EWALLET':
        return {'icon': Icons.account_balance_wallet_outlined, 'color': Colors.purple.shade600};
      default:
        return {'icon': Icons.credit_card_outlined, 'color': AppColors.slateGray};
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
  // CETAK LAPORAN PEMBAYARAN
  // ==========================================
  Future<void> _cetakLaporanPembayaran() async {
    if (_isLoading || _payments.isEmpty) return;

    _showNotif('Menyiapkan pencetakan...', AppColors.smartBlue);

    Map<String, dynamic> dataLaporan = {
      'periode': _selectedFilter,
      'Total_Frekuensi': '$_totalCount Transaksi',
      'Total_Nominal': _totalAmount,
      '-- RINCIAN METODE --': '',
    };

    for (var pay in _payments) {
      dataLaporan['${pay.methodGroup} (${pay.paymentCount}x)'] = pay.totalAmount;
    }

    try {
      await PrinterService().cetakLaporan(dataLaporan, "LAPORAN METODE PEMBAYARAN");
      if (!mounted) return;
      _showNotif('Laporan Pembayaran berhasil dicetak!', AppColors.primaryEmerald);
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
        title: const Text('Laporan Pembayaran', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.smartBlue),
            tooltip: 'Cetak Laporan',
            onPressed: _isLoading || _payments.isEmpty ? null : _cetakLaporanPembayaran,
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
                    onRefresh: _fetchPayments,
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
                            child: Text('Rincian Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange.shade500], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pembayaran Masuk', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_formatCurrency(_totalAmount), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
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
                      const Text('Jumlah (x)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('$_totalCount', style: const TextStyle(color: AppColors.navyActive, fontSize: 22, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(PaymentReportItem pay) {
    double percentage = _totalAmount > 0 ? (pay.totalAmount / _totalAmount) : 0;
    String strPercentage = (percentage * 100).toStringAsFixed(1);
    
    final style = _getPaymentStyle(pay.methodGroup);
    Color mainColor = style['color'];

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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: mainColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(style['icon'], color: mainColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pay.methodGroup, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.navyActive)),
                          const SizedBox(height: 4),
                          Text('${pay.paymentCount} Transaksi', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatCurrency(pay.totalAmount), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.navyActive)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: mainColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text('$strPercentage%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: mainColor)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppColors.lightGray,
                    color: mainColor,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
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
              child: Icon(Icons.account_balance_wallet_outlined, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada pembayaran sukses di periode ini', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
              onPressed: _fetchPayments,
              icon: const Icon(Icons.refresh, color: Colors.white),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              label: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
