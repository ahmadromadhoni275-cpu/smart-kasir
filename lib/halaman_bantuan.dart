import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'tema.dart'; // Import tema premium kita

class HalamanBantuan extends StatefulWidget {
  const HalamanBantuan({super.key});

  @override
  State<HalamanBantuan> createState() => _HalamanBantuanState();
}

class _HalamanBantuanState extends State<HalamanBantuan> {
  // Ganti dengan nomor WA dan Email Support Asli Anda
  final String _nomorWaSupport = "6281234567890"; 
  final String _emailSupport = "support@smartkasir.shop";

  // Daftar Pertanyaan FAQ
  final List<Map<String, String>> _faqData = [
    {
      'tanya': 'Bagaimana cara menghubungkan printer Bluetooth?',
      'jawab': '1. Nyalakan Bluetooth di HP Anda dan pastikan Printer sudah menyala.\n2. Lakukan "Pairing" (Sandingkan) printer di pengaturan Bluetooth HP (Biasanya password: 0000 atau 1234).\n3. Buka menu "Printer Bluetooth" di aplikasi Smart Kasir, lalu pilih nama printer Anda.'
    },
    {
      'tanya': 'Mengapa stok barang saya tidak berkurang saat transaksi?',
      'jawab': 'Pastikan saat Anda menambahkan produk, opsi "Jenis" diatur sebagai "Barang". Jika diatur sebagai "Jasa", sistem tidak akan mengurangi stok karena jasa tidak memiliki fisik.'
    },
    {
      'tanya': 'Bagaimana cara membuka shift kasir?',
      'jawab': 'Jika fitur Shift aktif, sistem akan otomatis memunculkan pop-up "Buka Shift" saat Anda masuk ke Halaman Kasir pertama kali. Masukkan uang modal awal yang ada di laci kasir Anda, lalu tekan Buka Shift.'
    },
    {
      'tanya': 'Saya Admin, bagaimana cara memperpanjang langganan?',
      'jawab': 'Buka menu "Menu ⋮" di pojok kanan bawah, lalu pilih "Langganan Sistem". Pilih paket yang Anda inginkan, lakukan pembayaran, dan unggah bukti transfer. Masa aktif akan otomatis bertambah setelah diverifikasi pusat.'
    },
    {
      'tanya': 'Bisakah saya menggunakan aplikasi ini tanpa internet?',
      'jawab': 'Untuk saat ini, Smart Kasir membutuhkan koneksi internet (Online) agar data transaksi dan stok selalu sinkron secara real-time antara kasir dan admin pemilik toko.'
    },
  ];

  // ==========================================
  // FUNGSI KONTAK EXTERNAL
  // ==========================================
  Future<void> _hubungiWhatsApp() async {
    final String pesan = Uri.encodeComponent("Halo Admin Smart Kasir, saya butuh bantuan terkait aplikasi...");
    final Uri url = Uri.parse("https://wa.me/$_nomorWaSupport?text=$pesan");
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _tampilkanNotif('Gagal membuka WhatsApp.');
      }
    } catch (e) {
      _tampilkanNotif('Terjadi kesalahan saat membuka WhatsApp.');
    }
  }

  Future<void> _kirimEmail() async {
    final Uri url = Uri.parse("mailto:$_emailSupport?subject=Bantuan%20Smart%20Kasir&body=Halo%20Admin,%20saya%20butuh%20bantuan...");
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _tampilkanNotif('Gagal membuka aplikasi Email.');
      }
    } catch (e) {
      _tampilkanNotif('Terjadi kesalahan saat membuka Email.');
    }
  }

  void _tampilkanNotif(String pesan) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ==========================================
  // WIDGET UTAMA (BODY)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        title: const Text('Pusat Bantuan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER BANNER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.support_agent, size: 50, color: AppColors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text('Ada yang bisa kami bantu?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                  const SizedBox(height: 5),
                  Text('Pilih menu di bawah ini untuk menemukan solusi', style: TextStyle(fontSize: 13, color: AppColors.white.withOpacity(0.7))),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- KARTU KONTAK LANGSUNG ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hubungi Layanan Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKartuKontak(
                          judul: 'Chat WhatsApp',
                          deskripsi: 'Balasan Cepat',
                          ikon: Icons.chat, // Native Flutter icon
                          warnaBg: AppColors.emerald,
                          onTap: _hubungiWhatsApp,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildKartuKontak(
                          judul: 'Kirim Email',
                          deskripsi: 'Lampirkan File',
                          ikon: Icons.email,
                          warnaBg: AppColors.smartBlue,
                          onTap: _kirimEmail,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- FAQ (PERTANYAAN UMUM) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pertanyaan Umum (FAQ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText)),
                  const SizedBox(height: 15),
                  
                  // Generate List FAQ
                  ..._faqData.map((faq) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          iconColor: AppColors.teal,
                          collapsedIconColor: AppColors.slateGray,
                          title: Text(faq['tanya']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkText)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                              child: Text(
                                faq['jawab']!,
                                style: const TextStyle(fontSize: 12, color: AppColors.slateGray, height: 1.5),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                  
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Komponen Kartu Kontak
  Widget _buildKartuKontak({required String judul, required String deskripsi, required IconData ikon, required Color warnaBg, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: warnaBg.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(ikon, color: warnaBg, size: 24),
            ),
            const SizedBox(height: 15),
            Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkText)),
            const SizedBox(height: 4),
            Text(deskripsi, style: const TextStyle(fontSize: 10, color: AppColors.slateGray)),
          ],
        ),
      ),
    );
  }
}
