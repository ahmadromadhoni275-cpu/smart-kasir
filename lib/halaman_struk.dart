import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform, Socket; 
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img; 

class HalamanStruk extends StatefulWidget {
  final List keranjang;
  final dynamic totalBelanja;
  final dynamic subtotal;
  final dynamic ppnNominal;
  final dynamic biayaJasa;
  final dynamic uangDiterima;
  final dynamic uangKembalian;
  final String noStruk;
  final String tanggal;
  final String metodePembayaran;
  final String? noMeja; 

  const HalamanStruk({
    super.key,
    required this.keranjang,
    required this.totalBelanja,
    required this.subtotal,
    required this.ppnNominal,
    required this.biayaJasa,
    required this.uangDiterima,
    required this.uangKembalian,
    required this.noStruk,
    required this.tanggal,
    required this.metodePembayaran,
    this.noMeja, 
  });

  @override
  State<HalamanStruk> createState() => _HalamanStrukState();
}

class _HalamanStrukState extends State<HalamanStruk> {
  final String domainUrl = 'https://smartkasir.shop';

  String namaToko = 'Nama Toko';
  String alamatToko = 'Alamat Toko';
  String waToko = '-';
  String namaBank = '';
  String rekeningBank = '';
  String atasNama = '';
  String qrQrisPath = ''; 

