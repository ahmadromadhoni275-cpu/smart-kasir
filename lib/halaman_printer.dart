import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'dart:io';

class HalamanPrinter extends StatefulWidget {
  const HalamanPrinter({super.key});

  @override
  State<HalamanPrinter> createState() => _HalamanPrinterState();
}

class _HalamanPrinterState extends State<HalamanPrinter> {
  // Status Printer Bluetooth (Kasir)
  String macPrinterTersimpan = '';
  String namaPrinterTersimpan = '';
  bool isBluetoothConnected = false;
  List<BluetoothInfo> perangkatBluetooth = [];
  bool isMencariBluetooth = false;

  // Status Printer WiFi / LAN (Dapur & Bar)
  TextEditingController ipDapurCtrl = TextEditingController();
  TextEditingController ipBarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muatPengaturanPrinter();
  }

  // ==============================================================
  // 1. MUAT PENGATURAN DARI MEMORI HP
  // ==============================================================
  Future<void> _muatPengaturanPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      macPrinterTersimpan = prefs.getString('mac_printer') ?? '';
      namaPrinterTersimpan = prefs.getString('nama_printer') ?? 'Belum ada printer';
      
      // Load IP masing-masing divisi
      ipDapurCtrl.text = prefs.getString('ip_printer_dapur') ?? '';
      ipBarCtrl.text = prefs.getString('ip_printer_bar') ?? '';
    });

    // Cek apakah bluetooth masih terhubung
    bool terhubung = await PrintBluetoothThermal.connectionStatus;
    setState(() {
      isBluetoothConnected = terhubung;
    });
  }

  // ==============================================================
  // 2. FUNGSI PRINTER BLUETOOTH (Untuk Kasir Utama)
  // ==============================================================
  Future<void> _cariPerangkatBluetooth() async {
    setState(() {
      isMencariBluetooth = true;
    });
    try {
      List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      setState(() {
        perangkatBluetooth = devices;
        isMencariBluetooth = false;
      });
      if (devices.isEmpty) {
        _tampilPesan('Tidak ada perangkat bluetooth tersambung di HP ini.', Colors.orange);
      }
    } catch (e) {
      setState(() { isMencariBluetooth = false; });
      _tampilPesan('Gagal mencari bluetooth. Pastikan Bluetooth HP menyala.', Colors.red);
    }
  }

  Future<void> _hubungkanBluetooth(String mac, String nama) async {
    _tampilLoading('Menghubungkan ke $nama...');
    try {
      bool terhubung = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      Navigator.pop(context); 

      if (terhubung) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mac_printer', mac);
        await prefs.setString('nama_printer', nama);

        setState(() {
          isBluetoothConnected = true;
          macPrinterTersimpan = mac;
          namaPrinterTersimpan = nama;
        });
        _tampilPesan('Berhasil terhubung ke $nama', Colors.green);
      } else {
        _tampilPesan('Gagal terhubung. Pastikan printer menyala.', Colors.red);
      }
    } catch (e) {
      Navigator.pop(context); 
      _tampilPesan('Error koneksi bluetooth.', Colors.red);
    }
  }

  Future<void> _tesPrintBluetooth() async {
    if (!isBluetoothConnected) {
      _tampilPesan('Printer bluetooth belum terhubung!', Colors.red);
      return;
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text("TES PRINTER KASIR", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text("Koneksi Sukses!", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("Divisi: KASIR UTAMA", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);

      await PrintBluetoothThermal.writeBytes(bytes);
      _tampilPesan('Cetak tes kasir berhasil!', Colors.green);
    } catch (e) {
      _tampilPesan('Gagal mencetak. Error: $e', Colors.red);
    }
  }

  // ==============================================================
  // 3. FUNGSI PRINTER WIFI/LAN (Untuk Dapur & Bar)
  // ==============================================================
  Future<void> _simpanIpWifi(String divisi, String ip) async {
    if (ip.isEmpty) {
      _tampilPesan('IP Printer $divisi tidak boleh kosong', Colors.red);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    
    if (divisi == 'DAPUR') {
      await prefs.setString('ip_printer_dapur', ip);
    } else if (divisi == 'BAR') {
      await prefs.setString('ip_printer_bar', ip);
    }
    
    _tampilPesan('IP Printer $divisi Berhasil Disimpan', Colors.green);
  }

  Future<void> _tesPrintWifi(String divisi, String ip) async {
    if (ip.isEmpty) {
      _tampilPesan('Simpan IP Printer $divisi terlebih dahulu!', Colors.red);
      return;
    }

    _tampilLoading('Mengirim perintah ke $ip...');
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text("TES PRINTER $divisi", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text("Koneksi Jaringan Sukses!", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("IP: $ip", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);

      // Kirim via Socket LAN
      final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      socket.destroy();

      Navigator.pop(context); 
      _tampilPesan('Cetak tes $divisi berhasil!', Colors.green);
    } catch (e) {
      Navigator.pop(context); 
      _tampilPesan('Gagal terhubung ke $ip. Cek jaringan/kabel LAN printer.', Colors.red);
    }
  }

  // ==============================================================
  // UTILS
  // ==============================================================
  void _tampilPesan(String pesan, Color warna) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan), backgroundColor: warna));
  }

  void _tampilLoading(String pesan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(pesan)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pengaturan Multi-Printer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===============================================
            // KARTU 1: PRINTER BLUETOOTH (STRUK KASIR)
            // ===============================================
            const Text('1. Printer Kasir (Struk Utama)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Text('Koneksi Bluetooth, cetak seluruh ringkasan pesanan.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bluetooth_connected, size: 40, color: isBluetoothConnected ? Colors.blueAccent : Colors.grey),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status Koneksi:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(isBluetoothConnected ? 'Terhubung' : 'Tidak Terhubung', 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isBluetoothConnected ? Colors.blueAccent : Colors.red)),
                              Text(namaPrinterTersimpan, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: _cariPerangkatBluetooth,
                            icon: const Icon(Icons.search, color: Colors.white, size: 18),
                            label: const Text('Cari', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: isBluetoothConnected ? Colors.green : Colors.grey, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: isBluetoothConnected ? _tesPrintBluetooth : null,
                            icon: const Icon(Icons.print, color: Colors.white, size: 18),
                            label: const Text('Tes', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),

                    if (isMencariBluetooth)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    if (perangkatBluetooth.isNotEmpty) ...[
                      const Divider(height: 30),
                      const Text('Perangkat Ditemukan (Pilih untuk menyambung):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(color: Colors.grey[50], border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                        child: ListView.builder(
                          itemCount: perangkatBluetooth.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.print, color: Colors.black54),
                              title: Text(perangkatBluetooth[index].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(perangkatBluetooth[index].macAdress, style: const TextStyle(fontSize: 10)),
                              trailing: const Icon(Icons.link, color: Colors.blueAccent),
                              onTap: () => _hubungkanBluetooth(perangkatBluetooth[index].macAdress, perangkatBluetooth[index].name),
                            );
                          },
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ===============================================
            // KARTU 2: PRINTER DAPUR (WIFI / LAN)
            // ===============================================
            const Text('2. Printer Dapur (Makanan)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Text('Koneksi Jaringan (LAN/Wi-Fi). Hanya mencetak item divisi "dapur".', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: ipDapurCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'IP Printer Dapur (Cth: 192.168.1.10)',
                        prefixIcon: const Icon(Icons.soup_kitchen, color: Colors.deepOrange),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () => _simpanIpWifi('DAPUR', ipDapurCtrl.text),
                            icon: const Icon(Icons.save, color: Colors.white, size: 18),
                            label: const Text('Simpan IP', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () => _tesPrintWifi('DAPUR', ipDapurCtrl.text),
                            icon: const Icon(Icons.print, color: Colors.white, size: 18),
                            label: const Text('Tes Print', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ===============================================
            // KARTU 3: PRINTER BAR (WIFI / LAN)
            // ===============================================
            const Text('3. Printer Bar (Minuman)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Text('Koneksi Jaringan (LAN/Wi-Fi). Hanya mencetak item divisi "bar".', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade300)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: ipBarCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'IP Printer Bar (Cth: 192.168.1.11)',
                        prefixIcon: const Icon(Icons.local_cafe, color: Colors.brown),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () => _simpanIpWifi('BAR', ipBarCtrl.text),
                            icon: const Icon(Icons.save, color: Colors.white, size: 18),
                            label: const Text('Simpan IP', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () => _tesPrintWifi('BAR', ipBarCtrl.text),
                            icon: const Icon(Icons.print, color: Colors.white, size: 18),
                            label: const Text('Tes Print', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            Center(
              child: Text('Data IP tersimpan di perangkat ini.\nBeda HP Kasir, beda IP tujuan.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
            )
          ],
        ),
      ),
    );
  }
}
