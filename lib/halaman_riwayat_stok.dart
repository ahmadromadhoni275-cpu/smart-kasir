import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart';
import 'core/services/stock_service.dart';
import 'models/stock_movement_model.dart';

class HalamanRiwayatStok extends StatefulWidget {
  const HalamanRiwayatStok({super.key});

  @override
  State<HalamanRiwayatStok> createState() => _HalamanRiwayatStokState();
}

class _HalamanRiwayatStokState extends State<HalamanRiwayatStok> {
  bool _isLoading = true;
  List<StockMovementModel> _movements = [];
  String _filterType = ''; // '', 'IN', 'OUT', 'ADJUSTMENT', 'RETURN'

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final rawData = await StockService.getMovements(type: _filterType);
      if (mounted) {
        setState(() {
          _movements = rawData.map((e) => StockMovementModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Color _getColorByType(String type) {
    if (type == 'IN') return AppColors.smartBlue;
    if (type == 'OUT') return AppColors.error;
    if (type == 'RETURN') return AppColors.primaryEmerald;
    return Colors.orange.shade700; // ADJUSTMENT
  }

  IconData _getIconByType(String type) {
    if (type == 'IN') return Icons.arrow_downward_rounded;
    if (type == 'OUT') return Icons.arrow_upward_rounded;
    if (type == 'RETURN') return Icons.assignment_return_outlined;
    return Icons.tune_rounded; // ADJUSTMENT
  }

  Widget _buildGlassFilterChip(String label, String value) {
    bool isSelected = _filterType == value;
    return InkWell(
      onTap: () {
        setState(() => _filterType = value);
        _fetchRiwayat();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyActive : Colors.white.withOpacity(0.5),
          border: Border.all(color: isSelected ? AppColors.navyActive : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.navyActive.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Riwayat Pergerakan', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 0,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: Colors.grey.withOpacity(0.2), height: 1)),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]
              ),
            ),
          ),
          
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
              
              // Filter Bar
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
                          _buildGlassFilterChip('Semua', ''),
                          const SizedBox(width: 10),
                          _buildGlassFilterChip('Masuk', 'IN'),
                          const SizedBox(width: 10),
                          _buildGlassFilterChip('Keluar', 'OUT'),
                          const SizedBox(width: 10),
                          _buildGlassFilterChip('Opname', 'ADJUSTMENT'),
                          const SizedBox(width: 10),
                          _buildGlassFilterChip('Retur', 'RETURN'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                  : _movements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 80, color: AppColors.textSecondary.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            const Text('Belum ada riwayat pergerakan stok.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchRiwayat,
                        color: AppColors.primaryEmerald,
                        backgroundColor: Colors.white,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
                          itemCount: _movements.length,
                          itemBuilder: (ctx, i) {
                            final mv = _movements[i];
                            String prefix = (mv.type == 'IN' || mv.type == 'RETURN' || mv.quantity > 0) ? '+' : '';

                            DateTime date = DateTime.tryParse(mv.createdAt)?.toLocal() ?? DateTime.now();
                            String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
                                boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        color: _getColorByType(mv.type).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _getColorByType(mv.type).withOpacity(0.3))
                                      ),
                                      child: Icon(_getIconByType(mv.type), color: _getColorByType(mv.type)),
                                    ),
                                    title: Text(mv.productName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 14)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('$formattedDate • ${mv.userName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        if (mv.note != null && mv.note!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text('"${mv.note}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87)),
                                          ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('$prefix${mv.quantity}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _getColorByType(mv.type))),
                                        const SizedBox(height: 2),
                                        Text('${mv.stockBefore} ➔ ${mv.stockAfter}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
