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

import 'tema.dart'; // Import tema premium
import 'kerangka_navigasi.dart';

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

  String namaToko = 'Memuat...';
  String alamatToko = '-';
  String waToko = '-';
  String namaBank = '';
  String rekeningBank = '';
  String atasNama = '';
  String qrQrisPath = ''; 

  String namaPetugas = 'Kasir';
  String waSuperadmin = '081234567890';
  bool isLoading = true;
  bool isPrinting = false;

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    await _muatDataTokoDanPetugas();
    setState(() => isLoading = false);
  }

  Future<void> _muatDataTokoDanPetugas() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaPetugas = prefs.getString('username') ?? 'Kasir';
    });

    int tokoId = prefs.getInt('toko_id') ?? 1;

    try {
      final response = await http.get(Uri.parse('$domainUrl/api/detailToko/$tokoId'), headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          namaToko = data['nama_toko'] ?? 'Toko Saya';
          alamatToko = data['alamat'] ?? '-';
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
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_parseInt(angka));
  }

  // ===================================================================
  // FUNGSI CETAK FISIK LANGSUNG (SILENT AUTO-CONNECT)
  // ===================================================================
  Future<void> _mulaiProsesCetak() async {
    if (kIsWeb || Platform.isIOS) {
      _tampilkanNotif('Cetak fisik belum didukung di Web/iOS.', AppColors.premiumGold);
      return;
    }

    setState(() => isPrinting = true);
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil settingan dari Halaman Printer
    String alamatUtama = prefs.getString('printer_alamat_utama') ?? prefs.getString('mac_printer') ?? '';

    if (alamatUtama.isEmpty) {
      _tampilkanNotif('Printer belum diatur! Silakan atur di menu Pengaturan Printer.', AppColors.red);
      setState(() => isPrinting = false);
      return;
    }

    _tampilkanNotif('Mencetak struk...', AppColors.smartBlue);

    // 1. Cetak Struk Lengkap ke Kasir
    List<int> bytesUtama = await _generateBytesStrukLengkap();
    await _kirimDataKePrinter(prefs, 'utama', bytesUtama, 'Kasir');

    // 2. Pemisahan Tiket Pesanan (Dapur & Bar)
    Map<String, List<dynamic>> pesananDivisi = {};
    for (var item in widget.keranjang) {
      String divisi = item['divisi_printer']?.toString().toLowerCase() ?? 'kasir';
      if (divisi != 'kasir') {
        if (!pesananDivisi.containsKey(divisi)) pesananDivisi[divisi] = [];
        pesananDivisi[divisi]!.add(item);
      }
    }

    for (var divisi in pesananDivisi.keys) {
      List<int> bytesDivisi = await _generateBytesStrukDivisi(pesananDivisi[divisi]!, divisi);
      String ipDivisi = prefs.getString('ip_printer_$divisi') ?? '';
      if (ipDivisi.isNotEmpty) {
        try {
          Socket socket = await Socket.connect(ipDivisi, 9100, timeout: const Duration(seconds: 5));
          socket.add(bytesDivisi);
          await socket.flush();
          socket.destroy();
        } catch (e) {
          debugPrint("Gagal cetak ke $divisi ($ipDivisi): $e");
        }
      }
    }

    setState(() => isPrinting = false);
  }

  Future<void> _kirimDataKePrinter(SharedPreferences prefs, String idSlot, List<int> bytes, String namaRute) async {
    String tipe = prefs.getString('printer_tipe_$idSlot') ?? 'bluetooth';
    String alamat = prefs.getString('printer_alamat_$idSlot') ?? prefs.getString('mac_printer') ?? '';
    if (alamat.isEmpty) return; 

    try {
      if (tipe == 'wifi') {
        Socket socket = await Socket.connect(alamat, 9100, timeout: const Duration(seconds: 5));
        socket.add(bytes);
        await socket.flush();
        socket.destroy();
      } else {
        bool isConnected = false;
        try {
          isConnected = await PrintBluetoothThermal.connectionStatus;
        } catch (_) {}

        if (!isConnected) {
          bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: alamat).timeout(const Duration(seconds: 8), onTimeout: () => false);
          
          if (!connected) {
             await PrintBluetoothThermal.disconnect;
             await Future.delayed(const Duration(seconds: 1));
             connected = await PrintBluetoothThermal.connect(macPrinterAddress: alamat).timeout(const Duration(seconds: 8), onTimeout: () => false);
          }

          if (!connected) {
            _tampilkanNotif('Gagal terhubung ke printer $namaRute. Pastikan perangkat menyala.', AppColors.red);
            return;
          }
        }

        bool printed = await PrintBluetoothThermal.writeBytes(bytes);
        if (!printed) {
           await PrintBluetoothThermal.disconnect;
           bool retryConnect = await PrintBluetoothThermal.connect(macPrinterAddress: alamat).timeout(const Duration(seconds: 7), onTimeout: () => false);
           if (retryConnect) await PrintBluetoothThermal.writeBytes(bytes);
        }
      }
    } catch (e) {
      _tampilkanNotif('Gagal mengirim data ke printer.', AppColors.red);
    }
  }

  Future<List<int>> _generateBytesStrukLengkap() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text(namaToko.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.text(alamatToko, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("WA: $waToko", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: "No: ${widget.noStruk}", width: 6),
      PosColumn(text: widget.tanggal.split(' ')[0], width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (widget.noMeja != null && widget.noMeja!.isNotEmpty && widget.noMeja != '-') {
      bytes += generator.feed(1);
      bytes += generator.text("MEJA / INFO: ${widget.noMeja}", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      bytes += generator.feed(1);
    }
    bytes += generator.row([
      PosColumn(text: "Kasir: $namaPetugas", width: 6),
      PosColumn(text: widget.metodePembayaran, width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    for (var item in widget.keranjang) {
      String namaItem = item['nama']?.toString() ?? 'Produk';
      int itemHarga = _parseInt(item['harga']);
      int itemQty = _parseInt(item['qty']);
      int itemSub = _parseInt(item['subtotal']);
      if (itemSub == 0 && itemHarga > 0 && itemQty > 0) itemSub = itemHarga * itemQty;

      bytes += generator.text(namaItem, styles: const PosStyles(align: PosAlign.left));
      bytes += generator.row([
        PosColumn(text: "$itemQty x ${_formatRp(itemHarga)}", width: 6),
        PosColumn(text: _formatRp(itemSub), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.row([
      PosColumn(text: "Subtotal", width: 6),
      PosColumn(text: _formatRp(widget.subtotal), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
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

    if (widget.metodePembayaran.toLowerCase() == 'tunai') {
      bytes += generator.row([
        PosColumn(text: "Tunai", width: 6),
        PosColumn(text: _formatRp(widget.uangDiterima), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: "Kembali", width: 6),
        PosColumn(text: _formatRp(widget.uangKembalian), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    } else {
      bytes += generator.feed(1);
      bytes += generator.text("--- DIBAYAR NON-TUNAI ---", styles: const PosStyles(align: PosAlign.center, bold: true));
      if (qrQrisPath.isNotEmpty) {
        try {
          String cleanPath = qrQrisPath.startsWith('/') ? qrQrisPath.substring(1) : qrQrisPath;
          String finalQrUrl = qrQrisPath.startsWith('http') ? qrQrisPath : '$domainUrl/uploads/qr/$cleanPath';
          final resImg = await http.get(Uri.parse(finalQrUrl));
          if (resImg.statusCode == 200) {
            img.Image? originalImage = img.decodeImage(resImg.bodyBytes);
            if (originalImage != null) {
              img.Image resized = img.copyResize(originalImage, width: 300);
              bytes += generator.feed(1);
              bytes += generator.imageRaster(resized, align: PosAlign.center);
            }
          }
        } catch(e) { debugPrint("Gagal muat QR: $e"); }
      }
    }
    
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Terima kasih telah berbelanja", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("di ${namaToko.toUpperCase()}", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);

    return bytes;
  }

  Future<List<int>> _generateBytesStrukDivisi(List items, String divisi) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text("TIKET ${divisi.toUpperCase()}", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.feed(1);
    bytes += generator.text("No: ${widget.noStruk}", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Tgl: ${widget.tanggal}", styles: const PosStyles(align: PosAlign.center)); 

    if (widget.noMeja != null && widget.noMeja!.isNotEmpty && widget.noMeja != '-') {
      bytes += generator.feed(1);
      bytes += generator.text("MEJA: ${widget.noMeja}", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    for (var item in items) {
      String namaItem = item['nama']?.toString() ?? 'Produk';
      int itemQty = _parseInt(item['qty']);
      bytes += generator.text("$itemQty x $namaItem", styles: const PosStyles(bold: true, width: PosTextSize.size2));
      bytes += generator.feed(1);
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    return bytes;
  }

  // ===================================================================
  // FUNGSI KIRIM WHATSAPP
  // ===================================================================
  Future<void> _kirimWhatsApp() async {
    String pesan = "*STRUK DIGITAL*\n";
    pesan += "*${namaToko.toUpperCase()}*\n$alamatToko\nWA: $waToko\n";
    pesan += "--------------------------------\n";
    pesan += "No: ${widget.noStruk}\nTgl: ${widget.tanggal}\nKasir: $namaPetugas\n";
    pesan += "--------------------------------\n";

    for (var item in widget.keranjang) {
      pesan += "${item['nama']}\n${item['qty']} x ${_formatRp(item['harga'])} = ${_formatRp(item['subtotal'])}\n";
    }

    pesan += "--------------------------------\n";
    pesan += "Subtotal : ${_formatRp(widget.subtotal)}\n";
    if (_parseInt(widget.ppnNominal) > 0) pesan += "PPN : ${_formatRp(widget.ppnNominal)}\n";
    pesan += "*Total : ${_formatRp(widget.totalBelanja)}*\n";

    if (widget.metodePembayaran.toLowerCase() == 'tunai') {
      pesan += "Tunai : ${_formatRp(widget.uangDiterima)}\nKembali : ${_formatRp(widget.uangKembalian)}\n";
    } else {
      pesan += "\n*💳 INFO PEMBAYARAN NON-TUNAI:*\nBank: $namaBank\nNo. Rek: $rekeningBank\nA/N: $atasNama\n";
    }
    pesan += "--------------------------------\n";
    pesan += "Terima kasih telah berbelanja di *${namaToko.toUpperCase()}*! 😊\n";

    String textEncoded = Uri.encodeComponent(pesan);
    final Uri waUrl = Uri.parse("https://wa.me/?text=$textEncoded");

    try {
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl, mode: LaunchMode.externalApplication);
      } else {
        _tampilkanNotif('Tidak dapat membuka WhatsApp.', AppColors.red);
      }
    } catch (e) {
      _tampilkanNotif('Gagal membuka WhatsApp.', AppColors.red);
    }
  }

  void _tampilkanNotif(String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ==========================================
  // WIDGET UTAMA (BODY)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(backgroundColor: AppColors.lightGray, body: Center(child: CircularProgressIndicator(color: AppColors.teal)));
    }

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        foregroundColor: AppColors.white,
        automaticallyImplyLeading: false, // Sembunyikan tombol back bawaan
      ),
      body: Column(
        children: [
          // STRUK KERTAS DIGITAL (Tampilan Utama)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Berhasil
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.15), shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle, color: AppColors.emerald, size: 50),
                          ),
                          const SizedBox(height: 10),
                          const Text('Transaksi Berhasil!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          Text(widget.noStruk, style: const TextStyle(color: AppColors.slateGray, fontSize: 13)),
                        ],
                      ),
                    ),
                    
                    const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: AppColors.lightGray, thickness: 2)),
                    
                    // Rincian Barang
                    const Text('Rincian Pembelanjaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slateGray)),
                    const SizedBox(height: 10),
                    ...widget.keranjang.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nama'] ?? 'Produk', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                                  Text("${item['qty']} x ${_formatRp(item['harga'])}", style: const TextStyle(fontSize: 12, color: AppColors.slateGray)),
                                ],
                              ),
                            ),
                            Text(_formatRp(item['subtotal']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          ],
                        ),
                      );
                    }),
                    
                    const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: AppColors.lightGray, thickness: 2)),
                    
                    // Total & Pembayaran
                    _buildRingkasanRow('Subtotal', _formatRp(widget.subtotal)),
                    if (_parseInt(widget.ppnNominal) > 0) ...[
                      const SizedBox(height: 6),
                      _buildRingkasanRow('PPN Otomatis', _formatRp(widget.ppnNominal)),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                        Text(_formatRp(widget.totalBelanja), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.smartBlue)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRingkasanRow('Metode Pembayaran', widget.metodePembayaran, isBold: true),
                          const SizedBox(height: 8),
                          if (widget.metodePembayaran.toLowerCase() == 'tunai') ...[
                            _buildRingkasanRow('Tunai', _formatRp(widget.uangDiterima)),
                            const SizedBox(height: 4),
                            _buildRingkasanRow('Kembalian', _formatRp(widget.uangKembalian), colorValue: AppColors.emerald),
                          ] else ...[
                            const Text('Transfer ke:', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                            Text('$namaBank - $rekeningBank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkText)),
                            Text('a/n $atasNama', style: const TextStyle(fontSize: 12, color: AppColors.darkText)),
                          ]
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    Center(child: Text('Dilayani oleh: $namaPetugas', style: const TextStyle(color: AppColors.slateGray, fontSize: 11))),
                  ],
                ),
              ),
            ),
          ),

          // PANEL TOMBOL BAWAH
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Tombol Cetak Fisik
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        onPressed: isPrinting ? null : _mulaiProsesCetak, 
                        icon: isPrinting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)) : const Icon(Icons.print, size: 18, color: AppColors.white),
                        label: const Text('Cetak Struk Fisik', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol Kirim WA
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                        onPressed: _kirimWhatsApp,
                        icon: const Icon(Icons.chat, size: 18, color: AppColors.white),
                        label: const Text('Kirim WA', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Tombol Kembali ke Kasir
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.smartBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const KerangkaNavigasiPremium()), (route) => false);
                    },
                    child: const Text('Transaksi Baru', style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRingkasanRow(String label, String value, {bool isBold = false, Color colorValue = AppColors.darkText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.slateGray, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: colorValue, fontSize: 13)),
      ],
    );
  }
}
