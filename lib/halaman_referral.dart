import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/referral_service.dart';
import 'tema.dart';
import 'halaman_riwayat_referral.dart';
import 'halaman_hadiah_referral.dart';

class HalamanReferral extends StatefulWidget {
  const HalamanReferral({Key? key}) : super(key: key);

  @override
  _HalamanReferralState createState() => _HalamanReferralState();
}

class _HalamanReferralState extends State<HalamanReferral> {
  final Color navy = const Color(0xFF0F172A);
  final Color emerald = const Color(0xFF10B981);
  final Color gold = const Color(0xFFD4AF37);
  final ReferralService _referralService = ReferralService();

  Map<String, dynamic>? dataSummary;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatDataSummary();
  }

  Future<void> _muatDataSummary() async {
    try {
      final data = await _referralService.getSummary();
      setState(() {
        dataSummary = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _salinKeClipboard(String teks, String jenis) {
    Clipboard.setData(ClipboardData(text: teks));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$jenis berhasil disalin!'), backgroundColor: emerald));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Referral Program', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: navy),
        elevation: 0,
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKartuProgres(),
                  const SizedBox(height: 24),
                  _buildKartuKode(),
                  const SizedBox(height: 24),
                  
                  // Navigasi ke Riwayat & Hadiah
                  Row(
                    children: [
                      Expanded(child: _buildTombolAksi('Riwayat Referral', Icons.history, () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanRiwayatReferral()));
                      })),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTombolAksi('Hadiah Saya', Icons.card_giftcard, () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanHadiahReferral()));
                      })),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKartuProgres() {
    final int valid = dataSummary?['valid_referrals'] ?? 0;
    final int target = dataSummary?['next_target'] ?? 10;
    final int sisa = dataSummary?['remaining'] ?? 0;
    final double progres = target > 0 ? (valid / target) : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.card_giftcard, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Program Referral', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Ajak teman, dapatkan hadiah', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          const Text('Referral valid kamu', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$valid', style: TextStyle(color: gold, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('dari $target referral', style: const TextStyle(color: Colors.white70, fontSize: 14, padding: EdgeInsets.only(bottom: 4))),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progres, backgroundColor: Colors.white24, valueColor: AlwaysStoppedAnimation<Color>(emerald), minHeight: 8, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          Text(sisa > 0 ? 'Tinggal $sisa referral valid untuk mencapai tingkat berikutnya.' : 'Target tingkat maksimum tercapai!', style: const TextStyle(color: Colors.white, fontSize: 12)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white24, height: 1)),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [Icon(Icons.people_outline, color: Colors.cyan, size: 16), SizedBox(width: 6), Text('Total undangan', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                    const SizedBox(height: 4),
                    Text('${dataSummary?['total_invites'] ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.military_tech, color: gold, size: 16), const SizedBox(width: 6), const Text('Hadiah diperoleh', style: TextStyle(color: Colors.white70, fontSize: 12))]),
                    const SizedBox(height: 4),
                    Text('${dataSummary?['rewards_claimed'] ?? 0} tingkat', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    final String kode = dataSummary?['referral_code'] ?? '-';
    final String tautan = 'https://smartkasir.id/ref/$kode';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kode Referral Saya', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Bagikan kode atau tautan ini kepada calon pengguna Smart Kasir.', style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 20),
          
          const Text('KODE REFERRAL', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(kode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)))),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _salinKeClipboard(kode, 'Kode Referral'),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Salin'),
                style: OutlinedButton.styleFrom(foregroundColor: navy, side: BorderSide(color: navy)),
              )
            ],
          ),
          
          const SizedBox(height: 20),
          const Text('TAUTAN UNDANGAN', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(tautan, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.blue)))),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _salinKeClipboard(tautan, 'Tautan'),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Salin'),
                style: OutlinedButton.styleFrom(foregroundColor: navy, side: BorderSide(color: navy)),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTombolAksi(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: navy, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
