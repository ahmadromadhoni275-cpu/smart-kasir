import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/referral_service.dart';

class HalamanHadiahReferral extends StatefulWidget {
  const HalamanHadiahReferral({Key? key}) : super(key: key);

  @override
  _HalamanHadiahReferralState createState() => _HalamanHadiahReferralState();
}

class _HalamanHadiahReferralState extends State<HalamanHadiahReferral> {
  final Color navy = const Color(0xFF0F172A);
  final Color gold = const Color(0xFFD4AF37);
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
      setState(() {
        dataRewards = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _klaimHadiah(String rewardId) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await _referralService.claimReward(rewardId);
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Klaim berhasil diajukan!'), backgroundColor: Colors.green));
      _muatHadiah(); // Refresh data
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Hadiah Saya', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: navy),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dataRewards?['tiers']?.length ?? 0,
              itemBuilder: (context, index) {
                final tier = dataRewards!['tiers'][index];
                final int validRef = dataRewards!['valid_referrals'] ?? 0;
                final int reqRef = int.parse(tier['required_referrals'].toString());
                final bool isUnlocked = validRef >= reqRef;

                return _buildKartuTier(tier, isUnlocked, validRef, reqRef);
              },
            ),
    );
  }

  Widget _buildKartuTier(Map<String, dynamic> tier, bool isUnlocked, int validRef, int reqRef) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: isUnlocked ? gold : Colors.grey.shade300, width: isUnlocked ? 2 : 1)
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(tier['tier_name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: isUnlocked ? navy : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: Text('$reqRef Referral', style: TextStyle(color: isUnlocked ? Colors.white : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (!isUnlocked)
              Text('Kurang ${reqRef - validRef} referral lagi', style: const TextStyle(color: Colors.red, fontSize: 12)),
            const Divider(height: 24),
            
            // Loop daftar hadiah di tier ini
            ...List.generate(tier['rewards'].length, (i) {
              final reward = tier['rewards'][i];
              return _buildBarisHadiah(reward, isUnlocked);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBarisHadiah(Map<String, dynamic> reward, bool isUnlocked) {
    String claimStatus = reward['claim_status'] ?? '';
    bool canClaim = reward['can_claim'] ?? false;
    
    Widget actionWidget;

    if (claimStatus == 'APPROVED' || claimStatus == 'COMPLETED') {
      actionWidget = const Text('Selesai', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    } else if (claimStatus == 'PENDING' || claimStatus == 'PROCESSING') {
      actionWidget = const Text('Menunggu\nPersetujuan', textAlign: TextAlign.right, style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold));
    } else if (canClaim) {
      actionWidget = ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: gold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        onPressed: () => _klaimHadiah(reward['referral_tier_reward_id'].toString()),
        child: const Text('Klaim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    } else {
      actionWidget = const Icon(Icons.lock_outline, color: Colors.grey);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(reward['reward_type'] == 'PHYSICAL_GIFT' ? Icons.redeem : Icons.event_available, color: isUnlocked ? gold : Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward['reward_name'], style: TextStyle(fontWeight: FontWeight.bold, color: isUnlocked ? Colors.black87 : Colors.grey)),
                if (reward['reward_description'] != null)
                  Text(reward['reward_description'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          actionWidget,
        ],
      ),
    );
  }
}
