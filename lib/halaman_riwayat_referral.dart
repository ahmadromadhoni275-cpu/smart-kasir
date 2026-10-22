import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart';
import 'core/services/referral_service.dart';

class HalamanRiwayatReferral extends StatefulWidget {
  const HalamanRiwayatReferral({Key? key}) : super(key: key);

  @override
  _HalamanRiwayatReferralState createState() => _HalamanRiwayatReferralState();
}

class _HalamanRiwayatReferralState extends State<HalamanRiwayatReferral> {
  final Color navy = const Color(0xFF0F172A);
  final ReferralService _referralService = ReferralService();
  
  List<dynamic> listRiwayat = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    try {
      final data = await _referralService.getHistory();
      setState(() {
        listRiwayat = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<dynamic> _filterData(String? statusFilter) {
    if (statusFilter == null) return listRiwayat;
    return listRiwayat.where((item) => item['status'] == statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text('Riwayat Undangan', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: navy),
          elevation: 0,
          bottom: TabBar(
            labelColor: navy,
            unselectedLabelColor: Colors.grey,
            indicatorColor: navy,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Semua'),
              Tab(text: 'Menunggu'),
              Tab(text: 'Valid'),
              Tab(text: 'Ditolak'),
            ],
          ),
        ),
        body: isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : TabBarView(
                children: [
                  _buildList(_filterData(null)),
                  _buildList(_filterData('PENDING')),
                  _buildList(_filterData('QUALIFIED')),
                  _buildList(_filterData('REJECTED')),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<dynamic> dataFiltered) {
    if (dataFiltered.isEmpty) {
      return const Center(child: Text('Belum ada data referral.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dataFiltered.length,
      itemBuilder: (context, index) {
        final item = dataFiltered[index];
        final status = item['status'] ?? 'PENDING';
        
        // Penyesuaian Deskripsi berdasarkan Status
        String deskripsi = 'Pendaftaran selesai, menunggu syarat program terpenuhi.';
        if (status == 'QUALIFIED') deskripsi = 'Pembayaran pertama telah diverifikasi.';
        if (status == 'REJECTED') deskripsi = item['rejection_reason'] ?? 'Tidak memenuhi ketentuan program.';

        // Format Tanggal
        DateTime dt = DateTime.parse(item['created_at']);
        String tanggalStr = DateFormat('dd MMM yyyy').format(dt);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['referred_name'] ?? 'Pengguna Anonim', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    _buildBadgeStatus(status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item['referred_email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(deskripsi, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4))),
                  ],
                ),
                const Divider(height: 24),
                Text('Bergabung: $tanggalStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeStatus(String status) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey.shade700;
    String label = 'Menunggu';

    if (status == 'QUALIFIED') {
      bg = Colors.green.shade50;
      text = Colors.green.shade700;
      label = 'Valid';
    } else if (status == 'REJECTED') {
      bg = Colors.red.shade50;
      text = Colors.red.shade700;
      label = 'Ditolak';
    } else if (status == 'PENDING') {
      bg = Colors.orange.shade50;
      text = Colors.orange.shade700;
      label = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
