import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; 

import 'tema.dart';
import 'core/services/dashboard_service.dart';
import 'models/dashboard_model.dart';

class HalamanBeranda extends StatefulWidget {
  const HalamanBeranda({super.key});

  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

class _HalamanBerandaState extends State<HalamanBeranda> {
  bool _isLoading = true;
  String _role = 'KASIR';
  String _namaPetugas = 'User';
  
  // Menggunakan Master Model untuk menampung seluruh data
  DashboardModel? _dashboardData;

  // Variabel untuk Jam Real-Time
  late Stream<DateTime> _timeStream;

  // Variabel untuk Carousel
  final PageController _pageController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;

  // Instansiasi Service Baru
  final DashboardService _dashboardService = DashboardService();

  @override
  void initState() {
    super.initState();
    _timeStream = Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => DateTime.now());
    
    _muatDataDashboard();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel(); 
    _pageController.dispose();
    super.dispose();
  }

  void _mulaiCarousel() {
    _carouselTimer?.cancel(); // Pastikan timer sebelumnya dibersihkan
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _dashboardData != null) {
        int bannerCount = _dashboardData!.banners.length;
        if (bannerCount > 1) {
          int nextPage = (_currentCarouselIndex + 1) % bannerCount;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  Future<void> _muatDataDashboard() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _role = (prefs.getString('role') ?? 'KASIR').toUpperCase();
      _namaPetugas = prefs.getString('username') ?? 'User';
      
      // Ambil data utuh menggunakan Service baru
      final DashboardModel data = await _dashboardService.getDashboardData();

      if (mounted) {
        setState(() {
          _dashboardData = data;
        });
        
        // Memulai ulang carousel jika ada data banner
        if (data.banners.isNotEmpty) {
          _mulaiCarousel();
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat data dashboard: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString().replaceAll('Exception: ', '')}'), 
            backgroundColor: AppColors.error
          )
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(num angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  // =================================================================
  // HEADER DENGAN JAM REAL-TIME DAN SALAM
  // =================================================================
  Widget _buildHeader(bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardSolid, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Kiri: Salam
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Selamat Datang,', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(_namaPetugas, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.smartBlue)),
                  const SizedBox(width: 8),
                  const Text('👋', style: TextStyle(fontSize: 24)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Kelola toko Anda dengan mudah dan profesional', style: TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              if (_role != 'OWNER')
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.menuActiveStart, AppColors.menuActiveEnd]),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: AppColors.smartBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    onPressed: () {},
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.point_of_sale, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Mulai Transaksi →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Kanan: Jam Real-Time 
          if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: StreamBuilder<DateTime>(
                stream: _timeStream,
                builder: (context, snapshot) {
                  final now = snapshot.data ?? DateTime.now();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(now), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(DateFormat('HH.mm.ss').format(now), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.navyActive, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text('Sistem Online', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      )
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // =================================================================
  // WIDGET CARD RINGKASAN ATAS (GLASSMORPHISM)
  // =================================================================
  Widget _buildSummaryCard(String title, String value, String subtitle, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 1.2),
        boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 20, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(subtitle.contains('+') ? Icons.arrow_upward : Icons.arrow_downward, 
                   size: 14, color: subtitle.contains('+') ? AppColors.greenAccent : AppColors.error),
              const SizedBox(width: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: subtitle.contains('+') ? AppColors.greenAccent : AppColors.error, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // =================================================================
  // GRID CARDS 
  // =================================================================
  Widget _buildSummarySection() {
    if (_dashboardData == null) return const SizedBox.shrink();

    // Data aman karena sudah melalui safe-parsing di DashboardStatisticsModel
    double sales = _dashboardData!.summary.sales;
    int trxCount = _dashboardData!.summary.transactions;
    int productsCount = _dashboardData!.summary.products;
    int lowStock = _dashboardData!.summary.lowStock;
    double profit = _dashboardData!.summary.profit;

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1000 ? 4 : (constraints.maxWidth > 600 ? 2 : 2);
        double childAspectRatio = constraints.maxWidth > 600 ? 1.6 : 1.3;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _buildSummaryCard('Total Penjualan', _formatRupiah(sales), '+0.0%', Icons.shopping_cart_outlined, Colors.white, AppColors.salesBlue),
            _buildSummaryCard('Total Transaksi', '$trxCount Trx', '+0.0%', Icons.loop, Colors.white, AppColors.transactionGreen), 
            _buildSummaryCard('Produk Tersedia', '$productsCount Item', '+0.0%', Icons.inventory_2_outlined, Colors.white, AppColors.productPurple),
            
            if (_role != 'KASIR') 
              _buildSummaryCard('Keuntungan', _formatRupiah(profit), '+0.0%', Icons.account_balance_wallet_outlined, Colors.white, AppColors.profitOrange)
            else
              _buildSummaryCard('Stok Menipis', '$lowStock Item', '-0.0%', Icons.warning_amber_rounded, Colors.white, AppColors.error),
          ],
        );
      },
    );
  }

  // =================================================================
  // WIDGET PRODUK TERLARIS & TRANSAKSI TERBARU 
  // =================================================================
  Widget _buildBottomSection(bool isDesktop) {
    if (_dashboardData == null) return const SizedBox.shrink();

    Widget txWidget = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.cardSolid, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 20, offset: Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: AppColors.smartBlue, size: 20),
                  SizedBox(width: 8),
                  Text('Transaksi Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              TextButton(onPressed: () {}, child: const Text('Lihat Semua →', style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold)))
            ],
          ),
          const SizedBox(height: 16),
          if (_dashboardData!.recentTransactions.isEmpty) const Text('Belum ada transaksi hari ini.', style: TextStyle(color: AppColors.textSecondary)),
          ..._dashboardData!.recentTransactions.map((tx) {
            String time = tx.createdAt.isNotEmpty ? tx.createdAt.substring(11, 16) : '-';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.receipt_long, color: AppColors.smartBlue, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navyActive)),
                        Text('Hari ini, $time', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(_formatRupiah(tx.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 14)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    Widget bestWidget = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.cardSolid, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 20, offset: Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events, color: AppColors.goldPremium, size: 20),
                  SizedBox(width: 8),
                  Text('Produk Terlaris', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              TextButton(onPressed: () {}, child: const Text('Lihat Semua →', style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold)))
            ],
          ),
          const SizedBox(height: 16),
          if (_dashboardData!.bestProducts.isEmpty) const Text('Belum ada data', style: TextStyle(color: AppColors.textSecondary)),
          
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _dashboardData!.bestProducts.length,
              itemBuilder: (context, index) {
                var prod = _dashboardData!.bestProducts[index];

                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.goldPremium, radius: 12,
                        child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${prod.soldQuantity} Terjual', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: txWidget),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: bestWidget),
        ],
      );
    }
    return Column(
      children: [
        txWidget,
        const SizedBox(height: 16),
        bestWidget,
      ],
    );
  }

  // =================================================================
  // CAROUSEL BANNER (PROMO/INFO)
  // =================================================================
  IconData _getBannerIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'print': return Icons.print;
      case 'workspace_premium': return Icons.workspace_premium;
      case 'update': return Icons.system_update;
      default: return Icons.campaign;
    }
  }

  List<Color> _getBannerGradient(String theme) {
    switch (theme.toLowerCase()) {
      case 'blue': return [Colors.blue.shade700, Colors.blue.shade400];
      case 'gold': return [AppColors.goldPremium, Colors.orange.shade300];
      default: return [AppColors.primaryEmerald, Colors.teal.shade400];
    }
  }

  Widget _buildCarousel() {
    if (_dashboardData == null || _dashboardData!.banners.isEmpty) return const SizedBox.shrink();

    List<Widget> slides = _dashboardData!.banners.map((b) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: _getBannerGradient(b['color_theme'] ?? ''), begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: _getBannerGradient(b['color_theme'] ?? '')[0].withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(b['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(b['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(_getBannerIcon(b['icon_name'] ?? ''), size: 60, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      );
    }).toList();

    int safeIndex = _currentCarouselIndex >= slides.length ? 0 : _currentCarouselIndex;

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentCarouselIndex = index),
            children: slides,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6, width: safeIndex == index ? 24 : 6,
              decoration: BoxDecoration(color: safeIndex == index ? AppColors.smartBlue : Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.smartBlue))
          : LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 800;
                
                return RefreshIndicator(
                  color: AppColors.smartBlue,
                  onRefresh: _muatDataDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isDesktop),
                        _buildCarousel(),
                        const SizedBox(height: 24),
                        _buildSummarySection(),
                        const SizedBox(height: 24),
                        _buildBottomSection(isDesktop),
                        const SizedBox(height: 60), 
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
