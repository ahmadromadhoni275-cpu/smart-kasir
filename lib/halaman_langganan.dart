import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

class HalamanLangganan extends StatefulWidget {
  const HalamanLangganan({super.key});

  @override
  State<HalamanLangganan> createState() => _HalamanLanggananState();
}

class _HalamanLanggananState extends State<HalamanLangganan> {
  final String baseUrl = 'https://smartkasir.shop/api';
  List paketLangganan = [];
  String rekeningTujuan = '-';
  bool isLoading = true;
  int tokoId = 1;

  @override
  void initState() {
    super.initState();
    _ambilDaftarPaket();
  }

 Future<void> _ambilDaftarPaket() async {
    final prefs = await SharedPreferences.getInstance();
    tokoId = prefs.getInt('toko_id') ?? 1;

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/getPaketLangganan'), 
        headers: {'ngrok-skip-browser-warning': 'true'}
      );
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          paketLangganan = data['data'];
          rekeningTujuan = data['rekening_tujuan'] ?? '-';
          isLoading = false;
        });
      } else {
        // --- BAGIAN INI DITAMBAHKAN AGAR LOADING BERHENTI SAAT ERROR ---
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Gagal mengambil data paket. Status API: ${res.statusCode}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal terhubung ke server: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  String _formatRp(int angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  // DIALOG PEMBAYARAN MANUAL
  void _tampilDialogManual(Map paket) async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;
    Uint8List fileBytes = await pickedFile.readAsBytes();

    // ignore: use_build_context_synchronously
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/beliPaket'));
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.fields['toko_id'] = tokoId.toString();
      request.fields['paket_id'] = paket['id'].toString();
      request.fields['metode'] = 'manual';
      request.files.add(http.MultipartFile.fromBytes('bukti_bayar', fileBytes, filename: pickedFile.name));

      var streamedResponse = await request.send();
      Navigator.pop(context); // tutup loading

      if (streamedResponse.statusCode == 201) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bukti berhasil dikirim. Menunggu verifikasi admin pusat!'), backgroundColor: Colors.green));
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim bukti bayar.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  // DIALOG METODE PEMBAYARAN
  void _pilihMetodePembayaran(Map paket) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pilih Metode Pembayaran', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Total Tagihan: ${_formatRp(int.parse(paket['harga'].toString()))}', style: const TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.green),
                title: const Text('Pembayaran Otomatis (QRIS/VA)'),
                subtitle: const Text('Aktif detik itu juga (Otomatis)'),
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Membuka Payment Gateway...')));
                  // Logic pindah ke WebView / Midtrans akan diisi di sini
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.receipt, color: Colors.orange),
                title: const Text('Transfer Manual'),
                subtitle: Text('Transfer ke: $rekeningTujuan'),
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  Navigator.pop(context);
                  _tampilDialogManual(paket);
                },
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perpanjang Langganan'), backgroundColor: Colors.purple),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: paketLangganan.length,
            itemBuilder: (context, index) {
              var paket = paketLangganan[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(paket['nama_paket'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(paket['keterangan'] ?? '', style: const TextStyle(color: Colors.grey)),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatRp(int.parse(paket['harga'].toString())), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            onPressed: () => _pilihMetodePembayaran(paket),
                            child: const Text('Beli Paket', style: TextStyle(color: Colors.white)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}
