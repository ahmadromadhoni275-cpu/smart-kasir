import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Tambahan untuk memori sesi
import 'dart:convert';
import 'halaman_login.dart'; // Tambahan untuk arah logout
import 'halaman_struk.dart'; // Tambahan untuk cetak ulang struk

// --- IMPOR PACKAGE BLUETOOTH & PELINDUNG PLATFORM ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

class HalamanBeranda extends StatefulWidget {
  const HalamanBeranda({super.key});

  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

int sisaHariMasaAktif = 30; // Default (Aman)

class _HalamanBerandaState extends State<HalamanBeranda> {
  // URL telah diubah ke hosting utama
  final String baseUrl = 'https://smartkasir.shop/api';
  bool isLoading = true;

  // Variabel Data Dashboard
  int pendapatanHariIni = 0;
  int jumlahTransaksi = 0;
  int totalProduk = 0;
  int stokMenipis = 0;
  List riwayatTerbaru = [];

  // Variabel Sesi Pengguna & Peringatan
  String username = 'Kasir';
  String role = 'kasir';
  int tokoId = 1;
  bool isTokoLengkap = true;

  @override
  void initState() {
    super.initState();
    _muatDataPengguna();
    ambilDataDashboard();
  }

  // --- MENGAMBIL NAMA & ROLE DARI MEMORI ---
  Future<void> _muatDataPengguna() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Kasir';
      role = prefs.getString('role') ?? 'kasir';
      tokoId = prefs.getInt('toko_id') ?? 1;
    });
    // Panggil fungsi cek kelengkapan setelah toko_id didapatkan
    _cekKelengkapanToko();
  }

  // --- CEK KELENGKAPAN DATA REKENING & QRIS TOKO ---
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

  // --- FUNGSI LOGOUT ---
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
              await prefs.clear(); // Menghapus semua data sesi di HP
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HalamanLogin()),
                  (route) =>
                      false, // Hapus tumpukan riwayat halaman (tidak bisa di-back)
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
      final response = await http.get(Uri.parse('$baseUrl/dashboard'),
          headers: {'ngrok-skip-browser-warning': 'true'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> res = json.decode(response.body);
        // --- LOGIKA HITUNG MUNDUR MASA AKTIF ---
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

  // --- KARTU METRIK ANTI-RUSAK (FITTEDBOX) ---
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

  // --- DIALOG PILIHAN CETAK (STRUK PANJANG VS REKAP) ---
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
              title: const Text('Cetak Laporan Rekap Harian',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  const Text('Ringkasan omset, total jasa, dan PPN shift ini'),
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

  // --- FUNGSI KHUSUS CETAK FISIK LAPORAN REKAP HARIAN ---
  Future<void> _cetakLaporanRekapFisik(Map<String, dynamic> dataLaporan) async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Cetak fisik tidak didukung di Web. Gunakan Android.'),
            backgroundColor: Colors.orange));
      }
      return;
    }
    if (Platform.isIOS) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Cetak Bluetooth terhalang aturan iOS. Gunakan Android.'),
            backgroundColor: Colors.orange));
      }
      return;
    }

    try {
      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected) {
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
        List<int> bytes = [];

        final toko = dataLaporan['toko'];
        final superadmin = dataLaporan['superadmin'];
        final items = dataLaporan['items'] ?? [];
        final totals = dataLaporan['totals'];

        String namaToko = toko != null ? toko['nama_toko'] : 'Toko Saya';
        String alamatToko = toko != null ? toko['alamat'] : '-';

        // Header
        bytes += generator.text(namaToko.toUpperCase(),
            styles: const PosStyles(
                align: PosAlign.center, bold: true, height: PosTextSize.size2));
        bytes += generator.text(alamatToko,
            styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text("--------------------------------",
            styles: const PosStyles(align: PosAlign.center));

        // Judul Laporan
        bytes += generator.text("LAPORAN AKHIR SHIFT",
            styles: const PosStyles(align: PosAlign.center, bold: true));
        bytes += generator.text("Tgl: ${dataLaporan['tanggal']}",
            styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text("--------------------------------",
            styles: const PosStyles(align: PosAlign.center));

        // Rincian Terjual
        bytes += generator.text("BARANG/JASA TERJUAL:",
            styles: const PosStyles(bold: true));
        for (var item in items) {
          int qty = int.tryParse(item['total_qty'].toString()) ?? 0;
          int subtotal = int.tryParse(item['total_subtotal'].toString()) ?? 0;

          bytes += generator.text("${item['nama']} (${item['jenis']})",
              styles: const PosStyles(align: PosAlign.left));
          bytes += generator.row([
            PosColumn(text: "$qty x", width: 4),
            PosColumn(
                text: formatRupiah(subtotal),
                width: 8,
                styles: const PosStyles(align: PosAlign.right)),
          ]);
        }

        bytes += generator.text("--------------------------------",
            styles: const PosStyles(align: PosAlign.center));

        // Ringkasan Keuangan
        bytes += generator.text("RINGKASAN KEUANGAN:",
            styles: const PosStyles(bold: true));

        int totalJasa =
            int.tryParse(totals['total_jasa']?.toString() ?? '0') ?? 0;
        int ppn = int.tryParse(totals['ppn']?.toString() ?? '0') ?? 0;
        int nonTunai =
            int.tryParse(totals['non_tunai']?.toString() ?? '0') ?? 0;
        int tunai = int.tryParse(totals['tunai']?.toString() ?? '0') ?? 0;
        int grandTotal =
            int.tryParse(totals['grand_total']?.toString() ?? '0') ?? 0;

        bytes += generator.row([
          PosColumn(text: "Total Jasa", width: 6),
          PosColumn(
              text: formatRupiah(totalJasa),
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: "Total PPN", width: 6),
          PosColumn(
              text: formatRupiah(ppn),
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: "Total Non-Tunai", width: 6),
          PosColumn(
              text: formatRupiah(nonTunai),
              width: 6,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
        bytes += generator.row([
          PosColumn(text: "Total Tunai", width: 6),
          PosColumn(
              text: formatRupiah(tunai),
              width: 6,
              styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]);

        bytes += generator.text("--------------------------------",
            styles: const PosStyles(align: PosAlign.center));

        bytes += generator.row([
          PosColumn(
              text: "GRAND TOTAL",
              width: 6,
              styles: const PosStyles(bold: true)),
          PosColumn(
              text: formatRupiah(grandTotal),
              width: 6,
              styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]);

        bytes += generator.text("--------------------------------",
            styles: const PosStyles(align: PosAlign.center));

        // Footer
        bytes += generator.text("Dihasilkan otomatis oleh",
            styles: const PosStyles(align: PosAlign.center));
        bytes += generator.text(
            superadmin != null ? superadmin['brand'] : "Smart Kasir",
            styles: const PosStyles(align: PosAlign.center, bold: true));

        bytes += generator.feed(2);

        await PrintBluetoothThermal.writeBytes(bytes);
      } else {
        List<BluetoothInfo> devices =
            await PrintBluetoothThermal.pairedBluetooths;
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Pilih Printer Bluetooth',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                height: 300,
                width: 300,
                child: devices.isEmpty
                    ? const Center(
                        child: Text("Belum ada perangkat terpasang.",
                            textAlign: TextAlign.center))
                    : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.print,
                                color: Colors.blueAccent),
                            title: Text(devices[index].name),
                            subtitle: Text(devices[index].macAdress),
                            onTap: () async {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    'Menghubungkan ke ${devices[index].name}...'),
                                backgroundColor: Colors.orange,
                              ));
                              try {
                                bool terhubung =
                                    await PrintBluetoothThermal.connect(
                                        macPrinterAddress:
                                            devices[index].macAdress);
                                if (terhubung) {
                                  _cetakLaporanRekapFisik(dataLaporan);
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content:
                                          Text('Gagal terhubung ke printer.'),
                                      backgroundColor: Colors.red,
                                    ));
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Koneksi gagal. Cek ulang bluetooth.'),
                                          backgroundColor: Colors.red));
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child:
                      const Text('Batal', style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error Bluetooth: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // --- POP-UP CETAK ULANG STRUK ---
  Future<void> lihatDetailTransaksi(int id) async {
    showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final res = await http.get(Uri.parse('$baseUrl/transaksi/$id'),
          headers: {'ngrok-skip-browser-warning': 'true'});
      Navigator.pop(context); // Tutup loading

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
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
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
                            Expanded(
                                child: Text('${item['nama']} x${item['qty']}')),
                            Text(formatRupiah(
                                int.parse(item['subtotal'].toString()))),
                          ],
                        ),
                      )),
                  const Divider(thickness: 1, color: Colors.black54),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:'),
                        Text(
                            formatRupiah(
                                int.parse(header['total_harga'].toString())),
                            style: const TextStyle(fontWeight: FontWeight.bold))
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tunai/Bayar:'),
                        Text(formatRupiah(
                            int.parse(header['uang_bayar'].toString())))
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembali:'),
                        Text(formatRupiah(
                            int.parse(header['kembalian'].toString())))
                      ]),
                  const SizedBox(height: 20),
                  const Text('Terima Kasih Atas Kunjungan Anda',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  const Divider(thickness: 1, color: Colors.black54),
                  const SizedBox(height: 5),
                  Text('Powered by ${superadmin['brand']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 11)),
                  Text(superadmin['teks'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text('Info Aplikasi/Sistem WA: ${superadmin['wa']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup')),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog pop-up

                  // --- MAPPING DATA & LEMPAR KE HALAMAN STRUK ---
                  List<Map<String, dynamic>> keranjangCetak = [];
                  int hitungSubtotal = 0;
                  int hitungJasa = 0;

                  for (var item in details) {
                    int sub =
                        int.tryParse(item['subtotal']?.toString() ?? '0') ?? 0;
                    int idProd = int.tryParse(item['product_id']?.toString() ??
                            item['id']?.toString() ??
                            '0') ??
                        0;

                    if (idProd == 0) {
                      hitungJasa += sub;
                    } else {
                      hitungSubtotal += sub;
                    }

                    keranjangCetak.add({
                      'id': idProd,
                      'nama': item['nama'] ?? 'Produk',
                      'harga': int.tryParse(item['harga_satuan']?.toString() ??
                              item['harga']?.toString() ??
                              '0') ??
                          0,
                      'qty': int.tryParse(item['qty']?.toString() ?? '1') ?? 1,
                      'subtotal': sub,
                    });
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HalamanStruk(
                        keranjang: keranjangCetak,
                        totalBelanja: int.tryParse(
                                header['total_harga']?.toString() ?? '0') ??
                            0,
                        subtotal: hitungSubtotal,
                        ppnNominal: int.tryParse(
                                header['ppn_nominal']?.toString() ?? '0') ??
                            0,
                        biayaJasa: hitungJasa,
                        uangDiterima: int.tryParse(
                                header['uang_bayar']?.toString() ?? '0') ??
                            0,
                        uangKembalian: int.tryParse(
                                header['kembalian']?.toString() ?? '0') ??
                            0,
                        noStruk: 'INV-${header['id']}',
                        tanggal: formatWaktuOtomatis(header['tanggal']),
                        metodePembayaran:
                            header['metode_pembayaran']?.toString() ?? 'Tunai',
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

  // --- POP-UP REKAP HARIAN (END SHIFT) ---
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
        final superadmin = data['superadmin'];

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Text(toko != null ? toko['nama_toko'] : 'Nama Toko',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18))),
                Center(
                    child: Text(toko != null ? toko['alamat'] : 'Alamat',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey))),
                const SizedBox(height: 15),
                const Center(
                    child: Text('LAPORAN AKHIR SHIFT',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                Center(
                    child: Text('Tanggal: ${data['tanggal']}',
                        style: const TextStyle(color: Colors.grey))),
                const Divider(thickness: 2),
                const Text('BARANG/JASA KELUAR:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title:
                            Text('${items[i]['nama']} (${items[i]['jenis']})'),
                        trailing: Text(
                            'Terjual: ${items[i]['total_qty']} | ${formatRupiah(int.parse(items[i]['total_subtotal'].toString()))}'),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 2),
                const Text('RINGKASAN KEUANGAN:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pendapatan Jasa:'),
                      Text(formatRupiah(int.parse(
                          totals['total_jasa'].toString() == 'null'
                              ? '0'
                              : totals['total_jasa'].toString())))
                    ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total PPN:'),
                      Text(formatRupiah(int.parse(
                          totals['ppn'].toString() == 'null'
                              ? '0'
                              : totals['ppn'].toString())))
                    ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Non-Tunai:'),
                      Text(formatRupiah(int.parse(
                          totals['non_tunai'].toString() == 'null'
                              ? '0'
                              : totals['non_tunai'].toString())))
                    ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tunai Kasir:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      Text(
                          formatRupiah(int.parse(
                              totals['tunai'].toString() == 'null'
                                  ? '0'
                                  : totals['tunai'].toString())),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.green))
                    ]),
                const Divider(),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GRAND TOTAL:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                          formatRupiah(int.parse(
                              totals['grand_total'].toString() == 'null'
                                  ? '0'
                                  : totals['grand_total'].toString())),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent))
                    ]),
                const SizedBox(height: 20),
                Center(
                    child: Text(
                        'Dihasilkan otomatis oleh sistem ${superadmin['brand']}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey))),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.black87),
                    onPressed: () {
                      Navigator.pop(context); // Tutup BottomSheet
                      _cetakLaporanRekapFisik(
                          data); // Panggil fungsi cetak rekap
                    },
                    icon: const Icon(Icons.print, color: Colors.white),
                    label: const Text('Cetak Struk Laporan',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
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
                  // --- NOTIFIKASI MASA AKTIF (< 7 HARI) ---
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

                  // --- NOTIFIKASI PERINGATAN DATA TOKO ---
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

                  // Sapaan Dinamis berdasarkan nama login
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

                  // --- TOMBOL MENU CETAK ---
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
                  const SizedBox(height: 30),

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
