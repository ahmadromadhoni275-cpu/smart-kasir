import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform, Socket;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'tema.dart'; // Import tema eksklusif

class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  final String domainUrl = 'https://smartkasir.shop';
  bool isLoading = true;
  int _tokoId = 1;
  int _userId = 1;
  String _namaToko = 'Toko Anda';

  // State untuk Shift
  String _statusShift = 'closed';
  int _modalAwal = 0;

  DateTime _tglAwal = DateTime.now().subtract(const Duration(days: 7));
  DateTime _tglAkhir = DateTime.now();

  Map<String, dynamic> metrik = {
    'omzet': 0,
    'total_transaksi': 0,
    'laba_bersih': 0
  };
  
  List grafikData = [];
  int grafikMax = 1;
  List produkTerlaris = [];

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tokoId = prefs.getInt('toko_id') ?? 1;
      _userId = prefs.getInt('user_id') ?? 1;
      _namaToko = prefs.getString('nama_toko') ?? 'Smart Kasir';
    });
    
    await _cekStatusShift();
    await _ambilDataLaporan();
  }

  // ==========================================
  // FUNGSI MANAJEMEN SHIFT
  // ==========================================
  Future<void> _cekStatusShift() async {
    try {
      final res = await http.get(Uri.parse('$domainUrl/api/cekStatusShift/$_userId'), headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final data = json.decode(res.body)['data'];
        setState(() {
          _statusShift = data['status_shift'] ?? 'closed';
          _modalAwal = int.tryParse(data['modal_awal']?.toString() ?? '0') ?? 0;
        });
      }
    } catch (e) {
      debugPrint("Gagal cek shift: $e");
    }
  }

  void _tampilkanDialogBukaShift() {
    TextEditingController modalCtrl = TextEditingController(text: '0');
    bool isProses = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Buka Shift Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Masukkan modal awal (uang kembalian) yang ada di laci kasir saat ini.', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                const SizedBox(height: 15),
                TextField(
                  controller: modalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Modal Awal (Rp)',
                    prefixIcon: const Icon(Icons.account_balance_wallet, color: AppColors.slateGray),
                    filled: true, fillColor: AppColors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: isProses ? null : () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.slateGray))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: isProses ? null : () async {
                  setDialogState(() => isProses = true);
                  try {
                    await http.post(
                      Uri.parse('$domainUrl/api/bukaShift'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({'user_id': _userId, 'modal_awal': int.tryParse(modalCtrl.text) ?? 0})
                    );
                    await _cekStatusShift();
                    if (ctx.mounted) Navigator.pop(ctx);
                    _tampilkanNotif('Shift Dibuka! Kasir siap digunakan.', AppColors.emerald);
                  } catch (e) {
                    _tampilkanNotif('Gagal membuka shift', AppColors.red);
                  }
                  setDialogState(() => isProses = false);
                },
                child: isProses ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)) : const Text('Buka Shift', style: TextStyle(color: AppColors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _tutupShift() async {
    try {
      await http.post(
        Uri.parse('$domainUrl/api/tutupShift'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': _userId})
      );
      await _cekStatusShift();
      _tampilkanNotif('Shift Ditutup. Laci kasir terkunci.', AppColors.smartBlue);
    } catch (e) {
      _tampilkanNotif('Gagal menutup shift', AppColors.red);
    }
  }

  // ==========================================
  // FUNGSI LAPORAN & CETAK
  // ==========================================
  Future<void> _ambilDataLaporan() async {
    setState(() => isLoading = true);
    String strAwal = DateFormat('yyyy-MM-dd').format(_tglAwal);
    String strAkhir = DateFormat('yyyy-MM-dd').format(_tglAkhir);

    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/laporanBerkala?toko_id=$_tokoId&tgl_awal=$strAwal&tgl_akhir=$strAkhir'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body)['data'];
        setState(() {
          metrik = res['metrik'];
          grafikData = res['grafik']['data'];
          grafikMax = res['grafik']['nilai_tertinggi'] == 0 ? 1 : res['grafik']['nilai_tertinggi'];
          produkTerlaris = res['produk_terlaris'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Gagal memuat laporan: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _pilihRentangTanggal() async {
    DateTimeRange? rangeSelesai = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _tglAwal, end: _tglAkhir),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.teal,
              onPrimary: AppColors.white,
              onSurface: AppColors.darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (rangeSelesai != null) {
      setState(() {
        _tglAwal = rangeSelesai.start;
        _tglAkhir = rangeSelesai.end;
      });
      _ambilDataLaporan();
    }
  }

  String _formatRupiah(int angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  Future<void> _cetakLaporanFisik() async {
    if (kIsWeb || Platform.isIOS) {
      _tampilkanNotif('Platform tidak didukung untuk cetak Bluetooth.', AppColors.red);
      return;
    }

    _tampilkanNotif('Memproses cetak laporan...', AppColors.smartBlue);

    final prefs = await SharedPreferences.getInstance();
    String tipe = prefs.getString('printer_tipe_utama') ?? 'bluetooth';
    String alamat = prefs.getString('printer_alamat_utama') ?? prefs.getString('mac_printer') ?? '';

    if (alamat.isEmpty) {
      _tampilkanNotif('Printer belum diatur! Silakan hubungkan di menu Pengaturan Printer.', AppColors.red);
      return;
    }

    try {
      List<int> bytes = await _generateBytesLaporan();

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
          bool reconnected = await PrintBluetoothThermal.connect(macPrinterAddress: alamat)
              .timeout(const Duration(seconds: 10), onTimeout: () => false);
          if (!reconnected) {
            await PrintBluetoothThermal.disconnect;
            await Future.delayed(const Duration(seconds: 1));
            reconnected = await PrintBluetoothThermal.connect(macPrinterAddress: alamat)
                .timeout(const Duration(seconds: 10), onTimeout: () => false);
          }
          if (!reconnected) {
            _tampilkanNotif('Gagal terhubung ke printer. Periksa & nyalakan printer Anda.', AppColors.red);
            return;
          }
        }

        bool printed = await PrintBluetoothThermal.writeBytes(bytes);
        if (!printed) {
          await PrintBluetoothThermal.disconnect;
          bool retry = await PrintBluetoothThermal.connect(macPrinterAddress: alamat).timeout(const Duration(seconds: 7), onTimeout: () => false);
          if (retry) await PrintBluetoothThermal.writeBytes(bytes);
        }
      }
    } catch (e) {
      _tampilkanNotif('Gagal mencetak laporan: $e', AppColors.red);
    }
  }

  Future<List<int>> _generateBytesLaporan() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    String strAwal = DateFormat('dd/MM/yyyy').format(_tglAwal);
    String strAkhir = DateFormat('dd/MM/yyyy').format(_tglAkhir);

    bytes += generator.text(_namaToko.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.text("LAPORAN PENJUALAN", styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text("Periode: $strAwal - $strAkhir", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.row([
      PosColumn(text: "Total Omzet", width: 6),
      PosColumn(text: _formatRupiah(metrik['omzet']), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: "Total TRX", width: 6),
      PosColumn(text: "${metrik['total_transaksi']}", width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: "Laba Bersih", width: 6),
      PosColumn(text: _formatRupiah(metrik['laba_bersih']), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("10 PRODUK TERLARIS:", styles: const PosStyles(align: PosAlign.left, bold: true));
    bytes += generator.feed(1);

    for (var i = 0; i < produkTerlaris.length; i++) {
      var prod = produkTerlaris[i];
      bytes += generator.text("${i+1}. ${prod['nama']}", styles: const PosStyles(align: PosAlign.left, bold: true));
      bytes += generator.row([
        PosColumn(text: "Terjual: ${prod['terjual']}x", width: 6),
        PosColumn(text: _formatRupiah(int.parse(prod['omzet'].toString())), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Dicetak pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);

    return bytes;
  }

  void _tampilkanNotif(String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ===================================================================
  // WIDGET UTAMA (BODY)
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    String periodeStr = "${DateFormat('dd MMM yyyy').format(_tglAwal)} - ${DateFormat('dd MMM yyyy').format(_tglAkhir)}";

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER HALAMAN ---
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
                  color: AppColors.lightGray,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Laporan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          SizedBox(height: 4),
                          Text('Analisis penjualan dan performa bisnis', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                        ],
                      ),
                      InkWell(
                        onTap: _pilihRentangTanggal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.slateGray),
                              const SizedBox(width: 8),
                              Text(periodeStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _ambilDataLaporan,
                    color: AppColors.teal,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- KARTU MANAJEMEN SHIFT ---
                          Container(
                            margin: const EdgeInsets.only(bottom: 25),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: _statusShift == 'open' ? AppColors.emerald.withOpacity(0.1) : AppColors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _statusShift == 'open' ? AppColors.emerald : AppColors.red),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_statusShift == 'open' ? 'Shift Sedang Berjalan' : 'Kasir Terkunci', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _statusShift == 'open' ? AppColors.emerald : AppColors.red)),
                                    const SizedBox(height: 4),
                                    Text(_statusShift == 'open' ? 'Modal Awal: ${_formatRupiah(_modalAwal)}' : 'Buka shift untuk mulai transaksi', style: const TextStyle(fontSize: 11, color: AppColors.darkText)),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _statusShift == 'open' ? AppColors.red : AppColors.emerald,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: _statusShift == 'open' ? _tutupShift : _tampilkanDialogBukaShift,
                                  child: Text(_statusShift == 'open' ? 'Tutup Shift' : 'Buka Shift', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
                                )
                              ],
                            ),
                          ),

                          // --- 3 METRIK UTAMA ---
                          Row(
                            children: [
                              Expanded(child: _buildMetrikCard('Total Omzet', _formatRupiah(metrik['omzet']), Icons.account_balance_wallet, AppColors.premiumGold)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildMetrikCard('Total Transaksi', '${metrik['total_transaksi']}', Icons.receipt_long, AppColors.smartBlue)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildMetrikCard('Laba Bersih', _formatRupiah(metrik['laba_bersih']), Icons.trending_up, AppColors.emerald)),
                            ],
                          ),
                          const SizedBox(height: 25),

                          // --- GRAFIK & PRODUK TERLARIS SECTION ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Grafik Penjualan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText)),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        height: 150,
                                        child: grafikData.isEmpty 
                                          ? const Center(child: Text('Tidak ada data', style: TextStyle(color: AppColors.slateGray)))
                                          : SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: grafikData.map((data) {
                                                  double tinggiTiang = (data['total'] / grafikMax) * 120;
                                                  if (data['total'] > 0 && tinggiTiang < 10) tinggiTiang = 10;
                                                  return Container(
                                                    margin: const EdgeInsets.only(right: 15),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        Container(
                                                          width: 15,
                                                          height: tinggiTiang,
                                                          decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(4)),
                                                        ),
                                                        const SizedBox(height: 10),
                                                        Text(data['hari_singkat'], style: const TextStyle(fontSize: 9, color: AppColors.slateGray)),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                flex: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Produk Terlaris', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText)),
                                      const SizedBox(height: 15),
                                      if (produkTerlaris.isEmpty)
                                        const Text('Belum ada penjualan', style: TextStyle(color: AppColors.slateGray, fontSize: 12))
                                      else
                                        ...produkTerlaris.map((prod) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(6)),
                                                  child: const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.slateGray),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(prod['nama'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                                                      Text('${prod['terjual']} Terjual', style: const TextStyle(fontSize: 9, color: AppColors.slateGray)),
                                                    ],
                                                  ),
                                                ),
                                                Text(_formatRupiah(int.parse(prod['omzet'].toString())), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.smartBlue)),
                                              ],
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: FloatingActionButton.extended(
          onPressed: _cetakLaporanFisik,
          backgroundColor: AppColors.teal,
          icon: const Icon(Icons.print, color: AppColors.white),
          label: const Text('Cetak Laporan', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildMetrikCard(String judul, String nilai, IconData ikon, Color warnaBg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: warnaBg.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(ikon, color: warnaBg, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(judul, style: const TextStyle(fontSize: 10, color: AppColors.slateGray, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          Text(nilai, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: warnaBg == AppColors.premiumGold ? AppColors.darkText : warnaBg)),
        ],
      ),
    );
  }
}
