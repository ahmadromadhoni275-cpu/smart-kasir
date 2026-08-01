import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- TAMBAHKAN IMPORT INI UNTUK CEK PLATFORM WEB & OS ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// IMPOR PACKAGE BLUETOOTH UNIVERSAL & FORMAT ESC/POS
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

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
  });

  @override
  State<HalamanStruk> createState() => _HalamanStrukState();
}

class _HalamanStrukState extends State<HalamanStruk> {
  // URL Domain telah disesuaikan ke hosting AnymHost Anda
  final String domainUrl = 'https://smartkasir.shop';

  String namaToko = 'Nama Toko';
  String alamatToko = 'Alamat Toko';
  String waToko = '-';
  String namaBank = '';
  String rekeningBank = '';
  String atasNama = '';

  // Variabel penampung nama
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
        setState(() =>
            waSuperadmin = res['data']['wa_superadmin'] ?? '081234567890');
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
      namaPetugas = prefs.getString('nama') ??
          prefs.getString('name') ??
          prefs.getString('nama_user') ??
          prefs.getString('username') ??
          prefs.getString('nama_kasir') ??
          prefs.getString('nama_admin') ??
          'Kasir/Admin';
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
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(nilai);
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
    pesan += "Oleh : $namaPetugas\n";
    pesan += "Bayar : ${widget.metodePembayaran}\n";
    pesan += "--------------------------------------\n";

    for (var item in widget.keranjang) {
      String namaItem = item['nama']?.toString() ?? 'Produk';
      int itemHarga = _parseInt(item['harga']);
      int itemQty = _parseInt(item['qty']);
      int itemSub = _parseInt(item['subtotal']);
      if (itemSub == 0 && itemHarga > 0 && itemQty > 0) {
        itemSub = itemHarga * itemQty;
      }

      pesan += "$namaItem\n";
      pesan += "$itemQty x ${_formatRp(itemHarga)} = ${_formatRp(itemSub)}\n";
    }

    pesan += "--------------------------------------\n";
    pesan += "Subtotal : ${_formatRp(subtotalVal)}\n";
    if (jasaVal > 0) {
      pesan += "Biaya Jasa : ${_formatRp(jasaVal)}\n";
    }
    if (ppnVal > 0) {
      pesan += "PPN : ${_formatRp(ppnVal)}\n";
    }
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

    pesan +=
        "Terima kasih banyak telah berbelanja di *${namaToko.toUpperCase()}*! 😊\n";
    pesan +=
        "Kepercayaan Anda sangat berarti bagi kami. Kami tunggu kedatangannya kembali ya!\n\n";
    pesan +=
        "✨ _Struk digital ini dicetak menggunakan Aplikasi *Smart Kasir*._\n";
    pesan +=
        "_Ingin usaha atau toko Anda tampil lebih rapi dan modern seperti ini?_\n";
    pesan += "_Yuk, ngobrol santai dengan tim kami di WA: *$waSuperadmin*_ 😉";

