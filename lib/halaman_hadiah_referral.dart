import 'dart:ui';
import 'package:flutter/material.dart';

import 'tema.dart';
import 'core/services/referral_service.dart';

class HalamanHadiahReferral extends StatefulWidget {
  const HalamanHadiahReferral({super.key});

  @override
  State<HalamanHadiahReferral> createState() => _HalamanHadiahReferralState();
}

class _HalamanHadiahReferralState extends State<HalamanHadiahReferral> {
  final ReferralService _referralService = ReferralService();
  Map<String, dynamic>? dataRewards;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatHadiah();
  }

  Future<void> _muatHadiah() async {
    setState(() => isLoading = true);
    try {
      final data = await _referralService.getRewards();
      if (mounted) setState(() => dataRewards = data);
    } catch (e) {
      debugPrint("Gagal load hadiah: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _tampilPopup(String judul, String pesan, IconData ikon, Color warna) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(ikon, color: warna), const SizedBox(width: 8), Text(judul, style: TextStyle(color: warna, fontWeight: FontWeight.bold))]),
        content: Text(pesan, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: warna, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Oke', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  Future<void> _klaimHadiah(String rewardId) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));
    try {
      await _referralService.claimReward(rewardId);
      if (mounted) Navigator.pop(context); // Tutup loading
      _tampilPopup('Berhasil', 'Klaim hadiah berhasil diajukan! Kami akan segera memprosesnya.', Icons.check_circle, AppColors.primaryEmerald);
      _muatHadiah();
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _tampilPopup('Gagal Klaim', e.toString().replaceAll('Exception: ', ''), Icons.warning, AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Hadiah Saya', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]))),
          
          isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 40),
                itemCount: dataRewards?['tiers']?.length ?? 0,
                itemBuilder: (context, index) {
                  final tier = dataRewards!['tiers'][index];
                  final int validRef = dataRewards!['valid_referrals'] ?? 0;
                  final int reqRef = int.parse(tier['required_referrals'].toString());
                  final bool isUnlocked = validRef >= reqRef;

                  return _buildKartuTier(tier, isUnlocked, validRef, reqRef);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildKartuTier(Map<String, dynamic> tier, bool isUnlocked, int validRef, int reqRef) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: isUnlocked ? AppColors.goldPremium : Colors.white.withOpacity(0.8), width: isUnlocked ? 2 : 1.5), 
        boxShadow: [BoxShadow(color: (isUnlocked ? AppColors.goldPremium : AppColors.shadowBlue).withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))]
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isUnlocked ? Icons.lock_open : Icons.lock, color: isUnlocked ? AppColors.goldPremium : AppColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Text(tier['tier_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.navyActive)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: isUnlocked ? AppColors.goldPremium.withOpacity(0.15) : AppColors.lightGray, borderRadius: BorderRadius.circular(20)),
                      child: Text('$reqRef Referral', style: TextStyle(color: isUnlocked ? AppColors.goldPremium : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                
                if (!isUnlocked) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: validRef/reqRef, backgroundColor: AppColors.lightGray, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.textSecondary), minHeight: 6, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 8),
                  Text('Kurang ${reqRef - validRef} referral valid lagi', style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: AppColors.border, height: 1)),
                
                ...List.generate(tier['rewards'].length, (i) {
                  return _buildBarisHadiah(tier['rewards'][i], isUnlocked);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarisHadiah(Map<String, dynamic> reward, bool isUnlocked) {
    String claimStatus = reward['claim_status'] ?? '';
    bool canClaim = reward['can_claim'] ?? false;
    
    Widget actionWidget;

    if (claimStatus == 'APPROVED' || claimStatus == 'COMPLETED') {
      actionWidget = Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: Text('Selesai', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)));
    } else if (claimStatus == 'PENDING' || claimStatus == 'PROCESSING') {
      actionWidget = Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)), child: Text('Diproses', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 12)));
    } else if (canClaim) {
      actionWidget = ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPremium, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
        onPressed: () => _klaimHadiah(reward['referral_tier_reward_id'].toString()),
        child: const Text('KLAIM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      );
    } else {
      actionWidget = const Icon(Icons.lock_outline, color: AppColors.border);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isUnlocked ? AppColors.goldPremium.withOpacity(0.15) : AppColors.lightGray, shape: BoxShape.circle),
            child: Icon(reward['reward_type'] == 'PHYSICAL_GIFT' ? Icons.redeem : Icons.event_available, color: isUnlocked ? AppColors.goldPremium : AppColors.textSecondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward['reward_name'], style: TextStyle(fontWeight: FontWeight.w900, color: isUnlocked ? AppColors.navyActive : AppColors.textSecondary, fontSize: 14)),
                if (reward['reward_description'] != null)
                  Text(reward['reward_description'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          actionWidget,
        ],
      ),
    );
  }
}
