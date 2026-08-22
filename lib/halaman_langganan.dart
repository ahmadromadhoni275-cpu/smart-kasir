import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class HalamanLangganan extends StatefulWidget {
  const HalamanLangganan({super.key});

  @override
  State<HalamanLangganan> createState() => _HalamanLanggananState();
}

class _HalamanLanggananState extends State<HalamanLangganan> {
  final String domainUrl = 'https://smartkasir.shop';
  
  bool isManualAktif = false;
  bool isOtomatisAktif = false;
  bool isLoading = true;

  String namaBank = "-";
  String rekeningBank = "-";
  String atasNamaBank = "-";
  int hargaPerBulan = 50000;
  int tokoId = 1;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    final prefs = await SharedPreferences.getInstance();
    tokoId = prefs.getInt('toko_id') ?? 1;

    try {
      final response = await http.get(
        Uri.parse('$domainUrl/api/pengaturan'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          isManualAktif = data['langganan_manual_aktif'] ?? false;
          isOtomatisAktif = data['langganan_otomatis_aktif'] ?? false;
          namaBank = data['nama_bank_pusat'] ?? "-";
          rekeningBank = data['rekening_pusat'] ?? "-";
          atasNamaBank = data['atas_nama_pusat'] ?? "-";
          hargaPerBulan = int.tryParse(data['harga_per_bulan'].toString()) ?? 50000;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // DIALOG UPLOAD BUKTI TRANSFER UNTUK MANUAL
  void _tampilkanDialogUploadManual(String namaPaket, int nominal, int durasiHari) {
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pilihGambar() async {
              final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
              if (picked != null) setModalState(() => selectedImage = File(picked.path));
            }

            Future<void> kirimBukti() async {
              if (selectedImage == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih foto bukti transfer dahulu!'), backgroundColor: Colors.red));
                return;
              }
              setModalState(() => isUploading = true);

              try {
                var request = http.MultipartRequest('POST', Uri.parse('$domainUrl/api/ajukanLanggananManual'));
                request.fields['toko_id'] = tokoId.toString();
                request.fields['nominal'] = nominal.toString();
                request.fields['durasi_hari'] = durasiHari.toString();
                request.files.add(await http.MultipartFile.fromPath('bukti_transfer', selectedImage!.path));

                var response = await request.send();
                if (response.statusCode == 200) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil! Menunggu konfirmasi admin.'), backgroundColor: Colors.green));
                  }
                } else {
                  setModalState(() => isUploading = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim data.'), backgroundColor: Colors.red));
                }
              } catch (e) {
                setModalState(() => isUploading = false);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan jaringan.'), backgroundColor: Colors.red));
              }
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Konfirmasi Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Silakan transfer sebesar Rp $nominal ke:', style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 5),
                        Text('$namaBank - $rekeningBank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('A/N $atasNamaBank', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: pilihGambar,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: selectedImage == null
                          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.camera_alt, size: 40, color: Colors.grey), SizedBox(height: 10), Text('Tap untuk pilih bukti transfer')])
                          : Image.file(selectedImage!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),
                  isUploading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                          onPressed: kirimBukti,
                          child: const Text('Kirim Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _prosesPaymentOtomatis(String paket, int nominal) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Membuka gerbang pembayaran untuk Rp $nominal...'), backgroundColor: Colors.blueAccent));
    // Integrasi Tripay Checkout diletakkan di sini nantinya
  }

  Widget _buildKartuPaket({required String judul, required int durasiHari, required int harga, required Color warna, required IconData ikon, required bool isOtomatis}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: warna.withAlpha(30), shape: BoxShape.circle), child: Icon(ikon, color: warna, size: 35)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('$durasiHari Hari', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 5),
                  Text('Rp $harga', style: TextStyle(color: warna, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: isOtomatis ? Colors.green : warna, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                if (isOtomatis) {
                  _prosesPaymentOtomatis(judul, harga);
                } else {
                  _tampilkanDialogUploadManual(judul, harga, durasiHari);
                }
              },
              child: Text(isOtomatis ? 'Bayar QRIS' : 'Upload Bukti'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (!isManualAktif && !isOtomatisAktif) {
      return Scaffold(appBar: AppBar(title: const Text('Langganan'), backgroundColor: Colors.blueAccent), body: const Center(child: Text('Fitur langganan dinonaktifkan.')));
    }

    int harga1Bulan = hargaPerBulan;
    int harga3Bulan = (hargaPerBulan * 3) - 15000; // Contoh diskon
    int harga1Tahun = (hargaPerBulan * 12) - 100000;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Perpanjang Langganan', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.indigo]), borderRadius: BorderRadius.circular(15)),
              child: Column(children: const [Icon(Icons.rocket_launch, color: Colors.white, size: 50), SizedBox(height: 10), Text('Upgrade Toko Anda!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))]),
            ),
            const SizedBox(height: 25),

            if (isOtomatisAktif) ...[
              const Text('Langsung Aktif (Otomatis):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              _buildKartuPaket(judul: 'Paket Basic (Auto)', durasiHari: 30, harga: harga1Bulan, warna: Colors.green, ikon: Icons.flash_on, isOtomatis: true),
              const SizedBox(height: 20),
            ],

            if (isManualAktif) ...[
              const Text('Verifikasi Admin (Upload Transfer):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              _buildKartuPaket(judul: 'Basic', durasiHari: 30, harga: harga1Bulan, warna: Colors.blue, ikon: Icons.star_border, isOtomatis: false),
              _buildKartuPaket(judul: 'Pro', durasiHari: 90, harga: harga3Bulan, warna: Colors.orange, ikon: Icons.star_half, isOtomatis: false),
              _buildKartuPaket(judul: 'Ultimate', durasiHari: 365, harga: harga1Tahun, warna: Colors.redAccent, ikon: Icons.star, isOtomatis: false),
            ]
          ],
        ),
      ),
    );
  }
}
