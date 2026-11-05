import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tema.dart';
import 'models/referral_model.dart';
import 'core/services/referral_service.dart';
import 'halaman_riwayat_referral.dart';
import 'halaman_hadiah_referral.dart';

class HalamanReferral extends StatefulWidget {
  const HalamanReferral({super.key});

  @override
  State<HalamanReferral> createState() => _HalamanReferralState();
}

class _HalamanReferralState extends State<HalamanReferral> {
  final ReferralService _referralService = ReferralService();
  ReferralSummaryModel? dataSummary;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatDataSummary();
  }

  Future<void> _muatDataSummary() async {
    setState(() => isLoading = true);
    try {
      final data = await _referralService.getSummary();
      if (mounted) setState(() => dataSummary = data);
    } catch (e) {
      debugPrint("Gagal load referral: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _salinKeClipboard(String teks, String jenis) {
    Clipboard.setData(ClipboardData(text: teks));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$jenis berhasil disalin!', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
      backgroundColor: AppColors.primaryEmerald,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Program Referral', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
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
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKartuProgres(),
                    const SizedBox(height: 24),
                    _buildKartuKode(),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(child: _buildTombolAksi('Riwayat', 'Undangan', Icons.history, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanRiwayatReferral()));
                        })),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTombolAksi('Hadiah', 'Saya', Icons.card_giftcard, () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanHadiahReferral())).then((_) => _muatDataSummary());
                        })),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildKartuProgres() {
    final sisa = dataSummary?.remaining ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.navyActive, Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.navyActive.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.goldPremium.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.stars, color: AppColors.goldPremium, size: 24)),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Program Referral', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    Text('Ajak teman & nikmati reward premium', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          
          const Text('Total Referral Valid', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${dataSummary?.validReferrals ?? 0}', style: const TextStyle(color: AppColors.goldPremium, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1)),
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('dari ${dataSummary?.nextTarget ?? 0} target terdekat', style: const TextStyle(color: Colors.white70, fontSize: 13))),
            ],
          ),
          const SizedBox(height: 16),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: dataSummary?.progress ?? 0, 
              backgroundColor: Colors.white.withOpacity(0.1), 
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldPremium), 
              minHeight: 8
            ),
          ),
          const SizedBox(height: 12),
          Text(sisa > 0 ? 'Tinggal $sisa referral valid untuk membuka tingkat berikutnya.' : 'Target tingkat maksimum tercapai! 🎉', style: const TextStyle(color: Colors.white, fontSize: 12)),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white24, height: 1)),
          
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.people_alt, color: Colors.cyanAccent, size: 16)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Undangan', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('${dataSummary?.totalInvites ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.card_giftcard, color: AppColors.primaryEmerald, size: 16)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hadiah Diklaim', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Text('${dataSummary?.rewardsClaimed ?? 0} kali', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKartuKode() {
    final String kode = dataSummary?.referralCode ?? '-';
    final String tautan = 'https://smartkasir.shop/ref/$kode';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: AppColors.navyActive, size: 20),
                  SizedBox(width: 8),
                  Text('Kode Undangan Anda', style: TextStyle(color: AppColors.navyActive, fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Bagikan kode atau tautan ini kepada kolega bisnis Anda.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 24),
              
              const Text('KODE REFERRAL', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: Text(kode, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: AppColors.navyActive)))),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _salinKeClipboard(kode, 'Kode Referral'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyActive, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(16)),
                    child: const Icon(Icons.copy, color: Colors.white),
                  )
                ],
              ),
              
              const SizedBox(height: 24),
              const Text('TAUTAN UNDANGAN (LINK)', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: Text(tautan, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold)))),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _salinKeClipboard(tautan, 'Tautan URL'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.smartBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.all(16)),
                    child: const Icon(Icons.copy, color: Colors.white),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTombolAksi(String label1, String label2, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.navyActive.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: AppColors.navyActive, size: 28)),
                const SizedBox(height: 12),
                Text(label1, style: const TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.w900, fontSize: 14)),
                Text(label2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