  String namaPetugas = 'Kasir/Admin';
  String waSuperadmin = 'Memuat...';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    await _muatDataTokoDanPetugas();
    await _ambilWaSuperadmin();
    setState(() => isLoading = false);
  }

  Future<void> _ambilWaSuperadmin() async {
    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/pengaturan'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() => waSuperadmin = res['data']['wa_superadmin'] ?? '081234567890');
      } else {
        setState(() => waSuperadmin = '081234567890');
      }
    } catch (e) {
      setState(() => waSuperadmin = '081234567890');
    }
  }

  Future<void> _muatDataTokoDanPetugas() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaPetugas = prefs.getString('nama') ?? prefs.getString('username') ?? 'Kasir/Admin';
    });

    int tokoId = prefs.getInt('toko_id') ?? 1;

    try {
      final response = await http.get(Uri.parse('$domainUrl/api/toko/$tokoId'),
          headers: {'ngrok-skip-browser-warning': 'true'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          namaToko = data['nama_toko'] ?? 'Toko Saya';
          alamatToko = data['alamat'] ?? 'Jl. Raya No. 1';
          waToko = data['no_hp'] ?? '-';
          namaBank = data['nama_bank'] ?? '';
          rekeningBank = data['rekening_bank'] ?? '';
          atasNama = data['atas_nama'] ?? '';
          qrQrisPath = data['qr_qris'] ?? ''; 
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat profil toko: $e");
    }
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _formatRp(dynamic angka) {
    int nilai = _parseInt(angka);
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(nilai);
  }

  Future<void> _kirimWhatsApp() async {
    int subtotalVal = _parseInt(widget.subtotal);
    int jasaVal = _parseInt(widget.biayaJasa);
    int ppnVal = _parseInt(widget.ppnNominal);
    int totalVal = _parseInt(widget.totalBelanja);
    int tunaiVal = _parseInt(widget.uangDiterima);
    int kembaliVal = _parseInt(widget.uangKembalian);

    String pesan = "*STRUK BELANJA*\n";
    pesan += "*${namaToko.toUpperCase()}*\n";
    pesan += "$alamatToko\n";
    pesan += "WA: $waToko\n";
    pesan += "--------------------------------------\n";
    pesan += "No. : ${widget.noStruk}\n";
    pesan += "Tgl : ${widget.tanggal}\n";
    if (widget.noMeja != null && widget.noMeja!.isNotEmpty) {
      pesan += "Meja: ${widget.noMeja}\n";
    }
    pesan += "Oleh : $namaPetugas\n";
    pesan += "Bayar : ${widget.metodePembayaran}\n";
    pesan += "--------------------------------------\n";

    for (var item in widget.keranjang) {
      String namaItem = item['nama']?.toString() ?? 'Produk';
      // MENGAMBIL DATA TIPE PESANAN (DINE IN / TAKEAWAY)
      String tipePesanan = item['tipe_pesanan'] != null ? " [${item['tipe_pesanan']}]" : "";
      
      int itemHarga = _parseInt(item['harga']);
      int itemQty = _parseInt(item['qty']);
      int itemSub = _parseInt(item['subtotal']);
      if (itemSub == 0 && itemHarga > 0 && itemQty > 0) {
        itemSub = itemHarga * itemQty;
      }
      pesan += "$namaItem$tipePesanan\n";
      pesan += "$itemQty x ${_formatRp(itemHarga)} = ${_formatRp(itemSub)}\n";
    }

    pesan += "--------------------------------------\n";
    pesan += "Subtotal : ${_formatRp(subtotalVal)}\n";
    if (jasaVal > 0) pesan += "Biaya Jasa : ${_formatRp(jasaVal)}\n";
    if (ppnVal > 0) pesan += "PPN : ${_formatRp(ppnVal)}\n";
    pesan += "*Total : ${_formatRp(totalVal)}*\n";

    if (widget.metodePembayaran == 'Tunai') {
      pesan += "Tunai : ${_formatRp(tunaiVal)}\n";
      pesan += "Kembali : ${_formatRp(kembaliVal)}\n";
    } else {
      pesan += "\n*💳 INFO PEMBAYARAN NON-TUNAI:*\n";
      pesan += "Bank : $namaBank\n";
      pesan += "No. Rek : $rekeningBank\n";
      pesan += "A/N : $atasNama\n";
    }
    pesan += "--------------------------------------\n\n";
    pesan += "Terima kasih telah berbelanja di *${namaToko.toUpperCase()}*! 😊\n\n";
    pesan += "🚀 _Kasir rapi, omset meroket bersama *Smart Kasir*_!\n";
    pesan += "_Buat toko Anda makin profesional. Hubungi admin kami di WA: *$waSuperadmin*_ 😉";

    String textEncoded = Uri.encodeComponent(pesan);
    final Uri waUrl = Uri.parse("https://wa.me/?text=$textEncoded");

    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuka WhatsApp.'), backgroundColor: Colors.red));
    }
  }

  // ==============================================================
  // MESIN MULTI-PRINTER HYBRID (Wi-Fi & Bluetooth & Split Bill)
  // ==============================================================

  Future<void> _mulaiProsesCetak() async {
    if (kIsWeb) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cetak fisik tidak bisa dilakukan di Web.'), backgroundColor: Colors.orange));
      return;
    }
    if (Platform.isIOS) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printer kasir tidak didukung di iOS.'), backgroundColor: Colors.orange));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String alamatUtama = prefs.getString('printer_alamat_utama') ?? '';

    if (alamatUtama.isEmpty) {
      _tampilkanDialogPilihPrinterBluetoothLama(); 
    } else {
      _eksekusiMultiPrinter(prefs); 
    }
  }

  Future<void> _eksekusiMultiPrinter(SharedPreferences prefs) async {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memproses cetak ke berbagai rute...'), backgroundColor: Colors.blueAccent));

    List<int> bytesUtama = await _generateBytesStrukLengkap();
    await _kirimDataKePrinter(prefs, 'utama', bytesUtama, 'Kasir');

    Map<String, List<dynamic>> pesananDivisi = {};
    for (var item in widget.keranjang) {
      String? catId = item['kategori_id']?.toString();
      if (catId != null && catId.isNotEmpty && catId != 'null') {
        if (!pesananDivisi.containsKey(catId)) {
          pesananDivisi[catId] = [];
        }
        pesananDivisi[catId]!.add(item);
      }
    }

    for (var catId in pesananDivisi.keys) {
      List<int> bytesDivisi = await _generateBytesStrukDivisi(pesananDivisi[catId]!);
      await _kirimDataKePrinter(prefs, 'cat_$catId', bytesDivisi, 'Divisi $catId');
    }
  }

  Future<void> _kirimDataKePrinter(SharedPreferences prefs, String idSlot, List<int> bytes, String namaRute) async {
    String tipe = prefs.getString('printer_tipe_$idSlot') ?? 'bluetooth';
    String alamat = prefs.getString('printer_alamat_$idSlot') ?? '';

    if (alamat.isEmpty) return; 

    try {
      if (tipe == 'wifi') {
        Socket socket = await Socket.connect(alamat, 9100, timeout: const Duration(seconds: 5));
        socket.add(bytes);
        await socket.flush();
        socket.destroy();
      } else {
        await PrintBluetoothThermal.connect(macPrinterAddress: alamat);
        await PrintBluetoothThermal.writeBytes(bytes);
      }
    } catch (e) {
      debugPrint("Gagal cetak rute $namaRute: $e");
    }
  }

  Future<List<int>> _generateBytesStrukLengkap() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text(namaToko.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(alamatToko, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("WA: $waToko", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: "No: ${widget.noStruk}", width: 6),
      PosColumn(text: "Tgl: ${widget.tanggal}", width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (widget.noMeja != null && widget.noMeja!.isNotEmpty) {
      bytes += generator.text("MEJA: ${widget.noMeja}", styles: const PosStyles(bold: true));
    }
    bytes += generator.row([
      PosColumn(text: "Kasir: $namaPetugas", width: 6),
      PosColumn(text: "Bayar: ${widget.metodePembayaran}", width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    for (var item in widget.keranjang) {
      String namaItem = item['nama']?.toString() ?? 'Produk';
      String tipePesanan = item['tipe_pesanan'] != null ? " [${item['tipe_pesanan']}]" : "";
      
      int itemHarga = _parseInt(item['harga']);
      int itemQty = _parseInt(item['qty']);
      int itemSub = _parseInt(item['subtotal']);
      if (itemSub == 0 && itemHarga > 0 && itemQty > 0) itemSub = itemHarga * itemQty;

      bytes += generator.text(namaItem + tipePesanan, styles: const PosStyles(align: PosAlign.left));
      bytes += generator.row([
        PosColumn(text: "$itemQty x ${_formatRp(itemHarga)}", width: 6),
        PosColumn(text: _formatRp(itemSub), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    if (_parseInt(widget.biayaJasa) > 0) {
      bytes += generator.row([
        PosColumn(text: "Biaya", width: 6),
        PosColumn(text: _formatRp(widget.biayaJasa), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    if (_parseInt(widget.ppnNominal) > 0) {
      bytes += generator.row([
        PosColumn(text: "PPN", width: 6),
        PosColumn(text: _formatRp(widget.ppnNominal), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: _formatRp(widget.totalBelanja), width: 6, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);

    if (widget.metodePembayaran == 'Tunai') {
      bytes += generator.row([
        PosColumn(text: "Tunai", width: 6),
        PosColumn(text: _formatRp(widget.uangDiterima), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: "Kembali", width: 6),
        PosColumn(text: _formatRp(widget.uangKembalian), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    } else {
      bytes += generator.text("Pembayaran Non-Tunai:", styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text("$namaBank - $rekeningBank", styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text("A/N: $atasNama", styles: const PosStyles(align: PosAlign.left));

      if (qrQrisPath.isNotEmpty) {
        try {
          final resImg = await http.get(Uri.parse('$domainUrl/$qrQrisPath'));
          if (resImg.statusCode == 200) {
            img.Image? originalImage = img.decodeImage(resImg.bodyBytes);
            if (originalImage != null) {
              img.Image resized = img.copyResize(originalImage, width: 300);
              bytes += generator.feed(1);
              bytes += generator.text("SCAN QRIS DI BAWAH INI", styles: const PosStyles(align: PosAlign.center, bold: true));
              bytes += generator.imageRaster(resized, align: PosAlign.center);
            }
          }
        } catch(e) {
          debugPrint("Gagal memuat gambar QR: $e");
        }
      }
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    bytes += generator.text("Terima kasih telah berbelanja", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("di ${namaToko.toUpperCase()}! :-)", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    bytes += generator.text("---", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Kasir rapi, omset meroket", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("bersama SMART KASIR!", styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(2);

    return bytes;
  }

  Future<List<int>> _generateBytesStrukDivisi(List items) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text("TIKET PESANAN", styles: const PosStyles(align: PosAlign.center, bold: true, width: PosTextSize.size2, height: PosTextSize.size2));
    bytes += generator.feed(1);
    bytes += generator.text("No: ${widget.noStruk}", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Waktu: ${widget.tanggal.split(' ')[1]}", styles: const PosStyles(align: PosAlign.center)); 

    if (widget.noMeja != null && widget.noMeja!.isNotEmpty) {
      bytes += generator.feed(1);
      bytes += generator.text("MEJA: ${widget.noMeja}", styles: const PosStyles(align: PosAlign.center, bold: true, width: PosTextSize.size2, height: PosTextSize.size2));
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    for (var item in items) {
      String namaItem = item['nama']?.toString() ?? 'Produk';
      String tipePesanan = item['tipe_pesanan'] != null ? " [${item['tipe_pesanan']}]" : "";
      int itemQty = _parseInt(item['qty']);
      
      bytes += generator.text("$itemQty x $namaItem$tipePesanan", styles: const PosStyles(bold: true, width: PosTextSize.size2));
      bytes += generator.feed(1);
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    return bytes;
  }

  Future<void> _tampilkanDialogPilihPrinterBluetoothLama() async {
    try {
      List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Pilih Printer Bluetooth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                height: 300,
                width: 300,
                child: devices.isEmpty
                    ? const Center(child: Text("Belum ada perangkat terpasang (paired).", textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.print, color: Colors.blueAccent),
                            title: Text(devices[index].name),
                            subtitle: Text(devices[index].macAdress),
                            onTap: () async {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Menghubungkan ke ${devices[index].name}...')));
                              try {
                                bool terhubung = await PrintBluetoothThermal.connect(macPrinterAddress: devices[index].macAdress);
                                if (terhubung) {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('printer_tipe_utama', 'bluetooth');
                                  await prefs.setString('printer_alamat_utama', devices[index].macAdress);
                                  _eksekusiMultiPrinter(prefs);
                                }
                              } catch (e) {
                                debugPrint("Error koneksi: $e");
                              }
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.red)))
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint("Error dialog bluetooth: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    int subtotalVal = _parseInt(widget.subtotal);
    int jasaVal = _parseInt(widget.biayaJasa);
    int ppnVal = _parseInt(widget.ppnNominal);
    int totalVal = _parseInt(widget.totalBelanja);
    int tunaiVal = _parseInt(widget.uangDiterima);
    int kembaliVal = _parseInt(widget.uangKembalian);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Detail Struk Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.grey.withAlpha(50), blurRadius: 10, spreadRadius: 2)],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 50),
                            const SizedBox(height: 5),
                            const Text('Transaksi Berhasil!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('No: ${widget.noStruk}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            if (widget.noMeja != null && widget.noMeja!.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                                child: Text('Meja: ${widget.noMeja}', style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                              )
                          ],
                        ),
                      ),
                      const Divider(height: 25, thickness: 1),
                      const Text('Rincian Belanja:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 5),
                      if (widget.keranjang.isNotEmpty)
                        ...widget.keranjang.map((item) {
                          String namaItem = item['nama']?.toString() ?? 'Produk';
                          String tipePesanan = item['tipe_pesanan'] != null ? " [${item['tipe_pesanan']}]" : "";
                          int itemHarga = _parseInt(item['harga']);
                          int itemQty = _parseInt(item['qty']);
                          int itemSub = _parseInt(item['subtotal']);

                          if (itemSub == 0 && itemHarga > 0 && itemQty > 0) itemSub = itemHarga * itemQty;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text("$namaItem$tipePesanan (${itemQty}x)", style: const TextStyle(fontSize: 13))),
                                Text(_formatRp(itemSub), style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          );
                        })
                      else
                        const Text('Tidak ada item', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const Divider(height: 25, thickness: 1),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text(_formatRp(subtotalVal))]),
                      if (jasaVal > 0) ...[const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Biaya Jasa'), Text(_formatRp(jasaVal))])],
                      if (ppnVal > 0) ...[const SizedBox(height: 4), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('PPN Otomatis'), Text(_formatRp(ppnVal))])],
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Belanja', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(_formatRp(totalVal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent))
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Pembayaran'), Text(widget.metodePembayaran, style: const TextStyle(fontWeight: FontWeight.bold))]),
                      const SizedBox(height: 4),
                      if (widget.metodePembayaran == 'Tunai') ...[
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tunai'), Text(_formatRp(tunaiVal))]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kembalian'), Text(_formatRp(kembaliVal), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Transfer / QRIS Ke:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                              Text('$namaBank - $rekeningBank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('a/n $atasNama', style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        )
                      ],
                      Divider(height: 25, thickness: 1, color: Colors.grey.shade400),
                      Center(child: Text('Kasir/Admin: $namaPetugas', style: const TextStyle(color: Colors.grey, fontSize: 11))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _mulaiProsesCetak, 
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Cetak Fisik', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _kirimWhatsApp,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Kirim WA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Transaksi Baru', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
            )
          ],
        ),
      ),
    );
  }
}
