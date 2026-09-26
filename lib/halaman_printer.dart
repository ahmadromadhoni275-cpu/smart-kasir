import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'tema.dart'; // Import tema eksklusif

class HalamanPrinter extends StatefulWidget {
  const HalamanPrinter({super.key});

  @override
  State<HalamanPrinter> createState() => _HalamanPrinterState();
}

class _HalamanPrinterState extends State<HalamanPrinter> {
  bool _isScanning = false;
  bool _isTesting = false;
  
  List<BluetoothInfo> _perangkatBluetooth = [];
  String _macTersimpan = '';
  
  final TextEditingController _ipDapurCtrl = TextEditingController();
  final TextEditingController _ipBarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muatPengaturanPrinter();
  }

  Future<void> _muatPengaturanPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Sinkronisasi dengan key dari halaman struk
      _macTersimpan = prefs.getString('printer_alamat_utama') ?? prefs.getString('mac_printer') ?? '';
      _ipDapurCtrl.text = prefs.getString('ip_printer_dapur') ?? '';
      _ipBarCtrl.text = prefs.getString('ip_printer_bar') ?? '';
    });
    
    if (!kIsWeb && !Platform.isIOS) {
      _pindaiPerangkatBluetooth();
    }
  }

  Future<void> _pindaiPerangkatBluetooth() async {
    setState(() => _isScanning = true);
    try {
      final List<BluetoothInfo> listResult = await PrintBluetoothThermal.pairedBluetooths;
      setState(() {
        _perangkatBluetooth = listResult;
      });
    } catch (e) {
      _tampilkanNotif('Gagal memindai Bluetooth: $e', AppColors.red);
    }
    setState(() => _isScanning = false);
  }

  Future<void> _hubungkanDanSimpan(String macAddress, String namaPerangkat) async {
    _tampilkanNotif('Menghubungkan ke $namaPerangkat...', AppColors.smartBlue);
    try {
      bool terhubung = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress)
          .timeout(const Duration(seconds: 8), onTimeout: () => false);

      if (terhubung) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('printer_tipe_utama', 'bluetooth');
        await prefs.setString('printer_alamat_utama', macAddress);
        await prefs.setString('mac_printer', macAddress); // Backup key lama
        
        setState(() => _macTersimpan = macAddress);
        _tampilkanNotif('Printer Utama berhasil diatur ke $namaPerangkat!', AppColors.emerald);
      } else {
        _tampilkanNotif('Gagal terhubung. Pastikan printer menyala.', AppColors.red);
      }
    } catch (e) {
      _tampilkanNotif('Error koneksi: $e', AppColors.red);
    }
  }

  Future<void> _simpanPrinterDivisi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip_printer_dapur', _ipDapurCtrl.text);
    await prefs.setString('ip_printer_bar', _ipBarCtrl.text);
    _tampilkanNotif('Pengaturan printer divisi (WiFi) berhasil disimpan!', AppColors.emerald);
  }

  Future<void> _tesPrint() async {
    if (_macTersimpan.isEmpty) {
      _tampilkanNotif('Pilih printer utama terlebih dahulu!', AppColors.premiumGold);
      return;
    }

    setState(() => _isTesting = true);

    try {
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (!isConnected) {
        isConnected = await PrintBluetoothThermal.connect(macPrinterAddress: _macTersimpan)
            .timeout(const Duration(seconds: 8), onTimeout: () => false);
      }

      if (isConnected) {
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
        List<int> bytes = [];

        bytes += generator.text("TES PRINTER", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
        bytes += generator.text("Koneksi Berhasil!", styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text("Printer siap digunakan untuk transaksi Smart Kasir.", styles: const PosStyles(align: PosAlign.center));
        bytes += generator.feed(2);

        await PrintBluetoothThermal.writeBytes(bytes);
        _tampilkanNotif('Tes print berhasil dikirim!', AppColors.emerald);
      } else {
        _tampilkanNotif('Printer terputus. Silakan hubungkan ulang.', AppColors.red);
      }
    } catch (e) {
      _tampilkanNotif('Gagal tes print: $e', AppColors.red);
    }

    setState(() => _isTesting = false);
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

  // ==========================================
  // WIDGET UTAMA (BODY)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        title: const Text('Pengaturan Printer', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER INFO ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: AppColors.deepNavy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: AppColors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.print, size: 50, color: AppColors.white),
                  ),
                  const SizedBox(height: 15),
                  const Text('Kelola Printer Struk', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white)),
                  const SizedBox(height: 5),
                  Text('Hubungkan printer Bluetooth untuk Kasir, dan setel IP WiFi untuk dapur/bar.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.white.withOpacity(0.7))),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- PRINTER UTAMA (BLUETOOTH) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Printer Kasir (Bluetooth)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
                  if (_isScanning)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))
                  else
                    InkWell(
                      onTap: _pindaiPerangkatBluetooth,
                      child: const Text('Pindai Ulang', style: TextStyle(color: AppColors.smartBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (kIsWeb || Platform.isIOS)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Fitur pencetakan Bluetooth fisik hanya didukung di perangkat Android.', style: TextStyle(color: AppColors.slateGray)),
              )
            else if (_perangkatBluetooth.isEmpty && !_isScanning)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                child: const Center(child: Text('Belum ada perangkat Bluetooth yang dipasangkan (paired).', textAlign: TextAlign.center, style: TextStyle(color: AppColors.slateGray))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _perangkatBluetooth.length,
                itemBuilder: (context, index) {
                  var device = _perangkatBluetooth[index];
                  bool isSelected = device.macAdress == _macTersimpan;

                  return GestureDetector(
                    onTap: () => _hubungkanDanSimpan(device.macAdress, device.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.teal.withOpacity(0.05) : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppColors.teal : Colors.grey.shade200, width: isSelected ? 2 : 1),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: isSelected ? AppColors.teal : AppColors.lightGray, shape: BoxShape.circle),
                            child: Icon(Icons.bluetooth, color: isSelected ? AppColors.white : AppColors.slateGray, size: 20),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(device.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? AppColors.teal : AppColors.darkText)),
                                const SizedBox(height: 4),
                                Text(device.macAdress, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12)),
                              child: const Text('Terpilih', style: TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Tombol Tes Print Kasir
            if (_macTersimpan.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkBlue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isTesting ? null : _tesPrint,
                    icon: _isTesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)) : const Icon(Icons.print, color: AppColors.white, size: 18),
                    label: const Text('Test Print Kasir', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // --- PRINTER DIVISI (WIFI) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text('Printer Divisi / Dapur (WiFi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
            ),
            const SizedBox(height: 15),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPremiumTextField('Alamat IP Printer Dapur', Icons.wifi, _ipDapurCtrl, hint: 'Contoh: 192.168.1.100'),
                  const Divider(height: 30, color: AppColors.lightGray),
                  _buildPremiumTextField('Alamat IP Printer Bar', Icons.wifi, _ipBarCtrl, hint: 'Contoh: 192.168.1.101', isLast: true),
                  
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _simpanPrinterDivisi,
                      child: const Text('Simpan Pengaturan Divisi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTextField(String label, IconData icon, TextEditingController controller, {String hint = '', bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slateGray)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.slateGray, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              filled: true,
              fillColor: AppColors.lightGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
