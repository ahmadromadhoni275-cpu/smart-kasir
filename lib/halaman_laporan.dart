import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/report_service.dart';
import 'core/services/printer_service.dart';
import 'models/report_summary_model.dart';
import 'tema.dart';

import 'halaman_laporan_penjualan.dart'; 
import 'halaman_laporan_pembayaran.dart';
import 'halaman_laporan_produk.dart';
import 'halaman_laporan_laba_rugi.dart';
import 'halaman_laporan_stok.dart';
import 'halaman_laporan_shift.dart';
import 'halaman_laporan_retur.dart';

class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  final ReportService _service = ReportService();
  
  bool _isLoading = true;
  String _errorMessage = '';
  
  String _selectedFilter = 'Hari Ini';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  ReportSummaryModel? _summary;

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
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final String strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      final data = await _service.getSummary(strDateFrom, strDateTo);
      
      setState(() {
        _summary = ReportSummaryModel.fromJson(data);
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

  Future<void> _cetakRingkasanLaporan() async {
    if (_isLoading || _summary == null) return;

    _showNotif('Menyiapkan pencetakan ringkasan...', AppColors.smartBlue);

    Map<String, dynamic> dataLaporan = {
      'periode': _selectedFilter,
      'total_transaksi': _summary!.transactionCount.toString(),
      'rata_rata_transaksi': _summary!.averageTransaction,
      'total_omzet_bersih': _summary!.netSales,
    };

    try {
      await PrinterService().cetakLaporan(dataLaporan, "RINGKASAN BISNIS");
      if (!mounted) return;
      _showNotif('Ringkasan berhasil dicetak!', AppColors.primaryEmerald);
    } catch (e) {
      if (!mounted) return;
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    }
  }

  Widget _buildGlassFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => _setFilterDate(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        title: const Text('Laporan Bisnis', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.smartBlue),
            tooltip: 'Cetak Ringkasan',
            onPressed: _isLoading ? null : _cetakRingkasanLaporan,
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

              // Filter Periode Bar (Glass Container)
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _buildGlassFilterChip('Hari Ini'),
                            const SizedBox(width: 8),
                            _buildGlassFilterChip('7 Hari'),
                            const SizedBox(width: 8),
                            _buildGlassFilterChip('Bulan Ini'),
                          ],
                        ),
                        InkWell(
                          onTap: _fetchSummary,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.refresh_rounded, color: AppColors.smartBlue, size: 18),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // Dynamic Dashboard Body
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                    : _errorMessage.isNotEmpty
                        ? Center(child: Text(_errorMessage, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)))
                        : RefreshIndicator(
                            color: AppColors.primaryEmerald,
                            backgroundColor: Colors.white,
                            onRefresh: _fetchSummary,
                            child: ListView(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
                              children: [
                                // Omzet Card Utama
                                _buildOmzetCard(),
                                const SizedBox(height: 12),

                                // Sub Metrik
                                Row(
                                  children: [
                                    Expanded(child: _buildMetrikKecil('Transaksi', '${_summary?.transactionCount ?? 0} Trx', Icons.receipt_long_outlined, AppColors.smartBlue)),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildMetrikKecil('Rata-rata', _formatCurrency(_summary?.averageTransaction ?? 0), Icons.analytics_outlined, Colors.orange.shade700)),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Grafik Penjualan
                                const Text('Grafik Penjualan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                                const SizedBox(height: 12),
                                _buildGrafikCard(),
                                const SizedBox(height: 24),

                                // Produk Terlaris
                                const Text('Produk Terlaris (Top 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                                const SizedBox(height: 12),
                                _buildTopProdukCard(),
                                const SizedBox(height: 28),

                                // Grid Detail Laporan Modul
                                const Text('Detail Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                                const SizedBox(height: 12),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.1,
                                  children: [
                                    _buildLaporanMenu(Icons.receipt_long, 'Penjualan', AppColors.smartBlue),
                                    _buildLaporanMenu(Icons.payments_outlined, 'Pembayaran', Colors.orange.shade700),
                                    _buildLaporanMenu(Icons.inventory_2_outlined, 'Produk', Colors.purple),
                                    _buildLaporanMenu(Icons.analytics_outlined, 'Laba Rugi', AppColors.primaryEmerald),
                                    _buildLaporanMenu(Icons.warehouse_outlined, 'Stok', Colors.brown),
                                    _buildLaporanMenu(Icons.swap_horiz_rounded, 'Shift', Colors.indigo),
                                    _buildLaporanMenu(Icons.assignment_return_outlined, 'Retur', AppColors.error),
                                  ],
                                ),
                              ],
                            ),
                          ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET CARD & ELEMEN GLASSMORPHISM
  // ==========================================

  Widget _buildOmzetCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyActive, AppColors.smartBlue],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.navyActive.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Omzet Penjualan', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(_selectedFilter, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(_summary?.netSales ?? 0),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrikKecil(String judul, String nilai, IconData icon, Color warna) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: warna.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 16, color: warna),
                  ),
                  const SizedBox(width: 8),
                  Text(judul, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(nilai, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.navyActive)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrafikCard() {
    final chartData = _summary?.chartData ?? [];

    if (chartData.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.8)),
        ),
        child: const Text('Tidak ada data grafik transaksi pada periode ini', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      );
    }

    double maxTotal = 0;
    for (var item in chartData) {
      if (item.total > maxTotal) maxTotal = item.total;
    }

    return Container(
      height: 190,
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: chartData.map((item) {
              double heightFactor = maxTotal == 0 ? 0 : (item.total / maxTotal);
              String labelTgl = item.date.length >= 10 ? item.date.substring(8, 10) : '-';

              return Tooltip(
                message: '${item.date}: ${_formatCurrency(item.total)}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 22,
                      height: 110 * heightFactor,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.smartBlue, AppColors.primaryEmerald],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(labelTgl, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopProdukCard() {
    final topProducts = _summary?.topProducts ?? [];

    if (topProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.8)),
        ),
        child: const Center(child: Text('Belum ada data produk terjual pada periode ini.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
      );
    }

    return Container(
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
            children: topProducts.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              bool isLast = index == topProducts.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: index == 0 ? AppColors.goldPremium.withOpacity(0.2) : AppColors.smartBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: index == 0 ? AppColors.goldPremium : AppColors.smartBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                    subtitle: Text('Terjual: ${item.qty}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: Text(_formatCurrency(item.revenue), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryEmerald, fontSize: 13)),
                  ),
                  if (!isLast) Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLaporanMenu(IconData icon, String title, Color color) {
    return Container(
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
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (title == 'Penjualan') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLaporanPenjualan()));
              } else if (title == 'Pembayaran') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLaporanPembayaran()));
              } else if (title == 'Produk') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLaporanProduk()));
              } else if (title == 'Laba Rugi') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLaporanLabaRugi()));
              } else if (title == 'Stok') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLaporanStok()));
              } else if (title == 'Shift') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLaporanShift()));
              } else if (title == 'Retur') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLaporanRetur()));
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
