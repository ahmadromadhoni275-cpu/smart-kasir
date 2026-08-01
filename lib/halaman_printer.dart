import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class HalamanPrinter extends StatefulWidget {
  const HalamanPrinter({super.key});

  @override
  State<HalamanPrinter> createState() => _HalamanPrinterState();
}

class _HalamanPrinterState extends State<HalamanPrinter> {
  String infoKoneksi = 'Belum terhubung';
  List<BluetoothInfo> daftarPerangkat = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    cekKoneksi();
  }

  // Mengecek apakah sebelumnya sudah ada printer yang terhubung
  Future<void> cekKoneksi() async {
    try {
      final bool terhubung = await PrintBluetoothThermal.connectionStatus;
      setState(() {
        infoKoneksi = terhubung ? 'Terhubung ke Printer' : 'Belum terhubung';
      });
    } catch (e) {
      debugPrint("Gagal cek koneksi: $e");
    }
  }

  // Mencari perangkat Bluetooth yang sudah dipasangkan (paired) di HP
  Future<void> cariPerangkat() async {
    setState(() {
      isScanning = true;
      daftarPerangkat.clear();
    });
    try {
      final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
      setState(() {
        daftarPerangkat = list;
      });
    } catch (e) {
      debugPrint("Error mencari bluetooth: $e");
    }
    setState(() {
      isScanning = false;
    });
  }

  // Menyambungkan aplikasi ke Printer yang dipilih
  Future<void> hubungkanPrinter(String mac) async {
    setState(() => infoKoneksi = 'Menghubungkan...');
    try {
      final bool terhubung = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      setState(() {
        infoKoneksi = terhubung ? 'Berhasil Terhubung!' : 'Gagal menghubungkan';
      });
    } catch (e) {
      setState(() => infoKoneksi = 'Gagal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.blue[50],
            child: Column(
              children: [
                Icon(
                  infoKoneksi.contains('Terhubung') ? Icons.print : Icons.print_disabled,
                  size: 50,
                  color: infoKoneksi.contains('Terhubung') ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 10),
                Text(
                  'Status: $infoKoneksi',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: isScanning ? null : cariPerangkat,
            icon: isScanning 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.search),
            label: Text(isScanning ? 'Mencari...' : 'Cari Printer Terpasang'),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: daftarPerangkat.isEmpty && !isScanning
                ? const Center(child: Text('Tidak ada perangkat ditemukan.\nPastikan printer sudah di-Pairing di pengaturan Bluetooth HP.', textAlign: TextAlign.center))
                : ListView.builder(
                    itemCount: daftarPerangkat.length,
                    itemBuilder: (context, index) {
                      var device = daftarPerangkat[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth, color: Colors.blueAccent),
                          title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(device.macAdress),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () => hubungkanPrinter(device.macAdress),
                            child: const Text('Hubungkan'),
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
