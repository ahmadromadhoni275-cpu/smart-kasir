import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart'; 
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

  List<dynamic> _transactions = [];
  
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

      final data = await _service.getSales(strDateFrom, strDateTo);
      
      // Hitung Rekapitulasi
      double tempTotal = 0;
      Map<String, double> tempDaily = {};
      
      for (var tx in data) {
        double total = double.tryParse(tx['grand_total']?.toString() ?? '0') ?? 0.0;
        tempTotal += total;
        
        // Ambil string tanggal saja (YYYY-MM-DD)
        String dateOnly = tx['created_at'].toString().length >= 10 
            ? tx['created_at'].toString().substring(0, 10) 
            : 'Unknown';
            
        tempDaily[dateOnly] = (tempDaily[dateOnly] ?? 0) + total;
      }

      setState(() {
        _transactions = data;
        _totalSales = tempTotal;
        _transactionCount = data.length;
        _dailyRecap = tempDaily;
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // HELPER FORMATTER
  // ==========================================
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

  // ==========================================
  // LOGIKA CETAK LAPORAN PENJUALAN
  // ==========================================
  Future<void> _cetakLaporanPenjualan() async {
    if (_isLoading) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menyiapkan pencetakan...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.blue)
    );

    // Menyusun data rekap penjualan
    Map<String, dynamic> dataLaporan = {
      'periode': _selectedFilter,
      'Total_Transaksi': '$_transactionCount Transaksi',
      'Total_Penjualan': _totalSales,
      '-- REKAP HARIAN --': '',
    };

    // Tambahkan rekap penjualan per hari ke dalam struk
    _dailyRecap.forEach((tanggal, total) {
      String tglBagus = _formatDateUI(tanggal);
      dataLaporan[tglBagus] = total;
    });

    try {
      await PrinterService().cetakLaporan(dataLaporan, "LAPORAN PENJUALAN");
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan Penjualan berhasil dicetak!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: AppColors.primaryEmerald)
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.red)
      );
    }
  }

  // ==========================================
  // WIDGET BUILDER
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Penjualan', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        // --- TOMBOL CETAK DI SUDUT KANAN ATAS ---
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: AppColors.primaryEmerald),
            tooltip: 'Cetak Laporan',
            onPressed: _isLoading || _transactions.isEmpty ? null : _cetakLaporanPenjualan,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : RefreshIndicator(
                  color: AppColors.primaryEmerald,
                  onRefresh: _fetchSales,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildFilterPanel()),
                      SliverToBoxAdapter(child: _buildSummaryCards()),
                      
                      if (_dailyRecap.isNotEmpty) 
                        SliverToBoxAdapter(child: _buildDailyRecap()),
                        
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
                          child: Text('Daftar Transaksi (${_transactions.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
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
                color: AppColors.primaryEmerald,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primaryEmerald.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Penjualan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(_formatCurrency(_totalSales), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                  const Text('Transaksi', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$_transactionCount', style: const TextStyle(color: AppColors.navyActive, fontSize: 20, fontWeight: FontWeight.bold)),
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
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _dailyRecap.length,
            itemBuilder: (context, index) {
              String dateKey = _dailyRecap.keys.elementAt(index);
              double dailyTotal = _dailyRecap[dateKey] ?? 0;
              
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_formatDateUI(dateKey), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(_formatCurrency(dailyTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 14)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    String invoice = tx['invoice_number']?.toString() ?? '-';
    String createdAt = tx['created_at']?.toString() ?? '';
    double total = double.tryParse(tx['grand_total']?.toString() ?? '0') ?? 0.0;
    
    // Status
    String txStatus = tx['transaction_status']?.toString() ?? 'UNKNOWN';
    String payStatus = tx['payment_status']?.toString() ?? 'UNPAID';
    
    bool isCompleted = txStatus == 'COMPLETED';

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(invoice, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isCompleted ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    isCompleted ? 'BERHASIL' : txStatus,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green.shade700 : Colors.red.shade700),
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
                        Text(_formatDateUI(createdAt, fullTime: true), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.payment, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(payStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: payStatus == 'PAID' ? AppColors.smartBlue : Colors.orange)),
                      ],
                    ),
                  ],
                ),
                Text(
                  _formatCurrency(total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryEmerald),
                ),
              ],
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
            Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Tidak ada penjualan di periode ini', style: TextStyle(color: AppColors.textSecondary)),
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
              onPressed: _fetchSales,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
