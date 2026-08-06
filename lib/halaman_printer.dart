import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HalamanPrinter extends StatefulWidget {
  const HalamanPrinter({super.key});

  @override
  State<HalamanPrinter> createState() => _HalamanPrinterState();
}

class _HalamanPrinterState extends State<HalamanPrinter> {
  final String kategoriUrl = 'https://smartkasir.shop/api/kategori';
  
  List daftarKategori = [];
  bool isLoading = true;
  
  // Variabel untuk proses pencarian Bluetooth
  List<BluetoothInfo> daftarPerangkat = [];
  bool isScanning = false;

  // Penampung pengaturan (key: id_slot, value: {tipe, alamat})
  Map<String, Map<String, String>> pengaturanPrinter = {};

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    await ambilDaftarKategori();
    await muatPengaturanLokal();
  }

  // 1. Mengambil Kategori Dinamis dari Server
  Future<void> ambilDaftarKategori() async {
    try {
      final response = await http.get(Uri.parse(kategoriUrl), headers: {'ngrok-skip-browser-warning': 'true'});
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() {
          daftarKategori = res['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error Kategori: $e");
    }
  }

  // 2. Memuat Pengaturan Printer yang Tersimpan di HP
  Future<void> muatPengaturanLokal() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Muat untuk Printer Utama (Kasir)
    pengaturanPrinter['utama'] = {
      'tipe': prefs.getString('printer_tipe_utama') ?? 'bluetooth',
      'alamat': prefs.getString('printer_alamat_utama') ?? '',
    };

    // Muat untuk masing-masing Kategori Dinamis
    for (var kat in daftarKategori) {
      String idKat = kat['id'].toString();
      pengaturanPrinter[idKat] = {
        'tipe': prefs.getString('printer_tipe_cat_$idKat') ?? 'bluetooth',
        'alamat': prefs.getString('printer_alamat_cat_$idKat') ?? '',
      };
    }

    setState(() {
      isLoading = false;
    });
  }

  // 3. Menyimpan Pengaturan ke Memori HP
  Future<void> simpanPengaturan(String idSlot, String tipe, String alamat) async {
    final prefs = await SharedPreferences.getInstance();
    String keySuffix = idSlot == 'utama' ? 'utama' : 'cat_$idSlot';
    
    await prefs.setString('printer_tipe_$keySuffix', tipe);
    await prefs.setString('printer_alamat_$keySuffix', alamat);

    setState(() {
      pengaturanPrinter[idSlot] = {'tipe': tipe, 'alamat': alamat};
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan printer berhasil disimpan!'), backgroundColor: Colors.green),
      );
    }
  }

  // --- FUNGSI BLUETOOTH BAWAAN ANDA ---
  Future<bool> _mintaIzinBluetooth() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses[Permission.bluetoothConnect]!.isGranted;
  }

  Future<void> cariPerangkatBluetooth(String idSlot) async {
    bool diizinkan = await _mintaIzinBluetooth();
    if (!diizinkan) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin Bluetooth ditolak!'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      isScanning = true;
      daftarPerangkat.clear();
    });

    // Menampilkan Bottom Sheet Pencarian
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              // Jalankan pencarian di latar belakang saat sheet terbuka
              if (isScanning && daftarPerangkat.isEmpty) {
                PrintBluetoothThermal.pairedBluetooths.then((list) {
                  setModalState(() {
                    daftarPerangkat = list;
                    isScanning = false;
                  });
                });
              }

              return Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Pilih Printer Bluetooth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Expanded(
                      child: isScanning
                          ? const Center(child: CircularProgressIndicator())
                          : daftarPerangkat.isEmpty
                              ? const Center(child: Text('Tidak ada perangkat Bluetooth ditemukan.'))
                              : ListView.builder(
                                  itemCount: daftarPerangkat.length,
                                  itemBuilder: (context, index) {
                                    var device = daftarPerangkat[index];
                                    return ListTile(
                                      leading: const Icon(Icons.bluetooth, color: Colors.blue),
                                      title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(device.macAdress),
                                      trailing: ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        onPressed: () {
                                          Navigator.pop(context); // Tutup Sheet
                                          simpanPengaturan(idSlot, 'bluetooth', device.macAdress);
                                          ujiKoneksiBluetooth(device.macAdress); // Uji tes koneksi
                                        },
                                        child: const Text('Pilih', style: TextStyle(color: Colors.white)),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ).whenComplete(() {
        setState(() => isScanning = false);
      });
    }
  }

  // Fungsi khusus untuk tes koneksi Bluetooth langsung
  Future<void> ujiKoneksiBluetooth(String mac) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menguji koneksi printer...'), backgroundColor: Colors.orange));
      }
      final bool terhubung = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(terhubung ? 'Berhasil terhubung ke printer!' : 'Gagal menghubungkan ke printer.'),
            backgroundColor: terhubung ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Gagal tes koneksi: $e");
    }
  }

  // --- WIDGET SLOT PRINTER CERDAS ---
  Widget _buildSlotPrinter(String idSlot, String namaSlot) {
    Map<String, String> config = pengaturanPrinter[idSlot] ?? {'tipe': 'bluetooth', 'alamat': ''};
    String tipeKoneksi = config['tipe']!;
    String alamat = config['alamat']!;
    
    TextEditingController ipCtrl = TextEditingController(text: tipeKoneksi == 'wifi' ? alamat : '');

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          backgroundColor: tipeKoneksi == 'bluetooth' ? Colors.blueAccent : Colors.teal,
          child: Icon(tipeKoneksi == 'bluetooth' ? Icons.bluetooth : Icons.wifi, color: Colors.white),
        ),
        title: Text(namaSlot, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(alamat.isEmpty ? 'Belum dikonfigurasi' : 'Tersimpan: $alamat', style: TextStyle(color: alamat.isEmpty ? Colors.red : Colors.grey)),
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Tipe Koneksi:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Bluetooth', style: TextStyle(fontSize: 14)),
                        value: 'bluetooth',
                        groupValue: tipeKoneksi,
                        activeColor: Colors.blueAccent,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => simpanPengaturan(idSlot, val!, ''), // Reset alamat saat ganti tipe
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('LAN / Wi-Fi', style: TextStyle(fontSize: 14)),
                        value: 'wifi',
                        groupValue: tipeKoneksi,
                        activeColor: Colors.teal,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => simpanPengaturan(idSlot, val!, ''),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                
                // PANEL KONTROL BERDASARKAN TIPE
                if (tipeKoneksi == 'bluetooth') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () => cariPerangkatBluetooth(idSlot),
                      icon: const Icon(Icons.search),
                      label: const Text('Cari & Pilih Printer Bluetooth'),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: ipCtrl,
                    decoration: InputDecoration(
                      labelText: 'Masukkan IP Address Printer',
                      hintText: 'Contoh: 192.168.1.200',
                      prefixIcon: const Icon(Icons.router),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: () {
                        if (ipCtrl.text.isNotEmpty) {
                          simpanPengaturan(idSlot, 'wifi', ipCtrl.text);
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Konfigurasi IP Jaringan'),
                    ),
                  ),
                ],
              ],
            ),
          )
        ],
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(15),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text('Atur perangkat cetak untuk masing-masing divisi. Pastikan printer dalam keadaan menyala.', 
                  style: TextStyle(color: Colors.grey)),
                ),
                
                // 1. SLOT PRINTER KASIR (SELALU ADA)
                _buildSlotPrinter('utama', 'Printer Kasir (Struk Umum)'),
                
                // 2. SLOT PRINTER KATEGORI/DIVISI DINAMIS
                for (var kat in daftarKategori)
                  _buildSlotPrinter(kat['id'].toString(), 'Printer Divisi: ${kat['nama_kategori']}'),
                  
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
