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
  // Status Printer Bluetooth
  String macPrinterTersimpan = '';
  String namaPrinterTersimpan = '';
  bool isBluetoothConnected = false;
  List<BluetoothInfo> perangkatBluetooth = [];
  bool isMencariBluetooth = false;

  // Status Printer WiFi / LAN
  TextEditingController ipPrinterCtrl = TextEditingController();

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
      ipPrinterCtrl.text = prefs.getString('ip_printer') ?? '';
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
      Navigator.pop(context); // Tutup loading

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
      Navigator.pop(context); // Tutup loading
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

      bytes += generator.text("TES PRINTER BLUETOOTH", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text("Koneksi Sukses!", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("Smart Kasir System", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);

      await PrintBluetoothThermal.writeBytes(bytes);
      _tampilPesan('Cetak tes berhasil!', Colors.green);
    } catch (e) {
      _tampilPesan('Gagal mencetak. Error: $e', Colors.red);
    }
  }

  // ==============================================================
  // 3. FUNGSI PRINTER WIFI/LAN (Untuk Dapur / Bar / Rekap Jarak Jauh)
  // ==============================================================
  Future<void> _simpanIpWifi() async {
    if (ipPrinterCtrl.text.isEmpty) {
      _tampilPesan('IP Printer tidak boleh kosong', Colors.red);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip_printer', ipPrinterCtrl.text);
    _tampilPesan('IP Printer Jaringan Berhasil Disimpan', Colors.green);
  }

  Future<void> _tesPrintWifi() async {
    String ip = ipPrinterCtrl.text;
    if (ip.isEmpty) {
      _tampilPesan('Simpan IP Printer terlebih dahulu!', Colors.red);
      return;
    }

    _tampilLoading('Mengirim perintah ke $ip...');
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text("TES PRINTER WIFI / LAN", styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text("Koneksi Jaringan Sukses!", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("IP: $ip", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);

      // Kirim via Socket LAN
      final socket = await Socket.connect(ip, 9100, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      socket.destroy();

      Navigator.pop(context); // Tutup loading
      _tampilPesan('Cetak tes jaringan berhasil!', Colors.green);
    } catch (e) {
      Navigator.pop(context); // Tutup loading
      _tampilPesan('Gagal terhubung ke IP. Cek koneksi WiFi/LAN.', Colors.red);
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
        title: const Text('Pengaturan Printer', style: TextStyle(fontWeight: FontWeight.bold)),
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
            const Text('Printer Utama (Bluetooth)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bluetooth_connected, size: 40, color: isBluetoothConnected ? Colors.green : Colors.grey),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status Koneksi:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(isBluetoothConnected ? 'Terhubung' : 'Tidak Terhubung', 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isBluetoothConnected ? Colors.green : Colors.red)),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12)
                            ),
                            onPressed: _cariPerangkatBluetooth,
                            icon: const Icon(Icons.search, color: Colors.white, size: 18),
                            label: const Text('Cari Printer', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBluetoothConnected ? Colors.green : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 12)
                            ),
                            onPressed: isBluetoothConnected ? _tesPrintBluetooth : null,
                            icon: const Icon(Icons.print, color: Colors.white, size: 18),
                            label: const Text('Tes Print', style: TextStyle(color: Colors.white)),
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
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10)
                        ),
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
            // KARTU 2: PRINTER WIFI / LAN (DAPUR / BAR)
            // ===============================================
            const Text('Printer Jaringan (WiFi / LAN)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Text('Biasanya digunakan untuk cetak struk Dapur atau Jarak Jauh', style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: ipPrinterCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Alamat IP Printer (Contoh: 192.168.1.100)',
                        prefixIcon: const Icon(Icons.wifi, color: Colors.teal),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 12)
                            ),
                            onPressed: _simpanIpWifi,
                            icon: const Icon(Icons.save, color: Colors.white, size: 18),
                            label: const Text('Simpan IP', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 12)
                            ),
                            onPressed: _tesPrintWifi,
                            icon: const Icon(Icons.print, color: Colors.white, size: 18),
                            label: const Text('Tes Print LAN', style: TextStyle(color: Colors.white)),
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
              child: Text('Data printer tersimpan di perangkat ini.\nBeda HP Kasir, beda pengaturan printer.', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
            )
          ],
        ),
      ),
    );
  }
}
