import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:io';

class HalamanShift extends StatefulWidget {
  const HalamanShift({super.key});

  @override
  State<HalamanShift> createState() => _HalamanShiftState();
}

class _HalamanShiftState extends State<HalamanShift> {
  final String baseUrl = 'https://smartkasir.shop/api';
  bool isLoading = false;
  
  // Variabel Sesi User & Toko
  int tokoId = 1;
  int userId = 1;
  String namaKasir = 'Kasir';

  // Variabel Data Shift
  bool isShiftBuka = false;
  int shiftId = 0; // Didapat dari database saat shift aktif
  int modalAwal = 0;
  String waktuBuka = '';

  // Data dari API Rekap Harian
  int totalTunaiSistem = 0;
  int totalNonTunaiSistem = 0;

  // Controller Input
  TextEditingController modalAwalCtrl = TextEditingController();
  TextEditingController uangFisikCtrl = TextEditingController();
  TextEditingController catatanShiftCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  // 1. Ambil ID User dan Toko yang sedang login
  Future<void> _inisialisasiData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    tokoId = prefs.getInt('toko_id') ?? 1;
    userId = prefs.getInt('user_id') ?? 1;
    namaKasir = prefs.getString('username') ?? 'Kasir';

    await _cekStatusShiftApi();
  }

  // 2. Cek ke Database (API) apakah user ini punya shift yang sedang berjalan
  Future<void> _cekStatusShiftApi() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/shift/status/$tokoId/$userId'),
          headers: {'ngrok-skip-browser-warning': 'true'});
          
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        
        if (res['status'] == true && res['data'] != null) {
          // Shift sedang berjalan
          setState(() {
            isShiftBuka = true;
            shiftId = int.parse(res['data']['id'].toString());
            modalAwal = int.parse(res['data']['modal_awal'].toString());
            
            // Format waktu dari database ke format cantik
            DateTime parsedDate = DateTime.parse(res['data']['waktu_buka']);
            waktuBuka = DateFormat('dd MMM yyyy, HH:mm').format(parsedDate);
          });
          
          // Karena shift buka, tarik juga data total pendapatan hari ini
          await _tarikTunaiSistem();
        } else {
          // Tidak ada shift aktif
          setState(() {
            isShiftBuka = false;
            shiftId = 0;
            modalAwal = 0;
            waktuBuka = '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error cek status shift: $e');
    }
    setState(() => isLoading = false);
  }

  // 3. Tarik omset / rekap uang hari ini
  Future<void> _tarikTunaiSistem() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rekap'),
          headers: {'ngrok-skip-browser-warning': 'true'});
          
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final totals = data['totals'];
        setState(() {
          totalTunaiSistem = int.tryParse(totals['tunai'].toString() == 'null' ? '0' : totals['tunai'].toString()) ?? 0;
          totalNonTunaiSistem = int.tryParse(totals['non_tunai'].toString() == 'null' ? '0' : totals['non_tunai'].toString()) ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error get rekap tunai: $e');
    }
  }

  // 4. POST: Kirim data buka shift ke API
  Future<void> _prosesBukaShift() async {
    if (modalAwalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modal awal tidak boleh kosong!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);
    int inputModal = int.tryParse(modalAwalCtrl.text) ?? 0;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shift/buka'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'toko_id': tokoId,
          'user_id': userId,
          'modal_awal': inputModal
        })
      );

      final res = json.decode(response.body);
      
      if (response.statusCode == 201 && res['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift Kasir Berhasil Dibuka!'), backgroundColor: Colors.green),
        );
        modalAwalCtrl.clear();
        await _cekStatusShiftApi(); // Refresh halaman agar masuk ke mode Tutup Shift
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal membuka shift'), backgroundColor: Colors.red));
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error server saat membuka shift'), backgroundColor: Colors.red));
    }
  }

  // 5. Validasi sebelum hitung dan tutup
  void _konfirmasiTutupShift() {
    int uangFisik = int.tryParse(uangFisikCtrl.text) ?? 0;
    int uangSeharusnya = modalAwal + totalTunaiSistem; 
    int selisih = uangFisik - uangSeharusnya;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Tutup Shift', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modal Awal Laci: ${_formatRp(modalAwal)}', style: const TextStyle(color: Colors.grey)),
            Text('Total Tunai Masuk: ${_formatRp(totalTunaiSistem)}', style: const TextStyle(color: Colors.grey)),
            const Divider(thickness: 1),
            Text('Sistem Seharusnya: ${_formatRp(uangSeharusnya)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Fisik Laci: ${_formatRp(uangFisik)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const Divider(thickness: 1),
            Text(
              selisih == 0 
                ? 'STATUS: BALANCE (SESUAI) ✅' 
                : selisih > 0 
                  ? 'STATUS: LEBIH ${_formatRp(selisih)} ⚠️' 
                  : 'STATUS: MINUS / KURANG ${_formatRp(selisih.abs())} ❌',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: selisih == 0 ? Colors.green : Colors.red
              )
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text('Info: Ada transaksi Non-Tunai sebesar ${_formatRp(totalNonTunaiSistem)} yang langsung masuk ke rekening.', 
                style: const TextStyle(fontSize: 10, color: Colors.purple, fontStyle: FontStyle.italic)),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal')
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _prosesTutupShift(uangFisik, uangSeharusnya, selisih);
            },
            child: const Text('Tutup & Cetak', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 6. POST: Kirim data tutup shift ke API, jika berhasil baru cetak Struk
  Future<void> _prosesTutupShift(int uangFisik, int uangSeharusnya, int selisih) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    String catatan = catatanShiftCtrl.text.isEmpty ? '-' : catatanShiftCtrl.text;

    try {
      // A. Simpan Data ke Database Server
      final response = await http.post(
        Uri.parse('$baseUrl/shift/tutup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'shift_id': shiftId,
          'total_tunai_sistem': totalTunaiSistem,
          'total_non_tunai_sistem': totalNonTunaiSistem,
          'uang_fisik': uangFisik,
          'selisih': selisih,
          'catatan': catatan
        })
      );

      final res = json.decode(response.body);

      if (response.statusCode == 200 && res['status'] == true) {
        // B. Jika Sukses Simpan ke Database, Mulai Mencetak Struk
        await _cetakStrukShift(uangFisik, uangSeharusnya, selisih, catatan);
        
        uangFisikCtrl.clear();
        catatanShiftCtrl.clear();

        if (mounted) Navigator.pop(context); // Tutup Loading
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift Berhasil Ditutup & Tersimpan di Sistem!'), backgroundColor: Colors.green));
        
        // Refresh Halaman (Akan kembali ke form Buka Shift)
        await _cekStatusShiftApi();
      } else {
        if (mounted) Navigator.pop(context); // Tutup Loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal menutup shift'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error jaringan saat menutup shift'), backgroundColor: Colors.red));
    }
  }

  // 7. Logika Cetak Printer
  Future<void> _cetakStrukShift(int uangFisik, int uangSeharusnya, int selisih, String catatan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String waktuTutup = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
      String ipPrinter = prefs.getString('ip_printer') ?? '';
      String macPrinter = prefs.getString('mac_printer') ?? '';

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text("LAPORAN TUTUP SHIFT", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text("Kasir: $namaKasir", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
     bytes += generator.text("Buka : $waktuBuka", styles: const PosStyles(align: PosAlign.left));
      bytes += generator.text("Tutup: $waktuTutup", styles: const PosStyles(align: PosAlign.left, fontSize: PosFontSize.size1));
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.row([PosColumn(text: "Modal Awal", width: 6), PosColumn(text: _formatRp(modalAwal), width: 6, styles: const PosStyles(align: PosAlign.right))]);
      bytes += generator.row([PosColumn(text: "Tunai Masuk", width: 6), PosColumn(text: _formatRp(totalTunaiSistem), width: 6, styles: const PosStyles(align: PosAlign.right))]);
      bytes += generator.row([PosColumn(text: "Non-Tunai", width: 6), PosColumn(text: _formatRp(totalNonTunaiSistem), width: 6, styles: const PosStyles(align: PosAlign.right))]);
      
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.row([PosColumn(text: "Sistem (Harus)", width: 6, styles: const PosStyles(bold: true)), PosColumn(text: _formatRp(uangSeharusnya), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true))]);
      bytes += generator.row([PosColumn(text: "Fisik (Laci)", width: 6, styles: const PosStyles(bold: true)), PosColumn(text: _formatRp(uangFisik), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true))]);
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      
      String status = selisih == 0 ? "BALANCE" : selisih > 0 ? "LEBIH" : "KURANG";
      bytes += generator.row([PosColumn(text: "Selisih ($status)", width: 6), PosColumn(text: _formatRp(selisih.abs()), width: 6, styles: const PosStyles(align: PosAlign.right))]);
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      
      bytes += generator.text("Catatan:", styles: const PosStyles(bold: true));
      bytes += generator.text(catatan, styles: const PosStyles(align: PosAlign.left));
      bytes += generator.feed(2);

      // --- Coba cetak ke Bluetooth, lalu LAN ---
      bool terhubungBluetooth = await PrintBluetoothThermal.connectionStatus;
      if (terhubungBluetooth) {
        await PrintBluetoothThermal.writeBytes(bytes);
      } else if (macPrinter.isNotEmpty) {
        bool terhubungUlang = await PrintBluetoothThermal.connect(macPrinterAddress: macPrinter);
        if (terhubungUlang) await PrintBluetoothThermal.writeBytes(bytes);
      } else if (ipPrinter.isNotEmpty) {
        final socket = await Socket.connect(ipPrinter, 9100, timeout: const Duration(seconds: 3));
        socket.add(bytes);
        socket.destroy();
      }
    } catch (e) {
      debugPrint("Gagal cetak fisik: $e");
    }
  }

  String _formatRp(int angka) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(angka);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Manajemen Shift Kasir', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isShiftBuka ? Colors.green : Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: !isShiftBuka ? _buildFormBukaShift() : _buildFormTutupShift(),
          ),
    );
  }

  Widget _buildFormBukaShift() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_clock, size: 80, color: Colors.blueAccent),
        const SizedBox(height: 20),
        const Text('Shift Anda Belum Dibuka', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Masukkan nominal uang kembalian (modal awal) yang ada di laci kasir saat ini.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        
        TextField(
          controller: modalAwalCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Modal Awal Laci (Rp)',
            prefixIcon: const Icon(Icons.money, color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            onPressed: _prosesBukaShift,
            child: const Text('Buka Shift Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        )
      ],
    );
  }

  Widget _buildFormTutupShift() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green.shade300)
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shift Aktif', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 18)),
                      Text('Dibuka pada: $waktuBuka', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Sistem Saat Ini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Modal Awal:'),
                      Text(_formatRp(modalAwal), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Penjualan Tunai Laci:'),
                      Text(_formatRp(totalTunaiSistem), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Non-Tunai (Ke Rekening):', style: TextStyle(color: Colors.grey)),
                      Text(_formatRp(totalNonTunaiSistem), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Divider(thickness: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target Uang Fisik Laci:', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      Text(_formatRp(modalAwal + totalTunaiSistem), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          const Text('Hitung Uang Fisik', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text('Masukkan jumlah fisik uang yang ada di laci saat ini', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          
          TextField(
            controller: uangFisikCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: 'Total Uang Fisik Laci (Rp)',
              prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.orange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: catatanShiftCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Catatan tambahan (Opsional)\nCth: Minus karena kurang kembalian 2rb...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () {
                if (uangFisikCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang fisik wajib diisi!'), backgroundColor: Colors.red));
                  return;
                }
                _konfirmasiTutupShift();
              },
              icon: const Icon(Icons.lock, color: Colors.white),
              label: const Text('Validasi & Tutup Shift', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }
}
