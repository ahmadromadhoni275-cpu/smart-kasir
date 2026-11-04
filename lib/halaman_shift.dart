import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// Package Cetak
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'tema.dart';
import 'core/services/shift_service.dart';
import 'models/shift_model.dart';
import 'halaman_riwayat_shift.dart';

class HalamanShift extends StatefulWidget {
  const HalamanShift({super.key});

  @override
  State<HalamanShift> createState() => _HalamanShiftState();
}

class _HalamanShiftState extends State<HalamanShift> {
  final ShiftService _shiftService = ShiftService();
  
  bool _isLoading = true;
  ShiftModel? _activeShift;
  
  String _namaKasir = '';
  String _namaCabang = '';

  // Controller Buka Shift
  final TextEditingController _openingCashCtrl = TextEditingController();
  final TextEditingController _openNoteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaKasir = prefs.getString('username') ?? 'Kasir';
      _namaCabang = prefs.getString('nama_toko') ?? 'Toko';
    });
    await _cekShiftAktif();
  }

  Future<void> _cekShiftAktif() async {
    setState(() => _isLoading = true);
    try {
      final shift = await _shiftService.getCurrentShift();
      setState(() => _activeShift = shift);
    } catch (e) {
      _tampilPopupCantik('Error', e.toString().replaceAll('Exception: ', ''), Icons.error, AppColors.error);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  void _tampilPopupCantik(String judul, String pesan, IconData ikon, Color warna, {VoidCallback? aksiTutup}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: warna.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: warna.withOpacity(0.1), shape: BoxShape.circle), child: Icon(ikon, color: warna, size: 48)),
              const SizedBox(height: 20),
              Text(judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 12),
              Text(pesan, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: warna, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (aksiTutup != null) aksiTutup();
                  },
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _prosesBukaShift() async {
    if (_openingCashCtrl.text.isEmpty) {
      _tampilPopupCantik('Input Kosong', 'Harap isi jumlah uang modal awal.', Icons.warning, AppColors.warning);
      return;
    }

    setState(() => _isLoading = true);
    try {
      double openingCash = double.tryParse(_openingCashCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      await _shiftService.openShift(openingCash, _openNoteCtrl.text);
      
      _openingCashCtrl.clear();
      _openNoteCtrl.clear();
      
      _tampilPopupCantik('Shift Terbuka', 'Selamat bertugas! Shift berhasil dibuka.', Icons.check_circle, AppColors.primaryEmerald);
      await _cekShiftAktif(); 
    } catch (e) {
      _tampilPopupCantik('Gagal', e.toString().replaceAll('Exception: ', ''), Icons.error, AppColors.error);
      setState(() => _isLoading = false);
    }
  }

  void _showCashMovementDialog(String type) {
    bool isCashIn = type == 'CASH_IN';
    Color themeColor = isCashIn ? AppColors.smartBlue : AppColors.error;
    
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isProcessing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(isCashIn ? Icons.arrow_downward : Icons.arrow_upward, color: themeColor)),
                      const SizedBox(width: 12),
                      Text(isCashIn ? 'Kas Masuk' : 'Kas Keluar', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(labelText: 'Nominal Kas', prefixText: 'Rp ', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(labelText: 'Keterangan Transaksi', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isProcessing ? null : () => Navigator.pop(context),
                          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : () async {
                            if (descCtrl.text.trim().isEmpty || amountCtrl.text.isEmpty) {
                              setDialogState(() {}); // memicu UI update saja
                              return;
                            }
                            double amount = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                            
                            setDialogState(() => isProcessing = true);
                            try {
                              await _shiftService.recordCashMovement(type, amount, descCtrl.text);
                              if (!mounted) return;
                              Navigator.pop(context);
                              _tampilPopupCantik('Berhasil', isCashIn ? 'Kas masuk berhasil dicatat' : 'Kas keluar berhasil dicatat', Icons.check_circle, themeColor);
                              await _cekShiftAktif();
                            } catch (e) {
                              if (!mounted) return;
                              Navigator.pop(context);
                              _tampilPopupCantik('Gagal', e.toString().replaceAll('Exception: ', ''), Icons.error, AppColors.error);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _tampilkanModalTutupShift() {
    if (_activeShift == null) return;

    final TextEditingController actualCashCtrl = TextEditingController();
    final TextEditingController closeNoteCtrl = TextEditingController();
    
    double expectedCash = _activeShift!.expectedCash;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          double actualCash = double.tryParse(actualCashCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          double difference = actualCash - expectedCash;
          
          Color diffColor = difference < 0 ? AppColors.error : (difference > 0 ? AppColors.greenAccent : AppColors.textSecondary);

          return Container(
            padding: EdgeInsets.only(top: 32, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tutup Shift', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Modal Awal', style: TextStyle(color: AppColors.textSecondary)), Text(_formatRupiah(_activeShift!.openingCash), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))]),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppColors.border)),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Expected Cash', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)), Text(_formatRupiah(expectedCash), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.smartBlue, fontSize: 18))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: actualCashCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.navyActive),
                    decoration: InputDecoration(
                      labelText: 'Uang Fisik di Laci (Actual Cash)',
                      prefixText: 'Rp ',
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                    onChanged: (val) => setModalState(() {}),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: diffColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: diffColor.withOpacity(0.2))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Selisih Kas:', style: TextStyle(color: diffColor, fontWeight: FontWeight.bold)),
                        Text(_formatRupiah(difference), style: TextStyle(color: diffColor, fontWeight: FontWeight.w900, fontSize: 18)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: closeNoteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Catatan Penutupan',
                      alignLabelWithHint: true,
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: isProcessing ? null : () async {
                        if (actualCashCtrl.text.isEmpty) {
                          setModalState(() {});
                          return;
                        }

                        setModalState(() => isProcessing = true);
                        
                        try {
                          final closedShiftData = await _shiftService.closeShift(actualCash, closeNoteCtrl.text);
                          
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          
                          if (closedShiftData.isNotEmpty) {
                            await _cetakLaporanShift(closedShiftData);
                          }
                          
                          _tampilPopupCantik('Shift Selesai', 'Terima kasih atas kerja keras Anda hari ini. Laporan penutupan telah dicetak.', Icons.check_circle, AppColors.primaryEmerald);
                          await _cekShiftAktif(); 
                        } catch (e) {
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          _tampilPopupCantik('Gagal Menutup', e.toString().replaceAll('Exception: ', ''), Icons.error, AppColors.error);
                        }
                      },
                      child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('KONFIRMASI TUTUP SHIFT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      )
    );
  }

  Future<void> _cetakLaporanShift(Map<String, dynamic> data) async {
    if (kIsWeb || Platform.isIOS) return;

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text("LAPORAN SHIFT KASIR", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      bytes += generator.text(_namaCabang.toUpperCase(), styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.row([PosColumn(text: "Kasir", width: 4), PosColumn(text: ": $_namaKasir", width: 8)]);
      
      String startTime = data['opened_at'] != null ? DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(data['opened_at']).toLocal()) : '-';
      String endTime = data['closed_at'] != null ? DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(data['closed_at']).toLocal()) : DateFormat('dd/MM/yy HH:mm').format(DateTime.now());
      
      bytes += generator.row([PosColumn(text: "Mulai", width: 4), PosColumn(text: ": $startTime", width: 8)]);
      bytes += generator.row([PosColumn(text: "Selesai", width: 4), PosColumn(text: ": $endTime", width: 8)]);
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

      double openingCash = double.tryParse(data['opening_cash'].toString()) ?? 0;
      double expectedCash = double.tryParse(data['expected_cash'].toString()) ?? 0;
      double actualCash = double.tryParse(data['actual_cash'].toString()) ?? 0;
      double difference = double.tryParse(data['difference'].toString()) ?? 0;

      bytes += generator.row([PosColumn(text: "Modal Awal", width: 7), PosColumn(text: _formatRupiah(openingCash), width: 5, styles: const PosStyles(align: PosAlign.right))]);
      
      double totalPenerimaan = expectedCash - openingCash;
      bytes += generator.row([PosColumn(text: "Mutasi/Jual", width: 7), PosColumn(text: _formatRupiah(totalPenerimaan), width: 5, styles: const PosStyles(align: PosAlign.right))]);
      
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.row([PosColumn(text: "KAS HARAPAN", width: 7, styles: const PosStyles(bold: true)), PosColumn(text: _formatRupiah(expectedCash), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true))]);
      bytes += generator.row([PosColumn(text: "KAS AKTUAL", width: 7, styles: const PosStyles(bold: true)), PosColumn(text: _formatRupiah(actualCash), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true))]);
      
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      
      String labelSelisih = difference == 0 ? "SEIMBANG" : difference > 0 ? "LEBIH" : "KURANG";
      bytes += generator.row([PosColumn(text: "SELISIH ($labelSelisih)", width: 7, styles: const PosStyles(bold: true)), PosColumn(text: _formatRupiah(difference.abs()), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true))]);
      
      bytes += generator.feed(2);
      bytes += generator.text("Ttd. Kasir", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(1);
      bytes += generator.text("_________________", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);

      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected) {
        await PrintBluetoothThermal.writeBytes(bytes);
      }
    } catch (e) {
      debugPrint("Gagal cetak shift: $e");
    }
  }

  Widget _buildOpenShiftView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.lock_clock, color: AppColors.smartBlue, size: 24)),
                  const SizedBox(width: 16),
                  const Text('Buka Shift Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                ],
              ),
              const SizedBox(height: 24),
              
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Cabang', style: TextStyle(color: AppColors.textSecondary)), Text(_namaCabang, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kasir', style: TextStyle(color: AppColors.textSecondary)), Text(_namaKasir, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.border)),

              const Text('Modal Awal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _openingCashCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  filled: true, fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Catatan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: _openNoteCtrl,
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  onPressed: _prosesBukaShift,
                  child: const Text('BUKA SHIFT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveShiftView() {
    DateTime openedAt = DateTime.parse(_activeShift!.openedAt).toLocal();
    String formattedDate = DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(openedAt);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: AppColors.primaryEmerald.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.greenAccent.withOpacity(0.2))), child: const Text('🟢 SHIFT AKTIF', style: TextStyle(color: AppColors.greenAccent, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12))),
              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Cabang', style: TextStyle(color: AppColors.textSecondary)), Text(_namaCabang, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kasir', style: TextStyle(color: AppColors.textSecondary)), Text(_namaKasir, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Waktu Mulai', style: TextStyle(color: AppColors.textSecondary)), Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))]),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: AppColors.border)),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryEmerald, Color(0xFF107A4D)]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primaryEmerald.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kas Seharusnya (Dalam Laci)', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(_formatRupiah(_activeShift!.expectedCash), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    const Divider(color: Colors.white24, height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Modal Awal', style: TextStyle(color: Colors.white70)),
                        Text(_formatRupiah(_activeShift!.openingCash), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCashMovementDialog('CASH_IN'),
                      icon: const Icon(Icons.arrow_downward, color: AppColors.smartBlue, size: 18),
                      label: const Text('Kas Masuk', style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.smartBlue.withOpacity(0.1), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCashMovementDialog('CASH_OUT'),
                      icon: const Icon(Icons.arrow_upward, color: AppColors.error, size: 18),
                      label: const Text('Kas Keluar', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error.withOpacity(0.1), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _tampilkanModalTutupShift,
                  child: const Text('TUTUP SHIFT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Manajemen Shift', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.navyActive),
            tooltip: 'Riwayat Shift',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanRiwayatShift()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _activeShift == null ? _buildOpenShiftView() : _buildActiveShiftView(),
            ),
    );
  }
}
