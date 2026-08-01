import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HalamanBantuan extends StatefulWidget {
  const HalamanBantuan({super.key});

  @override
  State<HalamanBantuan> createState() => _HalamanBantuanState();
}

class _HalamanBantuanState extends State<HalamanBantuan> {
  final TextEditingController _pesanCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // --- SESUAIKAN NOMOR WA INI ---
  // Gunakan format 62 tanpa tanda + atau awalan 0
  final String noWaSuperadmin = '6281234567890'; 

  List<Map<String, dynamic>> riwayatChat = [
    {
      'pengirim': 'bot',
      'pesan':
          'Halo! Saya asisten virtual Smart Kasir. Ada yang bisa saya bantu hari ini?\n\nKetik kata kunci seperti:\n- "Lupa Password"\n- "Perpanjang"\n- "Printer Error"',
      'tampilkanTombolWa': false
    }
  ];

  void _kirimPesan() {
    String teks = _pesanCtrl.text.trim();
    if (teks.isEmpty) return;

    setState(() {
      // 1. Masukkan pesan pengguna
      riwayatChat.add({
        'pengirim': 'user', 
        'pesan': teks, 
        'tampilkanTombolWa': false
      });
      _pesanCtrl.clear();
    });

    _gulirKeBawah();

    // 2. Simulasikan bot sedang mengetik
    Future.delayed(const Duration(seconds: 1), () {
      _balasPesanBot(teks.toLowerCase());
    });
  }

  void _balasPesanBot(String pertanyaan) {
    String balasan = '';
    bool butuhBantuanAdmin = false;

    // --- LOGIKA CERDAS CHATBOT (IF-ELSE KATA KUNCI) ---
    if (pertanyaan.contains('lupa') && pertanyaan.contains('password')) {
      balasan =
          'Untuk mereset password kasir, Anda bisa masuk menggunakan akun Admin, lalu ke menu "Pegawai" dan ubah data kasir di sana.';
    } else if (pertanyaan.contains('perpanjang') ||
        pertanyaan.contains('langganan') ||
        pertanyaan.contains('bayar')) {
      balasan =
          'Untuk memperpanjang masa aktif, silakan masuk ke menu Pengaturan Toko -> Klik tombol "Perpanjang Langganan", lalu pilih metode pembayaran otomatis melalui QRIS atau Virtual Account.';
    } else if (pertanyaan.contains('printer') ||
        pertanyaan.contains('cetak') ||
        pertanyaan.contains('struk')) {
      balasan =
          'Pastikan printer thermal bluetooth Anda sudah menyala dan tersambung dengan Bluetooth HP Anda. Lalu tekan "Buka Menu Cetak" di Beranda.';
    } else {
      // JIKA BOT TIDAK MENGERTI
      balasan =
          'Maaf, saya belum menemukan solusi untuk kendala tersebut. \n\nJangan khawatir! Tim Support (Admin Pusat) kami siap membantu Anda secara langsung.';
      butuhBantuanAdmin = true;
    }

    setState(() {
      riwayatChat.add({
        'pengirim': 'bot',
        'pesan': balasan,
        'tampilkanTombolWa': butuhBantuanAdmin
      });
    });

    _gulirKeBawah();
  }

  void _gulirKeBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeOut
        );
      }
    });
  }

  // --- FUNGSI MENGARAHKAN KE WHATSAPP ---
  Future<void> _hubungiAdminWA() async {
    final Uri url = Uri.parse(
        'https://wa.me/$noWaSuperadmin?text=Halo%20Admin%20Pusat,%20saya%20butuh%20bantuan%20terkait%20aplikasi%20kasir.');
    
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Bantuan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(15),
              itemCount: riwayatChat.length,
              itemBuilder: (context, index) {
                var chat = riwayatChat[index];
                bool isUser = chat['pengirim'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: isUser ? Colors.blueAccent : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 0),
                          bottomRight: Radius.circular(isUser ? 0 : 20),
                        )),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chat['pesan'],
                            style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87)),

                        // JIKA BOT MENYERAH, MUNCULKAN TOMBOL INI
                        if (chat['tampilkanTombolWa'] == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green, // Warna khas WA
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              onPressed: _hubungiAdminWA,
                              icon: const Icon(Icons.chat, color: Colors.white),
                              label: const Text('Chat Admin Pusat via WA',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // --- KOTAK INPUT PESAN ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white, 
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withAlpha(50),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
            ]),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pesanCtrl,
                    decoration: InputDecoration(
                        hintText: 'Ketik kendala Anda di sini...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10)),
                    onSubmitted: (value) => _kirimPesan(),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  radius: 25,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _kirimPesan,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
