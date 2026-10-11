import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:io' show Platform, Socket;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'tema.dart'; 
// TODO: Sesuaikan dengan lokasi ApiClient Anda
import 'core/network/api_client.dart'; 

class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  final Dio _dio = ApiClient().dio;

  bool isLoading = true;
  String _namaToko = 'Toko Anda';
  String _namaPetugas = 'Kasir'; 

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
      _namaToko = prefs.getString('nama_toko') ?? 'Smart Kasir';
      _namaPetugas = prefs.getString('username') ?? 'Kasir';
    });
    await _cekStatusShift();
    await _ambilDataLaporan();
  }

  // ==========================================
  // FUNGSI MANAJEMEN SHIFT (Sesuai Routes CI4)
  // ==========================================
  Future<void> _cekStatusShift() async {
    try {
      // Endpoint disesuaikan dengan: $routes->get('shifts/current', ...)
      final res = await _dio.get('/shifts/current');
      if (res.statusCode == 200) {
        final data = res.data['data'];
        setState(() {
          _statusShift = data['status_shift'] ?? 'closed';
          _modalAwal = int.tryParse(data['modal_awal']?.toString() ?? '0') ?? 0;
        });
      }
    } on DioException catch (e) {
      debugPrint("Gagal cek shift: ${e.message}");
    } catch (e) {
      debugPrint("Error sistem cek shift: $e");
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
                    // Endpoint disesuaikan dengan: $routes->post('shifts/open', ...)
                    await _dio.post(
                      '/shifts/open',
                      data: {
                        'modal_awal': int.tryParse(modalCtrl.text) ?? 0
                      }
                    );
                    await _cekStatusShift();
                    if (ctx.mounted) Navigator.pop(ctx);
                    _tampilkanNotif('Shift Dibuka! Silakan kembali ke menu Kasir.', AppColors.emerald);
                  } on DioException catch (e) {
                    final msg = e.response?.data['message'] ?? 'Gagal membuka shift';
                    _tampilkanNotif(msg, AppColors.red);
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

  void _tampilkanDialogTutupShift() {
    TextEditingController catatanCtrl = TextEditingController();
    bool isProses = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Tutup Shift', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Laci kasir akan dikunci. Silakan masukkan catatan (opsional) sebelum mencetak rekapitulasi shift.', style: TextStyle(fontSize: 12, color: AppColors.slateGray)),
                const SizedBox(height: 15),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Catatan / Keterangan',
                    hintText: 'Misal: Uang fisik sesuai, aman.',
                    filled: true, fillColor: AppColors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: isProses ? null : () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: AppColors.slateGray))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: isProses ? null : () async {
                  setDialogState(() => isProses = true);
                  try {
                    // Endpoint disesuaikan dengan: $routes->post('shifts/close', ...)
                    final response = await _dio.post(
                      '/shifts/close',
                      data: {
                        'catatan': catatanCtrl.text
                      }
                    );
                    
                    if (response.statusCode == 200) {
                      final dataShift = response.data['data'];
                      await _cekStatusShift();
                      if (ctx.mounted) Navigator.pop(ctx);
                      _tampilkanNotif('Shift Ditutup. Memproses cetak struk shift...', AppColors.smartBlue);
                      await _cetakLaporanShiftFisik(dataShift ?? {});
                    }
                  } on DioException catch (e) {
                    final msg = e.response?.data['message'] ?? 'Gagal menutup shift';
                    _tampilkanNotif(msg, AppColors.red);
                  }
                  if (ctx.mounted) setDialogState(() => isProses = false);
                },
                child: isProses ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)) : const Text('Tutup & Cetak Shift', style: TextStyle(color: AppColors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // FUNGSI LAPORAN (Sesuai Routes & Parameter CI4)
  // ==========================================
  Future<void> _ambilDataLaporan() async {
    setState(() => isLoading = true);
    String strAwal = DateFormat('yyyy-MM-dd').format(_tglAwal);
    String strAkhir = DateFormat('yyyy-MM-dd').format(_tglAkhir);

    try {
      // Menggunakan route /reports dan parameter date_from, date_to (bukan tgl_awal/tgl_akhir)
      final response = await _dio.get(
        '/dashboard', // ATAU /reports sesuai struktur pengembalian metrik backend Anda
        queryParameters: {
          'date_from': strAwal,
          'date_to': strAkhir,
        }
      );

      if (response.statusCode == 200) {
        final res = response.data['data'];
        setState(() {
          metrik = res['metrik'] ?? {'omzet': 0, 'total_transaksi': 0, 'laba_bersih': 0};
          grafikData = res['grafik']?['data'] ?? [];
          grafikMax = res['grafik']?['nilai_tertinggi'] == 0 ? 1 : (res['grafik']?['nilai_tertinggi'] ?? 1);
          produkTerlaris = res['produk_terlaris'] ?? [];
          isLoading = false;
        });
      }
    } on DioException catch (e) {
      debugPrint("Gagal memuat laporan: ${e.message}");
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

  // =======================================================
  // FUNGSI CETAK PRINTER BLUETOOTH (Tetap Sama)
  // =======================================================
  Future<void> _cetakLaporanFisik() async {
    if (kIsWeb || Platform.isIOS) {
      _tampilkanNotif('Platform tidak didukung untuk cetak Bluetooth.', AppColors.red);
      return;
    }
    _tampilkanNotif('Memproses cetak laporan...', AppColors.smartBlue);
    List<int> bytes = await _generateBytesLaporanBerkala();
    await _kirimKePrinter(bytes);
  }

  Future<void> _cetakLaporanShiftFisik(Map<String, dynamic> dataShift) async {
    if (kIsWeb || Platform.isIOS) return;
    List<int> bytes = await _generateBytesLaporanShift(dataShift);
    await _kirimKePrinter(bytes);
  }

  Future<void> _kirimKePrinter(List<int> bytes) async {
    final prefs = await SharedPreferences.getInstance();
    String tipe = prefs.getString('printer_tipe_utama') ?? 'bluetooth';
    String alamat = prefs.getString('printer_alamat_utama') ?? prefs.getString('mac_printer') ?? '';

    if (alamat.isEmpty) {
      _tampilkanNotif('Printer belum diatur! Silakan hubungkan di menu Pengaturan Printer.', AppColors.red);
      return;
    }

    try {
      if (tipe == 'wifi') {
        Socket socket = await Socket.connect(alamat, 9100, timeout: const Duration(seconds: 5));
        socket.add(bytes);
        await socket.flush();
        socket.destroy();
      } else {
        bool isConnected = false;
        try { isConnected = await PrintBluetoothThermal.connectionStatus; } catch (_) {}

        if (!isConnected) {
          bool reconnected = await PrintBluetoothThermal.connect(macPrinterAddress: alamat).timeout(const Duration(seconds: 10), onTimeout: () => false);
          if (!reconnected) {
            await PrintBluetoothThermal.disconnect;
            await Future.delayed(const Duration(seconds: 1));
            reconnected = await PrintBluetoothThermal.connect(macPrinterAddress: alamat).timeout(const Duration(seconds: 10), onTimeout: () => false);
          }
          if (!reconnected) {
            _tampilkanNotif('Gagal terhubung ke printer. Periksa & nyalakan printer.', AppColors.red);
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
      _tampilkanNotif('Gagal mencetak: $e', AppColors.red);
    }
  }

  Future<List<int>> _generateBytesLaporanShift(Map<String, dynamic> shift) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    String kasir = shift['kasir'] ?? _namaPetugas;
    String waktuBuka = shift['waktu_buka'] ?? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    String waktuTutup = shift['waktu_tutup'] ?? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    int modalAwal = int.tryParse(shift['modal_awal']?.toString() ?? '0') ?? _modalAwal;
    int bayarTunai = int.tryParse(shift['pembayaran_tunai']?.toString() ?? '0') ?? 0;
    int bayarNonTunai = int.tryParse(shift['pembayaran_non_tunai']?.toString() ?? '0') ?? 0;
    int totalPendapatan = int.tryParse(shift['total_penjualan']?.toString() ?? '0') ?? (bayarTunai + bayarNonTunai);
    String catatan = shift['catatan'] ?? '-';
    List produk = shift['produk_terjual'] ?? [];

    bytes += generator.text(_namaToko.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.text("REKAPITULASI SHIFT", styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.row([PosColumn(text: "Kasir", width: 4), PosColumn(text: ": $kasir", width: 8)]);
    bytes += generator.row([PosColumn(text: "Buka", width: 4), PosColumn(text: ": $waktuBuka", width: 8)]);
    bytes += generator.row([PosColumn(text: "Tutup", width: 4), PosColumn(text: ": $waktuTutup", width: 8)]);
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.row([PosColumn(text: "Modal Awal", width: 6), PosColumn(text: _formatRupiah(modalAwal), width: 6, styles: const PosStyles(align: PosAlign.right))]);
    bytes += generator.row([PosColumn(text: "Pemasukan Tunai", width: 6), PosColumn(text: _formatRupiah(bayarTunai), width: 6, styles: const PosStyles(align: PosAlign.right))]);
    bytes += generator.row([PosColumn(text: "Pemasukan QRIS/TF", width: 6), PosColumn(text: _formatRupiah(bayarNonTunai), width: 6, styles: const PosStyles(align: PosAlign.right))]);
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.row([PosColumn(text: "TOTAL KOTOR", width: 6, styles: const PosStyles(bold: true)), PosColumn(text: _formatRupiah(totalPendapatan), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true))]);
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("PRODUK TERJUAL (SHIFT INI):", styles: const PosStyles(align: PosAlign.left, bold: true));
    if (produk.isEmpty) {
      bytes += generator.text("Tidak ada penjualan", styles: const PosStyles(align: PosAlign.center));
    } else {
      for (var i = 0; i < produk.length; i++) {
        var prod = produk[i];
        bytes += generator.text("${i+1}. ${prod['nama']} (${prod['qty']}x)", styles: const PosStyles(align: PosAlign.left));
        bytes += generator.text(_formatRupiah(int.parse(prod['total']?.toString() ?? '0')), styles: const PosStyles(align: PosAlign.right));
      }
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Catatan: $catatan", styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text("================================", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);

    return bytes;
  }

  Future<List<int>> _generateBytesLaporanBerkala() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    String strAwal = DateFormat('dd/MM/yyyy').format(_tglAwal);
    String strAkhir = DateFormat('dd/MM/yyyy').format(_tglAkhir);

    bytes += generator.text(_namaToko.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.text("LAPORAN PENJUALAN", styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text("Periode: $strAwal - $strAkhir", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.row([PosColumn(text: "Total Omzet", width: 6), PosColumn(text: _formatRupiah(metrik['omzet']), width: 6, styles: const PosStyles(align: PosAlign.right))]);
    bytes += generator.row([PosColumn(text: "Total TRX", width: 6), PosColumn(text: "${metrik['total_transaksi']}", width: 6, styles: const PosStyles(align: PosAlign.right))]);
    bytes += generator.row([PosColumn(text: "Laba Bersih", width: 6), PosColumn(text: _formatRupiah(metrik['laba_bersih']), width: 6, styles: const PosStyles(align: PosAlign.right))]);
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
        content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: A