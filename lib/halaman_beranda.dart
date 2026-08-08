import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'dart:convert';
import 'halaman_login.dart'; 
import 'halaman_struk.dart'; 
import 'halaman_shift.dart'; 

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform, Socket; // Ditambah Socket untuk WiFi/LAN
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:url_launcher/url_launcher.dart'; // Ditambah untuk Share WA
import 'package:fl_chart/fl_chart.dart'; // Tambahkan ini

class HalamanBeranda extends StatefulWidget {
  const HalamanBeranda({super.key});

  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

int sisaHariMasaAktif = 30; // Default (Aman)

class _HalamanBerandaState extends State<HalamanBeranda> {
  final String baseUrl = 'https://smartkasir.shop/api';
  bool isLoading = true;

  // Variabel Data Dashboard
  int pendapatanHariIni = 0;
  int jumlahTransaksi = 0;
  int totalProduk = 0;
  int stokMenipis = 0;
  List riwayatTerbaru = [];
  List grafikJamSibuk = [];

  // Variabel Sesi Pengguna & Peringatan
  String username = 'Kasir';
  String role = 'kasir';
  int tokoId = 1;
  int idKasirAktif = 1; 
  bool isTokoLengkap = true;

  // Controller Catatan Pribadi
  TextEditingController catatanPribadiCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muatDataPengguna();
    ambilDataDashboard();
  }

