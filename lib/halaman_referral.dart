import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class HalamanReferral extends StatefulWidget {
  const HalamanReferral({super.key});

  @override
  State<HalamanReferral> createState() => _HalamanReferralState();
}

class _HalamanReferralState extends State<HalamanReferral> {
  String referralCode = '...';
  int inviteCount = 0;
  int sisaHariMasaAktif = 0;
  String masaAktifTanggal = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Idealnya tarik data terbaru dari API (misal: /api/profil)
    // Di sini asumsi data sudah tersimpan di SharedPreferences saat login atau via API fetch
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      referralCode = prefs.getString('referral_code') ?? 'TIDAK-ADA';
      inviteCount = prefs.getInt('invite_count') ?? 0;
      
      // Hitung sisa masa aktif (contoh sederhana)
      String tglAktifStr = prefs.getString('masa_aktif') ?? DateTime.now().toIso8601String();
      DateTime masaAktif = DateTime.parse(tglAktifStr);
      sisaHariMasaAktif = masaAktif.difference(DateTime.now()).inDays;
      masaAktifTanggal = "${masaAktif.day}-${masaAktif.month}-${masaAktif.year}";
    });
  }

  @override
  Widget build(BuildContext context) {
    int targetSelanjutnya = ((inviteCount ~/ 5) + 1) * 5; 
    int sisaKurang = targetSelanjutnya - inviteCount;
    double progress = (inviteCount % 5) / 5.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Undang & Perpanjang'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.card_giftcard, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Gratis 1 Bulan Langganan!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Undang 5 teman untuk menggunakan aplikasi ini. Setiap 5 undangan berhasil, masa aktif toko Anda otomatis bertambah 30 hari.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Card Masa Aktif Saat Ini
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const Icon(Icons.timer, color: Colors.blueAccent),
                title: const Text('Masa Aktif Toko Anda'),
                subtitle: Text('Berakhir: $masaAktifTanggal'),
                trailing: Text('$sisaHariMasaAktif Hari', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
              ),
            ),
            const SizedBox(height: 30),

            // Progress Bar Undangan
            Text('Progres Anda: $inviteCount Undangan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: Colors.orange,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 10),
            Text(
              sisaKurang == 5 && inviteCount == 0 
                ? 'Belum ada undangan. Mulai bagikan sekarang!' 
                : sisaKurang == 5 
                    ? 'Target tercapai! Undang 5 lagi untuk bulan berikutnya.'
                    : 'Kurang $sisaKurang teman lagi untuk klaim gratis 1 bulan.',
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            
            const SizedBox(height: 40),
            
            // Area Kode Referal
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, style: BorderStyle.solid, width: 2),
                borderRadius: BorderRadius.circular(10)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Kode Anda: ', style: TextStyle(fontSize: 16)),
                  Text(referralCode, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15)
                ),
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('Bagikan ke WhatsApp / Sosmed', style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: () {
                  Share.share(
                    'Halo! Saya pakai Smart Kasir untuk kelola toko. Daftarkan tokomu di https://smartkasir.shop/daftar dan masukkan kode referal saya: *$referralCode* saat pendaftaran!'
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
