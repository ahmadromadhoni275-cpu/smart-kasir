import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';
import 'services/api_service.dart';

class HalamanShift extends StatefulWidget {
  const HalamanShift({super.key});

  @override
  State<HalamanShift> createState() => _HalamanShiftState();
}

class _HalamanShiftState extends State<HalamanShift> {
  bool _isLoading = true;
  Map<String, dynamic>? _activeShift;
  
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
      _namaCabang = prefs.getString('nama_toko') ?? 'Cabang';
    });
    await _cekShiftAktif();
  }

  Future<void> _cekShiftAktif() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('shifts/current');
      if (response.statusCode == 200) {
        final resData = json.decode(response.body);
        setState(() {
          _activeShift = resData['data']; // null jika tidak ada shift aktif
        });
      }
    } catch (e) {
      _showNotif('Gagal memuat status shift', AppColors.error);
    }
    setState(() => _isLoading = false);
  }

  String _formatRupiah(num angka) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(angka);

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: warna, behavior: SnackBarBehavior.floating));
  }

  // =========================================================
  // AKSI API: BUKA SHIFT
  // =========================================================
  Future<void> _prosesBukaShift() async {
    if (_openingCashCtrl.text.isEmpty) {
      _showNotif('Modal awal wajib diisi', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'opening_cash': double.tryParse(_openingCashCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        'notes': _openNoteCtrl.text.isEmpty ? null : _openNoteCtrl.text,
      };

      final response = await ApiService.post('shifts/open', payload);
      final resData = json.decode(response.body);

      if (response.statusCode == 201) {
        _showNotif('Shift berhasil dibuka!', AppColors.greenAccent);
        _openingCashCtrl.clear();
        _openNoteCtrl.clear();
        await _cekShiftAktif(); // Refresh tampilan ke mode Shift Aktif
      } else {
        _showNotif(resData['message'] ?? 'Gagal membuka shift', AppColors.error);
      }
    } catch (e) {
      _showNotif('Terjadi kesalahan sistem', AppColors.error);
    }
    setState(() => _isLoading = false);
  }

  // =========================================================
  // MODAL & AKSI API: TUTUP SHIFT (Dengan Hitung Selisih Real-time)
  // =========================================================
  void _tampilkanModalTutupShift() {
    if (_activeShift == null) return;

    final TextEditingController actualCashCtrl = TextEditingController();
    final TextEditingController closeNoteCtrl = TextEditingController();
    
    double expectedCash = double.parse(_activeShift!['expected_cash'].toString());
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
            padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tutup Shift', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 24),

                  // Ringkasan Sistem
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Modal Awal', style: TextStyle(color: AppColors.textSecondary)), Text(_formatRupiah(double.parse(_activeShift!['opening_cash'].toString())), style: const TextStyle(fontWeight: FontWeight.bold))]),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Expected Cash (Sistem)', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)), Text(_formatRupiah(expectedCash), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 16))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Kasir
                  TextField(
                    controller: actualCashCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Uang Fisik di Laci (Actual Cash)',
                      prefixText: 'Rp ',
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setModalState(() {}), // Trigger hitung ulang selisih
                  ),
                  const SizedBox(height: 16),

                  // Indikator Selisih Real-time
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: diffColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Selisih:', style: TextStyle(color: diffColor, fontWeight: FontWeight.bold)),
                        Text(_formatRupiah(difference), style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: closeNoteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Catatan Penutupan (Opsional)',
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: isProcessing ? null : () async {
                        if (actualCashCtrl.text.isEmpty) {
                          _showNotif('Uang fisik wajib diisi', AppColors.error);
                          return;
                        }

                        setModalState(() => isProcessing = true);
                        
                        try {
                          final payload = {
                            'actual_cash': actualCash,
                            'notes': closeNoteCtrl.text.isEmpty ? null : closeNoteCtrl.text,
                          };

                          final res = await ApiService.post('shifts/${_activeShift!['shift_id']}/close', payload);
                          final resData = json.decode(res.body);

                          if (res.statusCode == 200) {
                            Navigator.pop(ctx);
                            _showNotif('Shift berhasil ditutup dan laporan tersimpan', AppColors.greenAccent);
                            await _cekShiftAktif();
                          } else {
                            _showNotif(resData['message'] ?? 'Gagal menutup shift', AppColors.error);
                            setModalState(() => isProcessing = false);
                          }
                        } catch (e) {
                          _showNotif('Terjadi kesalahan jaringan', AppColors.error);
                          setModalState(() => isProcessing = false);
                        }
                      },
                      child: isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('KONFIRMASI TUTUP SHIFT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // =========================================================
  // UI: STATE 1 - FORM BUKA SHIFT
  // =========================================================
  Widget _buildOpenShiftView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_clock, color: AppColors.navyActive, size: 28),
                  SizedBox(width: 12),
                  Text('Buka Shift Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                ],
              ),
              const SizedBox(height: 24),
              
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Cabang', style: TextStyle(color: AppColors.textSecondary)), Text(_namaCabang, style: const TextStyle(fontWeight: FontWeight.bold))]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kasir', style: TextStyle(color: AppColors.textSecondary)), Text(_namaKasir, style: const TextStyle(fontWeight: FontWeight.bold))]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

              TextField(
                controller: _openingCashCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Modal Awal (Rp)',
                  filled: true, fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _openNoteCtrl,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  filled: true, fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _prosesBukaShift,
                  child: const Text('BUKA SHIFT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // UI: STATE 2 - PANEL SHIFT AKTIF
  // =========================================================
  Widget _buildActiveShiftView() {
    double openingCash = double.parse(_activeShift!['opening_cash'].toString());
    double expectedCash = double.parse(_activeShift!['expected_cash'].toString());
    double pergerakanKas = expectedCash - openingCash; // Penjualan Cash + Cash In - Cash Out

    // Format Tanggal Buka
    DateTime openedAt = DateTime.parse(_activeShift!['opened_at']).toLocal();
    String formattedDate = DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(openedAt);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border), boxShadow: [BoxShadow(color: AppColors.primaryEmerald.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: const Text('🟢 SHIFT AKTIF', style: TextStyle(color: AppColors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 1))),
              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Cabang', style: TextStyle(color: AppColors.textSecondary)), Text(_namaCabang, style: const TextStyle(fontWeight: FontWeight.bold))]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Kasir', style: TextStyle(color: AppColors.textSecondary)), Text(_namaKasir, style: const TextStyle(fontWeight: FontWeight.bold))]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Waktu Mulai', style: TextStyle(color: AppColors.textSecondary)), Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold))]),
              
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Modal Awal', style: TextStyle(color: AppColors.textSecondary)), Text(_formatRupiah(openingCash), style: const TextStyle(fontWeight: FontWeight.bold))]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Pergerakan Kas', style: TextStyle(color: AppColors.textSecondary)), Text(pergerakanKas >= 0 ? '+ ${_formatRupiah(pergerakanKas)}' : _formatRupiah(pergerakanKas), style: TextStyle(fontWeight: FontWeight.bold, color: pergerakanKas >= 0 ? AppColors.greenAccent : AppColors.error))]),
              
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Expected Cash', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    Text(_formatRupiah(expectedCash), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryEmerald)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manajemen Shift', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
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
