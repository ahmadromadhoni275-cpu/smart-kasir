import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core/services/report_service.dart';
import 'tema.dart';
import 'halaman_laporan_penjualan.dart'; 

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

  // Variabel penampung data API
  double _netSales = 0;
  int _transactionCount = 0;
  double _averageTransaction = 0;
  List _chartData = [];
  List _topProducts = [];

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
        _netSales = double.tryParse(data['net_sales']?.toString() ?? '0') ?? 0.0;
        _transactionCount = int.tryParse(data['transaction_count']?.toString() ?? '0') ?? 0;
        _averageTransaction = double.tryParse(data['average_transaction']?.toString() ?? '0') ?? 0.0;
        _chartData = data['chart_data'] ?? [];
        _topProducts = data['top_products'] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Bisnis', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 1. FILTER TANGGAL
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Hari Ini', '7 Hari', 'Bulan Ini'].map((filter) {
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
          ),

          // 2. KONTEN DASHBOARD
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage, style: const TextStyle(color: AppColors.error)))
                  : RefreshIndicator(
                      color: AppColors.primaryEmerald,
                      onRefresh: _fetchSummary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // --- METRIK UTAMA ---
                          _buildOmzetCard(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildMetrikKecil('Transaksi', _transactionCount.toString(), Icons.receipt_long, Colors.blue)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildMetrikKecil('Rata-rata', _formatCurrency(_averageTransaction), Icons.analytics, Colors.orange)),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // --- GRAFIK PENJUALAN ---
                          const Text('Grafik Penjualan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                          const SizedBox(height: 12),
                          _buildGrafikCard(),

                          const SizedBox(height: 24),
                          
                          // --- PRODUK TERLARIS ---
                          const Text('Produk Terlaris (Top 5)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                          const SizedBox(height: 12),
                          _buildTopProdukCard(),

                          const SizedBox(height: 32),
                          
                          // --- MENU SUB-LAPORAN ---
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
                              _buildLaporanMenu(Icons.receipt_long, 'Penjualan', Colors.blue),
                              _buildLaporanMenu(Icons.payments, 'Pembayaran', Colors.orange),
                              _buildLaporanMenu(Icons.inventory_2, 'Produk', Colors.purple),
                              _buildLaporanMenu(Icons.analytics, 'Laba Rugi', Colors.teal),
                              _buildLaporanMenu(Icons.warehouse, 'Stok', Colors.brown),
                              _buildLaporanMenu(Icons.swap_horiz, 'Shift', Colors.indigo),
                              _buildLaporanMenu(Icons.assignment_return, 'Retur', Colors.red),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                  ),
          )
        ],
      ),
    );
  }

  // --- WIDGET PENDUKUNG ---

  Widget _buildOmzetCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryEmerald, Color(0xFF107A4D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primaryEmerald.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Omzet Penjualan', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(_formatCurrency(_netSales), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetrikKecil(String judul, String nilai, IconData icon, Color warna) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: warna),
              const SizedBox(width: 8),
              Text(judul, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(nilai, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyActive)),
        ],
      ),
    );
  }

  Widget _buildGrafikCard() {
    if (_chartData.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: const Text('Tidak ada data transaksi', style: TextStyle(color: Colors.grey)),
      );
    }

    // Cari nilai tertinggi untuk rasio tinggi grafik
    double maxTotal = 0;
    for (var item in _chartData) {
      double total = double.tryParse(item['total'].toString()) ?? 0;
      if (total > maxTotal) maxTotal = total;
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _chartData.map((item) {
          double total = double.tryParse(item['total'].toString()) ?? 0;
          double heightFactor = maxTotal == 0 ? 0 : total / maxTotal;
          
          // Ambil tanggal saja misal '2026-10-12' -> '12'
          String tglStr = item['date'].toString();
          String labelTgl = tglStr.length >= 10 ? tglStr.substring(8, 10) : '-';

          return Tooltip(
            message: _formatCurrency(total),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 24,
                  height: 120 * heightFactor, // Tinggi maksimal bar 120
                  decoration: BoxDecoration(color: AppColors.primaryEmerald.withOpacity(0.8), borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 8),
                Text(labelTgl, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

    Widget _buildTopProdukCard() {
    if (_topProducts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: const Center(child: Text('Belum ada produk terjual.', style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: _topProducts.asMap().entries.map((entry) {
          int index = entry.key;
          var item = entry.value;
          bool isLast = index == _topProducts.length - 1;
          
          // Pengamanan parsing berlapis (Null Safety)
          String namaProduk = item['product_name']?.toString() ?? 'Produk Tidak Diketahui';
          String qty = item['qty']?.toString() ?? '0';
          double revenue = double.tryParse(item['revenue']?.toString() ?? '0') ?? 0.0;
          
          return Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryEmerald.withOpacity(0.1),
                  child: Text('${index + 1}', style: const TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold)),
                ),
                title: Text(namaProduk, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Terjual: $qty', style: const TextStyle(fontSize: 12)),
                trailing: Text(_formatCurrency(revenue), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLaporanMenu(IconData icon, String title, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (title == 'Penjualan') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanLaporanPenjualan()));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Halaman Laporan $title sedang dibangun!')));
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