  Future<void> _muatDataPengguna() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Kasir';
      role = prefs.getString('role') ?? 'kasir';
      tokoId = prefs.getInt('toko_id') ?? 1;
      idKasirAktif = prefs.getInt('user_id') ?? 1;
    });
    
    _cekKelengkapanToko();
    _muatCatatanPribadi(); 
  }

  Future<void> _muatCatatanPribadi() async {
    final prefs = await SharedPreferences.getInstance();
    String kunciCatatan = 'catatan_${role}_$idKasirAktif'; 
    setState(() {
      catatanPribadiCtrl.text = prefs.getString(kunciCatatan) ?? '';
    });
  }

  Future<void> _simpanCatatanPribadi() async {
    final prefs = await SharedPreferences.getInstance();
    String kunciCatatan = 'catatan_${role}_$idKasirAktif';
    await prefs.setString(kunciCatatan, catatanPribadiCtrl.text);
  }

  Future<void> _cekKelengkapanToko() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/toko/$tokoId'),
          headers: {'ngrok-skip-browser-warning': 'true'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        if (mounted) {
          setState(() {
            isTokoLengkap = (data['nama_bank'] != null &&
                    data['nama_bank'].toString().isNotEmpty) &&
                (data['rekening_bank'] != null &&
                    data['rekening_bank'].toString().isNotEmpty) &&
                (data['qr_qris'] != null &&
                    data['qr_qris'].toString().isNotEmpty);
          });
        }
      }
    } catch (e) {
      debugPrint('Error cek kelengkapan toko: $e');
    }
  }

  void _konfirmasiLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Aplikasi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HalamanLogin()),
                  (route) => false, 
                );
              }
            },
            child: const Text('Keluar',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> ambilDataDashboard() async {
    setState(() => isLoading = true);
    try {
      // Mengirimkan toko_id agar datanya spesifik
      final response = await http.get(Uri.parse('$baseUrl/dashboard?toko_id=$tokoId'),
          headers: {'ngrok-skip-browser-warning': 'true'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> res = json.decode(response.body);
        
        final toko = res['toko'];
        if (toko != null && toko['masa_aktif'] != null) {
          DateTime masaAktif = DateTime.parse(toko['masa_aktif']);
          DateTime hariIni = DateTime.now();
          sisaHariMasaAktif = masaAktif.difference(hariIni).inDays;
        }
        setState(() {
          pendapatanHariIni = res['data']['pendapatan_hari_ini'] ?? 0;
          jumlahTransaksi = res['data']['jumlah_transaksi'] ?? 0;
          totalProduk = res['data']['total_produk'] ?? 0;
          stokMenipis = res['data']['stok_menipis'] ?? 0;
          riwayatTerbaru = res['data']['riwayat_terbaru'] ?? [];
          grafikJamSibuk = res['data']['jam_sibuk'] ?? []; // Tangkap data grafik
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  String formatRupiah(int angka) {
    return NumberFormat.currency(
            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
        .format(angka);
  }

  String formatWaktuOtomatis(String waktuServer) {
    try {
      DateTime waktuDiHp =
          DateTime.parse("${waktuServer.replaceAll(' ', 'T')}+07:00").toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(waktuDiHp);
    } catch (e) {
      return waktuServer;
    }
  }

  Widget kartuMetrik(String judul, String nilai, IconData ikon, Color warnaIkon,
      {Color? warnaBackgroundCard}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: warnaBackgroundCard ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withAlpha(30),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(judul,
                        style: TextStyle(
                            fontSize: 13,
                            color: warnaBackgroundCard != null
                                ? Colors.white
                                : Colors.grey,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                Icon(ikon,
                    color:
                        warnaBackgroundCard != null ? Colors.white : warnaIkon,
                    size: 20),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(nilai,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: warnaBackgroundCard != null
                          ? Colors.white
                          : Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }

  void _pilihMenuCetak() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🖨️ Menu Cetak & Laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Silakan pilih jenis struk yang ingin dicetak:',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.receipt_long, color: Colors.white)),
              title: const Text('Cetak Struk Transaksi Terakhir',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Cetak ulang struk pelanggan paling baru'),
              onTap: () {
                Navigator.pop(context);
                if (riwayatTerbaru.isNotEmpty) {
                  lihatDetailTransaksi(
                      int.parse(riwayatTerbaru[0]['id'].toString()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Belum ada transaksi hari ini.')));
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.assessment, color: Colors.white)),
              title: const Text('Buka Laporan Rekap Harian',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  const Text('Ringkasan omset, total jasa, catatan & PPN shift ini'),
              onTap: () {
                Navigator.pop(context);
                cetakRekapHarian();
              },
            ),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // FUNGSI PEMBUAT STRUK REKAP (Dipakai Bersama untuk Bluetooth & WiFi)
  // Memastikan ukuran 58mm pas dan tidak ada nominal bug.
  // =======================================================================
  List<int> _buatStrukRekapBytes(Map<String, dynamic> dataLaporan, Generator generator) {
    List<int> bytes = [];
    final toko = dataLaporan['toko'];
    final superadmin = dataLaporan['superadmin'];
    final items = dataLaporan['items'] ?? [];
    final totals = dataLaporan['totals'];
    String keteranganTambahan = dataLaporan['keterangan_tambahan'] ?? '';

    String namaToko = toko != null ? toko['nama_toko'] : 'Toko Saya';
    String alamatToko = toko != null ? toko['alamat'] : '-';

    bytes += generator.text(namaToko.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.text(alamatToko, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text("LAPORAN AKHIR SHIFT", styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text("Tgl: ${dataLaporan['tanggal']}", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text("BARANG/JASA TERJUAL:", styles: const PosStyles(bold: true));
    for (var item in items) {
      int qty = int.tryParse(item['total_qty'].toString()) ?? 0;
      int subtotal = int.tryParse(item['total_subtotal'].toString()) ?? 0;
      bytes += generator.text("${item['nama']} (${item['jenis']})", styles: const PosStyles(align: PosAlign.left));
      // Kolom ukuran 4 dan 8 (total 12 cocok 58mm)
      bytes += generator.row([
        PosColumn(text: "$qty x", width: 4),
        PosColumn(text: formatRupiah(subtotal), width: 8, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

    bytes += generator.text("RINGKASAN KEUANGAN:", styles: const PosStyles(bold: true));
    
    int totalJasa = int.tryParse(totals['total_jasa']?.toString() ?? '0') ?? 0;
    int ppn = int.tryParse(totals['ppn']?.toString() ?? '0') ?? 0;
    int nonTunai = int.tryParse(totals['non_tunai']?.toString() ?? '0') ?? 0;
    int tunai = int.tryParse(totals['tunai']?.toString() ?? '0') ?? 0;
    int grandTotal = int.tryParse(totals['grand_total']?.toString() ?? '0') ?? 0;

    // Kolom ukuran 6 dan 6
    bytes += generator.row([PosColumn(text: "Total Jasa", width: 6), PosColumn(text: formatRupiah(totalJasa), width: 6, styles: const PosStyles(align: PosAlign.right))]);
    bytes += generator.row([PosColumn(text: "Total PPN", width: 6), PosColumn(text: formatRupiah(ppn), width: 6, styles: const PosStyles(align: PosAlign.right))]);
    bytes += generator.row([PosColumn(text: "Non-Tunai", width: 6), PosColumn(text: formatRupiah(nonTunai), width: 6, styles: const PosStyles(align: PosAlign.right))]);
    bytes += generator.row([PosColumn(text: "Tunai Kasir", width: 6), PosColumn(text: formatRupiah(tunai), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true))]);
    
    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.row([
      PosColumn(text: "GRAND TOTAL", width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: formatRupiah(grandTotal), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true))
    ]);

    // Jika ada catatan tambahan
    if (keteranganTambahan.isNotEmpty) {
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("CATATAN / PENGELUARAN:", styles: const PosStyles(bold: true));
      bytes += generator.text(keteranganTambahan, styles: const PosStyles(align: PosAlign.left));
    }

    bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text("Dihasilkan otomatis oleh", styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(superadmin != null ? superadmin['brand'] : "Smart Kasir", styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(2);

    return bytes;
  }

  // --- 1. CETAK VIA BLUETOOTH ---
  Future<void> _cetakLaporanRekapFisik(Map<String, dynamic> dataLaporan) async {
    if (kIsWeb || Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cetak Bluetooth fisik hanya didukung di Android.'),
          backgroundColor: Colors.orange));
      return;
    }

    try {
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected) {
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
        
        List<int> bytes = _buatStrukRekapBytes(dataLaporan, generator);
        await PrintBluetoothThermal.writeBytes(bytes);
      } else {
        List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pilih Printer Bluetooth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                height: 300, width: 300,
                child: devices.isEmpty
                    ? const Center(child: Text("Belum ada perangkat terpasang."))
                    : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.print, color: Colors.blueAccent),
                            title: Text(devices[index].name),
                            subtitle: Text(devices[index].macAdress),
                            onTap: () async {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Menghubungkan ke ${devices[index].name}...'),
                                backgroundColor: Colors.orange,
                              ));
                              try {
                                bool terhubung = await PrintBluetoothThermal.connect(macPrinterAddress: devices[index].macAdress);
                                if (terhubung) {
                                  _cetakLaporanRekapFisik(dataLaporan);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal terhubung ke printer.'), backgroundColor: Colors.red));
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koneksi gagal. Cek ulang bluetooth.'), backgroundColor: Colors.red));
                              }
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.red)))
              ],
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Bluetooth: $e'), backgroundColor: Colors.red));
    }
  }

  // --- 2. CETAK VIA WIFI / LAN Sockets ---
  Future<void> _cetakLaporanRekapWiFi(Map<String, dynamic> dataLaporan) async {
    final prefs = await SharedPreferences.getInstance();
    String ipPrinter = prefs.getString('ip_printer') ?? '';
    
    if (ipPrinter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Alamat IP Printer belum diatur di Pengaturan!'), backgroundColor: Colors.orange));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mengirim ke Printer Jaringan...'), backgroundColor: Colors.blueAccent));

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = _buatStrukRekapBytes(dataLaporan, generator);

      final socket = await Socket.connect(ipPrinter, 9100, timeout: const Duration(seconds: 5));
      socket.add(bytes);
      socket.destroy();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Berhasil mencetak via WiFi!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mencetak LAN/WiFi: Cek koneksi & IP Printer.'), backgroundColor: Colors.red));
      }
    }
  }

  // --- 3. BAGIKAN KE WHATSAPP (Text Format) ---
  Future<void> _bagikanKeWA(Map<String, dynamic> dataLaporan) async {
    final toko = dataLaporan['toko'];
    final items = dataLaporan['items'] ?? [];
    final totals = dataLaporan['totals'];
    String keteranganTambahan = dataLaporan['keterangan_tambahan'] ?? '';
    
    String namaToko = toko != null ? toko['nama_toko'] : 'Toko Saya';
    String tanggal = dataLaporan['tanggal'] ?? '';

    StringBuffer sb = StringBuffer();
    sb.writeln("*LAPORAN AKHIR SHIFT* 📝");
    sb.writeln("🏢 Toko: $namaToko");
    sb.writeln("📅 Tgl: $tanggal");
    sb.writeln("---------------------------------");
    sb.writeln("*BARANG/JASA TERJUAL:*");
    for (var item in items) {
      int qty = int.tryParse(item['total_qty'].toString()) ?? 0;
      int sub = int.tryParse(item['total_subtotal'].toString()) ?? 0;
      sb.writeln("- ${item['nama']} ($qty x): ${formatRupiah(sub)}");
    }
    sb.writeln("---------------------------------");
    sb.writeln("*RINGKASAN KEUANGAN:*");
    int totalJasa = int.tryParse(totals['total_jasa']?.toString() ?? '0') ?? 0;
    int ppn = int.tryParse(totals['ppn']?.toString() ?? '0') ?? 0;
    int nonTunai = int.tryParse(totals['non_tunai']?.toString() ?? '0') ?? 0;
    int tunai = int.tryParse(totals['tunai']?.toString() ?? '0') ?? 0;
    int grandTotal = int.tryParse(totals['grand_total']?.toString() ?? '0') ?? 0;

    sb.writeln("Total Jasa: ${formatRupiah(totalJasa)}");
    sb.writeln("Total PPN: ${formatRupiah(ppn)}");
    sb.writeln("Total Non-Tunai: ${formatRupiah(nonTunai)}");
    sb.writeln("Total Tunai Kasir: *${formatRupiah(tunai)}*");
    sb.writeln("---------------------------------");
    sb.writeln("*GRAND TOTAL: ${formatRupiah(grandTotal)}*");
    
    if (keteranganTambahan.isNotEmpty) {
      sb.writeln("---------------------------------");
      sb.writeln("*CATATAN PENGELUARAN:*");
      sb.writeln(keteranganTambahan);
    }

    String encodedText = Uri.encodeComponent(sb.toString());
    String url = "https://wa.me/?text=$encodedText";
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka WhatsApp!'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error WhatsApp URL Launcher'), backgroundColor: Colors.red));
    }
  }
  // =======================================================================

  Future<void> lihatDetailTransaksi(int id) async {
    showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final res = await http.get(Uri.parse('$baseUrl/transaksi/$id'),
          headers: {'ngrok-skip-browser-warning': 'true'});
      Navigator.pop(context); 

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final header = data['header'];
        final details = data['details'];
        final toko = data['toko'];
        final superadmin = data['superadmin'];

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            contentPadding: const EdgeInsets.all(20),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(toko != null ? toko['nama_toko'] : 'Nama Toko',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(toko != null ? toko['alamat'] : 'Alamat',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                      'Struk #${header['id']} | ${formatWaktuOtomatis(header['tanggal'])}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const Divider(thickness: 1, color: Colors.black54),
                  ...details.map<Widget>((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${item['nama']} x${item['qty']}')),
                            Text(formatRupiah(int.parse(item['subtotal'].toString()))),
                          ],
                        ),
                      )),
                  const Divider(thickness: 1, color: Colors.black54),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:'),
                        Text(formatRupiah(int.parse(header['total_harga'].toString())),
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tunai/Bayar:'),
                        Text(formatRupiah(int.parse(header['uang_bayar'].toString())))
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembali:'),
                        Text(formatRupiah(int.parse(header['kembalian'].toString())))
                      ]),
                  const SizedBox(height: 20),
                  const Text('Terima Kasih Atas Kunjungan Anda',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  const Divider(thickness: 1, color: Colors.black54),
                  const SizedBox(height: 5),
                  Text('Powered by ${superadmin['brand']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  Text(superadmin['teks'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('Info Aplikasi/Sistem WA: ${superadmin['wa']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); 

                  List<Map<String, dynamic>> keranjangCetak = [];
                  int hitungSubtotal = 0;
                  int hitungJasa = 0;

                  for (var item in details) {
                    int sub = int.tryParse(item['subtotal']?.toString() ?? '0') ?? 0;
                    int idProd = int.tryParse(item['product_id']?.toString() ?? item['id']?.toString() ?? '0') ?? 0;

                    if (idProd == 0) {
                      hitungJasa += sub;
                    } else {
                      hitungSubtotal += sub;
                    }

                    keranjangCetak.add({
                      'id': idProd,
                      'nama': item['nama'] ?? 'Produk',
                      'harga': int.tryParse(item['harga_satuan']?.toString() ?? item['harga']?.toString() ?? '0') ?? 0,
                      'qty': int.tryParse(item['qty']?.toString() ?? '1') ?? 1,
                      'subtotal': sub,
                    });
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanStruk(
                        keranjang: keranjangCetak,
                        totalBelanja: int.tryParse(header['total_harga']?.toString() ?? '0') ?? 0,
                        subtotal: hitungSubtotal,
                        ppnNominal: int.tryParse(header['ppn_nominal']?.toString() ?? '0') ?? 0,
                        biayaJasa: hitungJasa,
                        uangDiterima: int.tryParse(header['uang_bayar']?.toString() ?? '0') ?? 0,
                        uangKembalian: int.tryParse(header['kembalian']?.toString() ?? '0') ?? 0,
                        noStruk: 'INV-${header['id']}',
                        tanggal: formatWaktuOtomatis(header['tanggal']),
                        metodePembayaran: header['metode_pembayaran']?.toString() ?? 'Tunai',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('Cetak'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  Future<void> cetakRekapHarian() async {
    showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final res = await http.get(Uri.parse('$baseUrl/rekap'),
          headers: {'ngrok-skip-browser-warning': 'true'});
      Navigator.pop(context);
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final items = data['items'];
        final totals = data['totals'];
        final toko = data['toko'];
        
        TextEditingController keteranganRekapCtrl = TextEditingController();

        showModalBottomSheet(
          context: context,
          isScrollControlled: true, 
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Text(toko != null ? toko['nama_toko'] : 'Nama Toko',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  Center(
                      child: Text(toko != null ? toko['alamat'] : 'Alamat',
                          style: const TextStyle(fontSize: 12, color: Colors.grey))),
                  const SizedBox(height: 15),
                  const Center(
                      child: Text('LAPORAN AKHIR SHIFT',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  Center(
                      child: Text('Tanggal: ${data['tanggal']}',
                          style: const TextStyle(color: Colors.grey))),
                  const Divider(thickness: 2),
                  const Text('BARANG/JASA KELUAR:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${items[i]['nama']} (${items[i]['jenis']})'),
                          trailing: Text('Terjual: ${items[i]['total_qty']} | ${formatRupiah(int.parse(items[i]['total_subtotal'].toString()))}'),
                        );
                      },
                    ),
                  ),
                  const Divider(thickness: 2),
                  const Text('RINGKASAN KEUANGAN:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total Jasa:'),
                    Text(formatRupiah(int.parse(totals['total_jasa'].toString() == 'null' ? '0' : totals['total_jasa'].toString())))
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total PPN:'),
                    Text(formatRupiah(int.parse(totals['ppn'].toString() == 'null' ? '0' : totals['ppn'].toString())))
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total Non-Tunai:'),
                    Text(formatRupiah(int.parse(totals['non_tunai'].toString() == 'null' ? '0' : totals['non_tunai'].toString())))
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total Tunai Kasir:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    Text(formatRupiah(int.parse(totals['tunai'].toString() == 'null' ? '0' : totals['tunai'].toString())),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))
                  ]),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('GRAND TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(formatRupiah(int.parse(totals['grand_total'].toString() == 'null' ? '0' : totals['grand_total'].toString())),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent))
                  ]),
                      
                  const SizedBox(height: 10),
                  const Text('Catatan Tambahan / Pengeluaran:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: keteranganRekapCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Cth: Uang kepakai beli es batu 20rb...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ===============================================
                  // FITUR BARU: TOMBOL PILIHAN CETAK / SHARE WA
                  // ===============================================
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.black87),
                          onPressed: () {
                            Navigator.pop(context); 
                            data['keterangan_tambahan'] = keteranganRekapCtrl.text;
                            _cetakLaporanRekapFisik(data); 
                          },
                          icon: const Icon(Icons.bluetooth, color: Colors.white, size: 18),
                          label: const Text('Bluetooth', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.teal),
                          onPressed: () {
                            Navigator.pop(context); 
                            data['keterangan_tambahan'] = keteranganRekapCtrl.text;
                            _cetakLaporanRekapWiFi(data); 
                          },
                          icon: const Icon(Icons.wifi, color: Colors.white, size: 18),
                          label: const Text('WiFi/LAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.green),
                      onPressed: () {
                        Navigator.pop(context); 
                        data['keterangan_tambahan'] = keteranganRekapCtrl.text;
                        _bagikanKeWA(data); 
                      },
                      icon: const Icon(Icons.share, color: Colors.white, size: 18),
                      label: const Text('Bagikan ke WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
    Widget _buildGrafikJamSibuk() {
    if (grafikJamSibuk.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('Belum ada data transaksi hari ini.', style: TextStyle(color: Colors.grey))),
      );
    }

    // Mengubah data API JSON menjadi Format BarChart Fl_Chart
    List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (var data in grafikJamSibuk) {
      int jam = int.parse(data['jam'].toString());
      double total = double.parse(data['total_transaksi'].toString());
      
      if (total > maxY) maxY = total; // Cari nilai tertinggi untuk tinggi grafik

      barGroups.add(
        BarChartGroupData(
          x: jam,
          barRods: [
            BarChartRodData(
              toY: total,
              color: Colors.blueAccent,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY + 2, // Background bayangan grafik
                color: Colors.blue.withAlpha(20),
              )
            )
          ],
        )
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(20), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY + 2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  'Pukul ${group.x.toString().padLeft(2, '0')}:00\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} Transaksi',
                      style: const TextStyle(color: Colors.yellowAccent, fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${value.toInt()}:00', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink(); // Hilangkan desimal
                  return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 40, fit: BoxFit.contain),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Keluar Akun',
            onPressed: _konfirmasiLogout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: ambilDataDashboard,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (sisaHariMasaAktif <= 7 && sisaHariMasaAktif > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.red, size: 40),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Masa Aktif Hampir Habis!',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red)),
                                Text(
                                    'Sistem kasir akan dikunci dalam $sisaHariMasaAktif hari. Segera perpanjang langganan Anda.',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!isTokoLengkap && role == 'admin')
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade300),
                          borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 40),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Perhatian!',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange)),
                                Text(
                                    'Harap lengkapi pengaturan Rekening dan QRIS Toko agar fitur pembayaran non-tunai berfungsi maksimal.',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  Text('Selamat Datang, $username!',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('Berikut adalah ringkasan penjualan hari ini.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      kartuMetrik('Pendapatan', formatRupiah(pendapatanHariIni),
                          Icons.account_balance_wallet, Colors.green),
                      const SizedBox(width: 15),
                      kartuMetrik('Transaksi', '$jumlahTransaksi',
                          Icons.receipt_long, Colors.blueAccent),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      kartuMetrik('Total Produk', '$totalProduk',
                          Icons.inventory_2, Colors.orange),
                      const SizedBox(width: 15),
                      kartuMetrik('Stok Menipis', '$stokMenipis',
                          Icons.warning_amber_rounded, Colors.white,
                          warnaBackgroundCard:
                              stokMenipis > 0 ? Colors.redAccent : Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 20),

// JUDUL GRAFIK
const Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('📈 Analitik Jam Sibuk (Hari Ini)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  ],
),
const SizedBox(height: 10),

// PANGGIL GRAFIKNYA DI SINI
_buildGrafikJamSibuk(),
const SizedBox(height: 25),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HalamanShift()),
                      );
                    },
                    icon: const Icon(Icons.lock_clock, color: Colors.white),
                    label: const Text('Manajemen Uang Shift (Buka/Tutup Laci)',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 15),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    onPressed: _pilihMenuCetak,
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text('Buka Menu Cetak Laporan & Struk',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade300)),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_note, color: Colors.orange),
                              const SizedBox(width: 10),
                              Text('Catatan Pribadi ($role)', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: catatanPribadiCtrl,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Tulis tugas, keluhan, atau info di sini...\n(Catatan ini tersimpan aman & rahasia di perangkat Anda)',
                              hintStyle: const TextStyle(fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.orange.shade50.withAlpha(100),
                            ),
                            onChanged: (val) => _simpanCatatanPribadi(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5 Transaksi Terakhir',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Icon(Icons.history, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (riwayatTerbaru.isEmpty)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('Belum ada transaksi hari ini.')))
                  else
                    ...riwayatTerbaru.map((trx) {
                      bool isTunai = trx['metode_pembayaran'] == 'tunai';
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          onTap: () => lihatDetailTransaksi(
                              int.parse(trx['id'].toString())),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor:
                                (isTunai ? Colors.green : Colors.purple)
                                    .withAlpha(30),
                            child: Icon(
                                isTunai
                                    ? Icons.payments
                                    : Icons.qr_code_scanner,
                                color: isTunai ? Colors.green : Colors.purple),
                          ),
                          title: Text('ID Transaksi: #${trx['id']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              formatWaktuOtomatis(trx['tanggal'].toString())),
                          trailing: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatRupiah(
                                  int.parse(trx['total_harga'].toString())),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