    String textEncoded = Uri.encodeComponent(pesan);
    final Uri waUrl = Uri.parse("https://wa.me/?text=$textEncoded");

    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp.'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal membuka WhatsApp.'),
            backgroundColor: Colors.red));
      }
    }
  }

  // --- FUNGSI CETAK FISIK MENGGUNAKAN BLUETOOTH THERMAL UNIVERSAL ---

  Future<void> _cetakStrukFisik() async {
    // 1. PELINDUNG UNTUK WEB
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Cetak fisik tidak bisa dilakukan di Web. Harap instal aplikasi di HP Android.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    // 2. PELINDUNG UNTUK IOS (IPHONE/IPAD)
    if (Platform.isIOS) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Printer kasir umumnya tidak didukung di iOS karena batasan Apple. Gunakan Android.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    // 3. JIKA LULUS CEK (Berarti ini dijalankan di HP Android), LANJUTKAN CETAK
    try {
      bool isConnected = await PrintBluetoothThermal.connectionStatus;

      if (isConnected) {
        int subtotalVal = _parseInt(widget.subtotal);
        int jasaVal = _parseInt(widget.biayaJasa);
        int ppnVal = _parseInt(widget.ppnNominal);
        int totalVal = _parseInt(widget.totalBelanja);
        int tunaiVal = _parseInt(widget.uangDiterima);
        int kembaliVal = _parseInt(widget.uangKembalian);

        // GENERATE BYTES ESC/POS (Mendukung kertas 58mm)
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
        List<int> bytes = [];

        // Header Toko
        bytes += generator.text(namaToko.toUpperCase(),
            styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2));
        bytes += generator.text(alamatToko,
            styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text("WA: $waToko",
            styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text("--------------------------------",
            styles: const PosStyles(align: PosAlign.center));

        // Info Transaksi
        bytes += generator.row([
          PosColumn(text: "No: ${widget.noStruk}", width: 6),
          PosColumn(
              text: "Tgl: ${widget.tanggal}",
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: "Kasir: $namaPetugas", width: 6),
          PosColumn(
              text: "Bayar: ${widget.metodePembayaran}",
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.text("--------------------------------",
            styles: const PosStyles(align: PosAlign.center));

        // CETAK DAFTAR BARANG
        for (var item in widget.keranjang) {
          String namaItem = item['nama']?.toString() ?? 'Produk';
          int itemHarga = _parseInt(item['harga']);
          int itemQty = _parseInt(item['qty']);
          int itemSub = _parseInt(item['subtotal']);

          if (itemSub == 0 && itemHarga > 0 && itemQty > 0) {
            itemSub = itemHarga * itemQty;
          }

          bytes += generator.text(namaItem,
              styles: const PosStyles(align: PosAlign.left));
          bytes += generator.row([
            PosColumn(text: "$itemQty x ${_formatRp(itemHarga)}", width: 6),
            PosColumn(
                text: _formatRp(itemSub),
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
        }

        bytes += generator.text("--------------------------------",
            styles: const PosStyles(align: PosAlign.center));

        // Rincian Biaya
        bytes += generator.row([
          PosColumn(text: "Subtotal", width: 6),
          PosColumn(
              text: _formatRp(subtotalVal),
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]);

        if (jasaVal > 0) {
          bytes += generator.row([
            PosColumn(text: "Biaya Jasa", width: 6),
            PosColumn(
                text: _formatRp(jasaVal),
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
        }
        if (ppnVal > 0) {
          bytes += generator.row([
            PosColumn(text: "PPN Otomatis", width: 6),
            PosColumn(
                text: _formatRp(ppnVal),
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
        }

        // TOTAL BELANJA
        bytes += generator.row([
          PosColumn(
              text: "TOTAL",
              width: 6,
              styles: const PosStyles(bold: true, width: PosTextSize.size2)),
          PosColumn(
              text: _formatRp(totalVal),
              width: 6,
              styles: const PosStyles(
                  align: PosAlign.right, bold: true, width: PosTextSize.size2)),
        ]);

        if (widget.metodePembayaran == 'Tunai') {
          bytes += generator.row([
            PosColumn(text: "Tunai", width: 6),
            PosColumn(
                text: _formatRp(tunaiVal),
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
          bytes += generator.row([
            PosColumn(text: "Kembali", width: 6),
            PosColumn(
                text: _formatRp(kembaliVal),
                width: 6,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
        } else {
          bytes += generator.text("Pembayaran Non-Tunai:",
              styles: const PosStyles(align: PosAlign.left));
          bytes += generator.text("$namaBank - $rekeningBank",
              styles: const PosStyles(align: PosAlign.left));
          bytes += generator.text("A/N: $atasNama",
              styles: const PosStyles(align: PosAlign.left));
        }

        bytes += generator.text("--------------------------------",
            styles: const PosStyles(align: PosAlign.center));

        // --- TEKS PROMOSI ---
        bytes += generator.text("Terima kasih banyak telah",
            styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text("berbelanja di ${namaToko.toUpperCase()}! :-)",
            styles: const PosStyles(align: PosAlign.center));
        bytes += generator.feed(1);
        bytes += generator.text("Struk ini dicetak menggunakan",
            styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text("Aplikasi Smart Kasir",
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.text("Ingin usaha lebih modern?",
            styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text("Hubungi WA: $waSuperadmin",
            styles: const PosStyles(align: PosAlign.center));

        // Spasi Kertas agar tidak terpotong mesin
        bytes += generator.feed(2);

        // KIRIIM DATA MENTAH KE PRINTER
        await PrintBluetoothThermal.writeBytes(bytes);
      } else {
        // JIKA PRINTER BELUM TERHUBUNG, TAMPILKAN DAFTAR PRINTER
        List<BluetoothInfo> devices =
            await PrintBluetoothThermal.pairedBluetooths;

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Pilih Printer Bluetooth',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                content: SizedBox(
                  height: 300,
                  width: 300,
                  child: devices.isEmpty
                      ? const Center(
                          child: Text(
                              "Belum ada perangkat terpasang (paired). Pasangkan printer di pengaturan Bluetooth HP Anda terlebih dahulu.",
                              textAlign: TextAlign.center))
                      : ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.print,
                                  color: Colors.blueAccent),
                              title: Text(devices[index].name),
                              subtitle: Text(devices[index].macAdress),
                              onTap: () async {
                                Navigator.pop(
                                    context); // Tutup dialog list printer

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      'Menghubungkan ke ${devices[index].name}...'),
                                  backgroundColor: Colors.orange,
                                ));

                                try {
                                  // Menghubungkan menggunakan Mac Address
                                  bool terhubung =
                                      await PrintBluetoothThermal.connect(
                                          macPrinterAddress:
                                              devices[index].macAdress);

                                  if (terhubung) {
                                    _cetakStrukFisik(); // Panggil ulang untuk cetak setelah sukses konek
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Gagal terhubung ke printer. Pastikan printer menyala.'),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text(
                                          'Koneksi gagal. Cek ulang bluetooth.'),
                                      backgroundColor: Colors.red,
                                    ));
                                  }
                                }
                              },
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal',
                        style: TextStyle(color: Colors.red)),
                  )
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error Bluetooth: $e'), backgroundColor: Colors.red));
      }
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
        title: const Text('Detail Struk Transaksi',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withAlpha(50),
                        blurRadius: 10,
                        spreadRadius: 2)
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 50),
                            const SizedBox(height: 5),
                            const Text('Transaksi Berhasil!',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('No: ${widget.noStruk}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Divider(height: 25, thickness: 1),
                      const Text('Rincian Belanja:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 5),
                      if (widget.keranjang.isNotEmpty)
                        ...widget.keranjang.map((item) {
                          String namaItem =
                              item['nama']?.toString() ?? 'Produk';
                          int itemHarga = _parseInt(item['harga']);
                          int itemQty = _parseInt(item['qty']);
                          int itemSub = _parseInt(item['subtotal']);

                          if (itemSub == 0 && itemHarga > 0 && itemQty > 0) {
                            itemSub = itemHarga * itemQty;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text("$namaItem (${itemQty}x)",
                                      style: const TextStyle(fontSize: 13)),
                                ),
                                Text(_formatRp(itemSub),
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          );
                        })
                      else
                        const Text('Tidak ada item',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const Divider(height: 25, thickness: 1),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(_formatRp(subtotalVal))
                          ]),
                      if (jasaVal > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Biaya Jasa'),
                              Text(_formatRp(jasaVal))
                            ]),
                      ],
                      if (ppnVal > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('PPN Otomatis'),
                              Text(_formatRp(ppnVal))
                            ]),
                      ],
                      const SizedBox(height: 4),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Belanja',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(_formatRp(totalVal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blueAccent))
                          ]),
                      const SizedBox(height: 6),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pembayaran'),
                            Text(widget.metodePembayaran,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))
                          ]),
                      const SizedBox(height: 4),
                      if (widget.metodePembayaran == 'Tunai') ...[
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tunai'),
                              Text(_formatRp(tunaiVal))
                            ]),
                        const SizedBox(height: 4),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kembalian'),
                              Text(_formatRp(kembaliVal),
                                  style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold))
                            ]),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Transfer / QRIS Ke:',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue)),
                              Text('$namaBank - $rekeningBank',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                              Text('a/n $atasNama',
                                  style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        )
                      ],
                      Divider(
                          height: 25,
                          thickness: 1,
                          color: Colors.grey.shade400),
                      Center(
                        child: Text('Kasir/Admin: $namaPetugas',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                      ),
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
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: _cetakStrukFisik,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Cetak Fisik',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onPressed: _kirimWhatsApp,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Kirim WA',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Transaksi Baru',
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            )
          ],
        ),
      ),
    );
  }
}
