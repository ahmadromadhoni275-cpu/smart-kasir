import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart';
import 'models/plan_model.dart';
import 'core/services/subscription_service.dart';
import 'halaman_tagihan_langganan.dart';

class HalamanPilihPaket extends StatefulWidget {
  const HalamanPilihPaket({super.key});

  @override
  State<HalamanPilihPaket> createState() => _HalamanPilihPaketState();
}

class _HalamanPilihPaketState extends State<HalamanPilihPaket> {
  final SubscriptionService _subService = SubscriptionService();
  List<PlanModel> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final data = await _subService.getAvailablePlans();
      if (mounted) setState(() => _plans = data);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pilih Paket', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]))),
          
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 40),
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final PlanModel paket = _plans[index];
                  bool isHighlighted = paket.price > 50000; // Contoh logika highlight
                  return _buildPlanCard(paket, isHighlighted);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PlanModel paket, bool isHighlighted) {
    String durasi = paket.billingCycle == 'MONTHLY' ? 'Bulan' : paket.billingCycle == 'YEARLY' ? 'Tahun' : 'Selamanya';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.navyActive : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isHighlighted ? AppColors.goldPremium : Colors.white, width: isHighlighted ? 2 : 1.5),
        boxShadow: [BoxShadow(color: (isHighlighted ? AppColors.navyActive : AppColors.shadowBlue).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHighlighted)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.goldPremium, borderRadius: BorderRadius.circular(20)),
                child: const Text('PALING POPULER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            
            Text(paket.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isHighlighted ? Colors.white : AppColors.navyActive)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatRupiah(paket.price), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: isHighlighted ? AppColors.goldPremium : AppColors.primaryEmerald)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(' / $durasi', style: TextStyle(fontSize: 13, color: isHighlighted ? Colors.white70 : AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: AppColors.border, height: 1)),
            
            ...paket.features.map((fitur) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: isHighlighted ? AppColors.goldPremium : AppColors.primaryEmerald, size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Text(fitur, style: TextStyle(color: isHighlighted ? Colors.white : AppColors.navyActive, fontSize: 13))),
                ],
              ),
            )).toList(),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isHighlighted ? AppColors.goldPremium : AppColors.navyActive, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanTagihanLangganan(planId: paket.planId))),
                child: Text('PILIH ${paket.name.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
