import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart'; 
import 'models/report_model.dart'; // Impor model yang menampung SalesReportItem
import 'tema.dart';

class HalamanLaporanPenjualan extends StatefulWidget {
  const HalamanLaporanPenjualan({super.key});

  @override
  State<HalamanLaporanPenjualan> createState() => _HalamanLaporanPenjualanState();
}

class _HalamanLaporanPenjualanState extends State<HalamanLaporanPenjualan> {
  final ReportService _service = ReportService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'Hari Ini';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  List<SalesReportItem> _transactions = [];
  
  // Variabel Rekap
  double _totalSales = 0;
  int _transactionCount = 0;
  Map<String, double> _dailyRecap = {};

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
        _fetchSales();
      } else if (filterType == '7 Hari') {
        _dateFrom = now.subtract(const Duration(days: 6));
        _dateTo = now;
        _fetchSales();
      } else if (filterType == 'Bulan Ini') {
        _dateFrom = DateTime(now.year, now.month, 1);
        _dateTo = DateTime(now.year, now.month + 1, 0);
        _fetchSales();
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
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryEmerald),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
      _fetchSales();
    } else {
      setState(() => _selectedFilter = 'Hari Ini');
      _setFilterDate('Hari Ini');
    }
  }

  // ==========================================
  // FETCH DATA & PERHITUNGAN REKAP
  // ==========================================
  Future<void> _fetchSales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final String strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      // PERBAIKAN: Tangkap respon sebagai dynamic dulu (List<dynamic>)
      final dynamic rawData = await _service.getSales(strDateFrom, strDateTo);
      
      // PERBAIKAN: Lakukan mapping dari List<dynamic> ke List<SalesReportItem>
      final List<SalesReportItem> data = (rawData as List).map((item) {
        return SalesReportItem.fromJson(item as Map<String, dynamic>);
      }).toList();
      
      // Hitung Rekapitulasi
      double tempTotal = 0;
      Map<String, double> tempDaily = {};
      
      for (var tx in data) {
        // Hanya hitung jika status COMPLETED
        if (tx.transactionStatus == 'COMPLETED') {
          tempTotal += tx.grandTotal;
          
          String dateOnly = tx.createdAt.length >= 10 ? tx.createdAt.substring(0, 10) : 'Unknown';
          tempDaily[dateOnly] = (tempDaily[dateOnly] ?? 0) + tx.grandTotal;
        }
      }

      setState(() {
        _transactions = data;
        _totalSales = tempTotal;
        _transactionCount = data.length; // Total semua record (termasuk batal)
        _dailyRecap = tempDaily;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

      setState(() {
        _transactions = data;
        _totalSales = tempTotal;
        _transactionCount = data.length; // Total semua record (termasuk batal)
        _dailyRecap = tempDaily;
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

  String _formatDateUI(String dateStr, {bool fullTime = false}) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      if (fullTime) {
        return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
      }
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    } catch (e) {
      return dateStr;
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
  // LOGIKA CETAK LAPORAN PENJUALAN
  // ==========================================
  Future<void> _cetakLaporanPenjualan() async {
    if (_isLoading) return;

    _showNotif('Menyiapkan pencetakan...', AppColors.smartBlue);

    Map<String, dynamic> dataLaporan = {
      'periode': _selectedFilter,
      'Total_Transaksi': '$_transactionCount Transaksi',
      'Total_Penjualan': _totalSales,
      '-- REKAP HARIAN --': '',
    };

    _dailyRecap.forEach((tanggal, total) {
      String tglBagus = _formatDateUI(tanggal);
      dataLaporan[tglBagus] = total;
    });

    try {
      await PrinterService().cetakLaporan(dataLaporan, "LAPORAN PENJUALAN");
      if (!mounted) return;
      _showNotif('Laporan Penjualan berhasil dicetak!', AppColors.primaryEmerald);
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
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Laporan Penjualan', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.smartBlue),
            tooltip: 'Cetak Laporan',
            onPressed: _isLoading || _transactions.isEmpty ? null : _cetakLaporanPenjualan,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.withOpacity(0.2), height: 1)),
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

          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),

              // Filter Periode Bar (Glass)
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
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                  : _errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : RefreshIndicator(
                          color: AppColors.primaryEmerald,
                          backgroundColor: Colors.white,
                          onRefresh: _fetchSales,
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: _buildSummaryCards()),
                              
                              if (_dailyRecap.isNotEmpty) 
                                SliverToBoxAdapter(child: _buildDailyRecap()),
                                
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Daftar Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(10)),
                                        child: Text('${_transactions.length} Data', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              
                              _transactions.isEmpty
                                  ? SliverToBoxAdapter(child: _buildEmptyState())
                                  : SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) => _buildTransactionItem(_transactions[index]),
                                        childCount: _transactions.length,
                                      ),
                                    ),
                                    
                              const SliverToBoxAdapter(child: SizedBox(height: 40)),
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
                gradient: const LinearGradient(colors: [AppColors.smartBlue, AppColors.primaryEmerald], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primaryEmerald.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Text('Total Penjualan', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_formatCurrency(_totalSales), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary, size: 16),
                      SizedBox(width: 6),
                      Text('Transaksi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('$_transactionCount', style: const TextStyle(color: AppColors.navyActive, fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Rekap Harian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _dailyRecap.length,
            itemBuilder: (context, index) {
              String dateKey = _dailyRecap.keys.elementAt(index);
              double dailyTotal = _dailyRecap[dateKey] ?? 0;
              
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_formatDateUI(dateKey), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_formatCurrency(dailyTotal), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navyActive, fontSize: 15)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(SalesReportItem tx) {
    bool isCompleted = tx.transactionStatus == 'COMPLETED';
    bool isPaid = tx.paymentStatus == 'PAID';

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(tx.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navyActive, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.primaryEmerald.withOpacity(0.15) : AppColors.error.withOpacity(0.15), 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        isCompleted ? 'BERHASIL' : tx.transactionStatus,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isCompleted ? AppColors.primaryEmerald : AppColors.error),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(_formatDateUI(tx.createdAt, fullTime: true), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.payment_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              tx.paymentStatus, 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPaid ? AppColors.smartBlue : Colors.orange.shade700)
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      _formatCurrency(tx.grandTotal),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isCompleted ? AppColors.primaryEmerald : AppColors.textSecondary),
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_outlined, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            const Text('Tidak ada penjualan di periode ini', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
              onPressed: _fetchSales,
              icon: const Icon(Icons.refresh, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
              ),
              label: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
