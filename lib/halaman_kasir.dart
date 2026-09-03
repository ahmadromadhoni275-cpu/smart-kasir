import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_scan2/barcode_scan2.dart'; 
import 'dart:convert';
import 'package:intl/intl.dart';

import 'halaman_struk.dart';
import 'halaman_riwayat.dart';
import 'halaman_printer.dart'; 

class HalamanKasir extends StatefulWidget {
  const HalamanKasir({super.key});

  @override
  State<HalamanKasir> createState() => _HalamanKasirState();
}

class _HalamanKasirState extends State<HalamanKasir> {
  final String baseUrl = 'https://smartkasir.shop/api';

  String namaToko = "Smart Kasir";
  int idTokoAktif = 1;
  int idKasirAktif = 1;
  String userRole = 'kasir';

  bool isLocked = false;
  bool isShiftTerbuka = false; 
  bool isFiturJasaAktif = true;
  bool isFiturMejaAktif = false; 
  bool isFiturTakeawayAktif = false; 
  int shiftIdAktif = 0;

  List data = [];
  bool isLoading = true;
  String kataKunci = "";
  TextEditingController pencarianController = TextEditingController();
  TextEditingController noMejaCtrl = TextEditingController(); 

  List<Map<String, dynamic>> keranjang = [];

  int persenPpn = 0;
  TextEditingController namaJasaCtrl = TextEditingController();
  TextEditingController nominalJasaCtrl = TextEditingController();

  // CONTROLLER KHUSUS UNTUK POPUP BUKA SHIFT
  TextEditingController modalAwalCtrl = TextEditingController();
  bool isProsesBukaShift = false;

  @override
  void initState() {
    super.initState();
    _muatDataPenggunaDanToko();
    _muatKeranjangLokal(); 
  }

  // =======================================================
  // FITUR AUTO-SAVE DAN PEMULIHAN KERANJANG
  // =======================================================
  Future<void> _simpanKeranjangLokal() async {
    final prefs = await SharedPreferences.getInstance();
    String keranjangJson = json.encode(keranjang);
    await prefs.setString('keranjang_sementara', keranjangJson);
    await prefs.setString('no_meja_sementara', noMejaCtrl.text);
    await prefs.setString('jasa_nama_sementara', namaJasaCtrl.text);
    await prefs.setString('jasa_nominal_sementara', nominalJasaCtrl.text);
  }

  Future<void> _muatKeranjangLokal() async {
    final prefs = await SharedPreferences.getInstance();
    String? keranjangJson = prefs.getString('keranjang_sementara');
    if (keranjangJson != null && keranjangJson.isNotEmpty) {
      try {
        List<dynamic> decoded = json.decode(keranjangJson);
        setState(() {
          keranjang = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      } catch (e) {
        debugPrint('Gagal memuat keranjang lokal: $e');
      }
    }
    setState(() {
      noMejaCtrl.text = prefs.getString('no_meja_sementara') ?? '';
      namaJasaCtrl.text = prefs.getString('jasa_nama_sementara') ?? '';
      nominalJasaCtrl.text = prefs.getString('jasa_nominal_sementara') ?? '';
    });
  }

  // =======================================================
  // CEK STATUS SHIFT (Sudah Bersih dari Ngrok Header)
  // =======================================================
  Future<void> _cekStatusShift() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shift/status/$idTokoAktif/$idKasirAktif'),
        headers: {'Accept': 'application/json'}
      );
      final data = json.decode(response.body);
      
      if (data['status'] == true) {
        setState(() { 
          isShiftTerbuka = true; 
          shiftIdAktif = data['data']['shift_id']; 
        });
      } else {
        setState(() { isShiftTerbuka = false; });
      }
    } catch (e) {
      debugPrint('Error cek shift: $e');
      // Tidak lagi memaksa false agar popup tidak berkedip jika internet lambat
    }
  }

  // =======================================================
  // PROSES BUKA SHIFT LANGSUNG DARI OVERLAY KASIR
  // =======================================================
  Future<void> _prosesBukaShiftLangsung() async {
    if (modalAwalCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang modal awal wajib diisi!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isProsesBukaShift = true);
    int inputModal = int.tryParse(modalAwalCtrl.text) ?? 0;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/shift/buka'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: json.encode({
          'toko_id': idTokoAktif,
          'user_id': idKasirAktif,
          'modal_awal': inputModal
        })
      );

      final res = json.decode(response.body);
      
      if ((response.statusCode == 200 || response.statusCode == 201) && res['status'] == true) {
        // 1. KOSONGKAN FORM DAN HILANGKAN POPUP SEKETIKA!
        modalAwalCtrl.clear();
        setState(() {
           isShiftTerbuka = true; 
        });

        // 2. MUNCULKAN NOTIF SUKSES
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift Kasir Berhasil Dibuka!'), backgroundColor: Colors.green),
        );
        
        // 3. AMBIL DATA SHIFT ID DI LATAR BELAKANG
        _cekStatusShift(); 
      } else {
        // TANGKAP PESAN ERROR DARI SERVER
        String pesanError = 'Gagal membuka shift';
        if (res['messages'] != null && res['messages']['error'] != null) {
          pesanError = res['messages']['error'];
        } else if (res['message'] != null) {
          pesanError = res['message'];
        }
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Info Server: $pesanError'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4)
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error jaringan: $e'), backgroundColor: Colors.red));
    }
    
    if (mounted) setState(() => isProsesBukaShift = false);
  }

  Future<void> _muatDataPenggunaDanToko() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idTokoAktif = prefs.getInt('toko_id') ?? 1;
      idKasirAktif = prefs.getInt('user_id') ?? 1;
      userRole = prefs.getString('role') ?? 'kasir';
      namaToko = prefs.getString('nama_toko') ?? 'Smart Kasir';
      isFiturJasaAktif = prefs.getBool('fitur_jasa_aktif') ?? true;
      isFiturMejaAktif = prefs.getBool('fitur_meja_aktif') ?? false;
      isFiturTakeawayAktif = prefs.getBool('fitur_takeaway_aktif') ?? false;
    });

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/toko/$idTokoAktif'),
        headers: {'Accept': 'application/json'}
      );

      if (res.statusCode == 200) {
        final tokoData = json.decode(res.body)['data'];
        int ppnToko = int.tryParse(tokoData['ppn_persen']?.toString() ?? '0') ?? 0;

        if (tokoData['masa_aktif'] != null) {
          DateTime masaAktif = DateTime.parse(tokoData['masa_aktif']);
          DateTime hariIni = DateTime.now();
          int sisaHari = masaAktif.difference(hariIni).inDays;

          setState(() {
            namaToko = tokoData['nama_toko'] ?? namaToko;
            persenPpn = ppnToko;
            isLocked = sisaHari < 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error cek masa aktif: $e');
    }

    await _cekStatusShift();

    if (!isLocked) {
      ambilDataProduk();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> ambilDataProduk() async {
    final url = Uri.parse('$baseUrl/produk');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          data = responseData['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error Ambil Data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> mulaiScanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      String hasilScan = result.rawContent;
      if (hasilScan.isNotEmpty && hasilScan != '-1') {
        setState(() {
          pencarianController.text = hasilScan;
          kataKunci = hasilScan;
        });
      }
    } catch (e) {
      debugPrint('Error saat scanning barcode: $e');
    }
  }

  void tambahKeKeranjang(Map<String, dynamic> produk) {
    int stokTersedia = int.tryParse(produk['stok'].toString()) ?? 0;
    setState(() {
      int index = keranjang.indexWhere((item) => item['id'] == produk['id']);
      int harga = int.tryParse(produk['harga'].toString()) ?? 0;

      if (index != -1) {
        if (keranjang[index]['qty'] >= stokTersedia) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stok ${produk['nama']} tidak mencukupi! Sisa stok: $stokTersedia'), backgroundColor: Colors.red, duration: const Duration(seconds: 1)),
          );
          return;
        }
        keranjang[index]['qty'] += 1;
        keranjang[index]['subtotal'] = keranjang[index]['qty'] * harga;
      } else {
        if (stokTersedia < 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal! Stok ${produk['nama']} habis.'), backgroundColor: Colors.red, duration: const Duration(seconds: 1)),
          );
          return;
        }
        keranjang.add({
          'id': produk['id'],
          'nama': produk['nama'] ?? 'Produk',
          'harga': harga,
          'qty': 1,
          'subtotal': harga,
          'kategori_id': produk['kategori_id'], 
          'divisi_printer': produk['divisi_printer'] ?? 'kasir',
          'stok_maksimal': stokTersedia, 
          'tipe_pesanan': 'Dine In',
        });
      }
    });
    _simpanKeranjangLokal(); 
  }

  void kurangiDariKeranjang(Map<String, dynamic> produk) {
    setState(() {
      int index = keranjang.indexWhere((item) => item['id'] == produk['id']);
      if (index != -1) {
        if (keranjang[index]['qty'] > 1) {
          keranjang[index]['qty'] -= 1;
          int harga = int.tryParse(produk['harga'].toString()) ?? 0;
          keranjang[index]['subtotal'] = keranjang[index]['qty'] * harga;
        } else {
          keranjang.removeAt(index);
        }
      }
    });
    _simpanKeranjangLokal(); 
  }

  int getSubtotal() {
    int total = 0;
    for (var item in keranjang) {
      int h = int.tryParse(item['harga'].toString()) ?? 0;
      int q = int.tryParse(item['qty'].toString()) ?? 0;
      total += h * q;
    }
    return total;
  }

  int getNominalJasa() {
    return int.tryParse(nominalJasaCtrl.text) ?? 0;
  }

  int getPpnNominal() {
    int dasarPengenaanPajak = getSubtotal() + getNominalJasa();
    return persenPpn > 0 ? (dasarPengenaanPajak * persenPpn) ~/ 100 : 0;
  }

  int getGrandTotal() {
    return getSubtotal() + getNominalJasa() + getPpnNominal();
  }

  void kosongkanKeranjang() {
    setState(() {
      keranjang.clear();
      namaJasaCtrl.clear();
      nominalJasaCtrl.clear();
      noMejaCtrl.clear(); 
    });
    _simpanKeranjangLokal(); 
  }

  Future<void> prosesTransaksiPusat(
      BuildContext dialogContext, String metode, int uangBayar, int kembalian, String namaPelanggan) async {
    final url = Uri.parse('$baseUrl/simpanTransaksi');

    int finalPpnNominal = getPpnNominal();
    int finalGrandTotal = getGrandTotal();
    int nominalJasa = getNominalJasa();

    List<Map<String, dynamic>> finalDetailBelanja = [];

    for (var item in keranjang) {
      int h = int.tryParse(item['harga'].toString()) ?? 0;
      int q = int.tryParse(item['qty'].toString()) ?? 1;
      String tipePesananItem = item['tipe_pesanan'] ?? 'Dine In';

      finalDetailBelanja.add({
        'id': item['id'],
        'nama': "${item['nama']} ($tipePesananItem)", 
        'harga': h,
        'qty': q,
        'subtotal': h * q,
        'kategori_id': item['kategori_id'], 
        'divisi_printer': item['divisi_printer'] ?? 'kasir',
      });
    }

    if (nominalJasa > 0) {
      String namaJasa = namaJasaCtrl.text.isEmpty ? 'Jasa Tambahan' : namaJasaCtrl.text;
      finalDetailBelanja.add({
        'id': 0,
        'nama': 'Jasa: $namaJasa',
        'harga': nominalJasa,
        'qty': 1,
        'subtotal': nominalJasa,
        'kategori_id': null,
      });
    }

    Map<String, dynamic> payloadJson = {
      "toko_id": idTokoAktif,
      "user_id": idKasirAktif,
      "total_harga": finalGrandTotal,
      "ppn_persen": persenPpn,
      "ppn_nominal": finalPpnNominal,
      "uang_bayar": uangBayar,
      "kembalian": kembalian,
      "metode_pembayaran": metode,
      "nama_pelanggan": metode == 'kasbon' ? namaPelanggan : null, 
      "no_meja": isFiturMejaAktif && noMejaCtrl.text.isNotEmpty ? noMejaCtrl.text : null,
      "tipe_pesanan": keranjang.isNotEmpty && keranjang[0]['tipe_pesanan'] == 'Takeaway' ? 'takeaway' : 'dine_in',
      "items": finalDetailBelanja.map((item) => {
        "product_id": int.tryParse(item['id'].toString()) ?? 0,
        "qty": int.tryParse(item['qty'].toString()) ?? 1,
        "harga_satuan": int.tryParse(item['harga'].toString()) ?? 0,
        "subtotal": int.tryParse(item['subtotal'].toString()) ?? 0
      }).toList()
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: json.encode(payloadJson),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }

        setState(() {
          for (var itemKeranjang in finalDetailBelanja) {
            if (itemKeranjang['id'] != 0) {
              int indexProduk = data.indexWhere((p) => p['id'] == itemKeranjang['id']);
              if (indexProduk != -1 && data[indexProduk]['stok'] != null) {
                int stokLama = int.tryParse(data[indexProduk]['stok'].toString()) ?? 0;
                int qtyBeli = int.tryParse(itemKeranjang['qty'].toString()) ?? 0;
                data[indexProduk]['stok'] = (stokLama - qtyBeli).toString();
              }
            }
          }
        });

        // TANGKAP NILAI SEBELUM KERANJANG DIKOSONGKAN AGAR TIDAK RP 0 / HILANG
        int subtotalFix = getSubtotal();
        String? mejaFix = isFiturMejaAktif && noMejaCtrl.text.isNotEmpty ? noMejaCtrl.text : null;

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HalamanStruk(
                keranjang: finalDetailBelanja,
                totalBelanja: finalGrandTotal,
                subtotal: subtotalFix, // <--- Gunakan variabel yang ditangkap
                ppnNominal: finalPpnNominal,
                biayaJasa: nominalJasa,
                uangDiterima: uangBayar,
                uangKembalian: kembalian,
                noStruk: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                tanggal: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                metodePembayaran: metode == 'tunai' ? 'Tunai' : (metode == 'kasbon' ? 'Kasbon/Hutang' : 'Non-Tunai'),
                noMeja: mejaFix, // <--- Gunakan variabel meja yang ditangkap
              ),
            ),
          );
        }
        kosongkanKeranjang();

      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal oleh server: ${response.statusCode}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan koneksi!'), backgroundColor: Colors.red));
      }
    }
  }

  void tampilkanDialogPembayaran() {
    String metodePilih = 'tunai';
    TextEditingController uangBayarCtrl = TextEditingController();
    TextEditingController namaPelangganCtrl = TextEditingController(); 
    int kembalian = 0;
    int total = getGrandTotal();
    bool isProsesAPI = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Proses Pembayaran'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: metodePilih,
                      decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                      items: const [
                        DropdownMenuItem(value: 'tunai', child: Text('Uang Tunai')),
                        DropdownMenuItem(value: 'non_tunai', child: Text('Non-Tunai (QRIS / Rekening)')),
                        DropdownMenuItem(value: 'kasbon', child: Text('Kasbon / Catatan Hutang')), 
                      ],
                      onChanged: isProsesAPI
                          ? null
                          : (val) {
                              setDialogState(() {
                                metodePilih = val!;
                                if (metodePilih == 'non_tunai') {
                                  uangBayarCtrl.text = total.toString();
                                  kembalian = 0;
                                } else if (metodePilih == 'kasbon') {
                                  uangBayarCtrl.text = '0';
                                  kembalian = 0;
                                } else {
                                  uangBayarCtrl.clear();
                                  kembalian = 0;
                                }
                              });
                            },
                    ),
                    const SizedBox(height: 15),

                    if (metodePilih == 'kasbon') ...[
                      TextField(
                        controller: namaPelangganCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Pelanggan / Peminjam',
                          hintText: 'Cth: Bpk. Budi / Bu Ani',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],

                    if (metodePilih == 'tunai') ...[
                      TextField(
                        controller: uangBayarCtrl,
                        keyboardType: TextInputType.number,
                        enabled: !isProsesAPI,
                        decoration: const InputDecoration(
                            labelText: 'Uang Diterima (Rp)',
                            border: OutlineInputBorder()),
                        onChanged: (val) {
                          setDialogState(() {
                            int uang = int.tryParse(val) ?? 0;
                            kembalian = uang - total;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ActionChip(
                          backgroundColor: Colors.blue[50],
                          label: const Text('⚡ Uang Pas', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setDialogState(() {
                              uangBayarCtrl.text = total.toString();
                              kembalian = 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    if (metodePilih == 'tunai')
                      Text(
                        kembalian < 0
                            ? 'Uang Kurang: Rp ${kembalian.abs()}'
                            : 'Kembalian: Rp $kembalian',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kembalian < 0 ? Colors.red : Colors.green),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: isProsesAPI ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: isProsesAPI
                      ? null
                      : () async {
                          if (metodePilih == 'kasbon' && namaPelangganCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Nama pelanggan wajib diisi untuk kasbon!'), backgroundColor: Colors.red));
                            return;
                          }

                          int uangBayar = metodePilih == 'kasbon' ? 0 : (int.tryParse(uangBayarCtrl.text) ?? 0);
                          if (metodePilih == 'tunai' && uangBayar < total) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Uang bayar tidak mencukupi!'), backgroundColor: Colors.red));
                            return;
                          }

                          setDialogState(() {
                            isProsesAPI = true;
                          });

                          await prosesTransaksiPusat(
                              dialogContext, metodePilih, uangBayar, kembalian, namaPelangganCtrl.text);

                          if (dialogContext.mounted) {
                            setDialogState(() {
                              isProsesAPI = false;
                            });
                          }
                        },
                  child: isProsesAPI
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Bayar / Simpan', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  void tampilkanLembarKeranjang() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext konteksBawah) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Rincian Belanja",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            kosongkanKeranjang();
                          }, 
                          icon: const Icon(Icons.delete_sweep, color: Colors.red), 
                          label: const Text('Kosongkan', style: TextStyle(color: Colors.red))
                      )
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: keranjang.isEmpty
                        ? const Center(
                            child: Text('Keranjang masih kosong',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: keranjang.length,
                            itemBuilder: (context, i) {
                              var item = keranjang[i];
                              int h = int.tryParse(item['harga'].toString()) ?? 0;
                              int q = int.tryParse(item['qty'].toString()) ?? 0;
                              int maxStok = item['stok_maksimal'] ?? 0; 
                              int sub = h * q;
                              String tipeItem = item['tipe_pesanan'] ?? 'Dine In';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade200))
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(item['nama'] ?? 'Produk',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 15)),
                                        ),
                                        Text('Rp $sub',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blueAccent, fontSize: 15)),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (isFiturTakeawayAktif)
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  setModalState(() { keranjang[i]['tipe_pesanan'] = 'Dine In'; });
                                                  setState(() {});
                                                  _simpanKeranjangLokal();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: tipeItem == 'Dine In' ? Colors.blueAccent : Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Text('Dine In', style: TextStyle(fontSize: 10, color: tipeItem == 'Dine In' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              InkWell(
                                                onTap: () {
                                                  setModalState(() { keranjang[i]['tipe_pesanan'] = 'Takeaway'; });
                                                  setState(() {});
                                                  _simpanKeranjangLokal();
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: tipeItem == 'Takeaway' ? Colors.orange : Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Text('Takeaway', style: TextStyle(fontSize: 10, color: tipeItem == 'Takeaway' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          const SizedBox.shrink(),

                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                setModalState(() {
                                                  if (keranjang[i]['qty'] > 1) {
                                                    keranjang[i]['qty'] -= 1;
                                                    keranjang[i]['subtotal'] = keranjang[i]['qty'] * h;
                                                  } else {
                                                    keranjang.removeAt(i);
                                                  }
                                                });
                                                setState(() {}); 
                                                _simpanKeranjangLokal(); 
                                              },
                                              child: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 26),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('$q', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                if (keranjang[i]['qty'] >= maxStok) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Maksimal stok tercapai! Sisa stok hanya: $maxStok'), backgroundColor: Colors.red, duration: const Duration(seconds: 1)),
                                                  );
                                                  return;
                                                }
                                                setModalState(() {
                                                  keranjang[i]['qty'] += 1;
                                                  keranjang[i]['subtotal'] = keranjang[i]['qty'] * h;
                                                });
                                                setState(() {});
                                                _simpanKeranjangLokal(); 
                                              },
                                              child: const Icon(Icons.add_circle_outline, color: Colors.green, size: 26),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  if (isFiturMejaAktif) ...[
                    const Divider(thickness: 2),
                    const Text('Informasi Pemesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noMejaCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nomor Meja (Cth: VIP 1 / Meja 05)',
                        prefixIcon: const Icon(Icons.table_restaurant, color: Colors.orange),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        setModalState(() {});
                        setState(() {});
                        _simpanKeranjangLokal(); 
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (isFiturJasaAktif) ...[
                    const Divider(thickness: 2),
                    const Text('Layanan Tambahan / Jasa (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: namaJasaCtrl,
                            decoration: InputDecoration(
                              hintText: 'Nama Jasa',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (val) => _simpanKeranjangLokal(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nominalJasaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Nominal Rp',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (val) {
                              setModalState(() {});
                              setState(() {});
                              _simpanKeranjangLokal();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  const Divider(),
                  if (persenPpn > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PPN Otomatis ($persenPpn%)', style: const TextStyle(color: Colors.grey)),
                          Text('Rp ${getPpnNominal()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      Text('Rp ${getGrandTotal()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: keranjang.isEmpty && getNominalJasa() == 0
                          ? null
                          : () {
                              Navigator.pop(context);
                              tampilkanDialogPembayaran();
                            },
                      child: const Text('Konfirmasi & Proses',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLayarTerkunci() {
    bool isAdmin = userRole == 'admin' || userRole == 'superadmin';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 100, color: Colors.redAccent),
            const SizedBox(height: 20),
            const Text('Akses Kasir Terkunci', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              isAdmin
                  ? 'Masa aktif langganan sistem toko Anda telah habis. Harap segera lakukan pembayaran untuk membuka kembali fitur kasir.'
                  : 'Mohon maaf, Owner/Pemilik toko belum memperpanjang masa aktif aplikasi. Silakan hubungi pemilik toko untuk mengaktifkan kembali sistem kasir.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List dataTersaring = data.where((produk) {
      String cari = kataKunci.toLowerCase();
      bool cocokNama = produk['nama'].toString().toLowerCase().contains(cari);
      bool cocokKode = produk['kode_barang'] != null && 
          produk['kode_barang'].toString().toLowerCase().contains(cari);
      bool isBarang = produk['jenis'] != 'jasa';
      return (cocokNama || cocokKode) && isBarang;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Kasir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(namaToko, style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_connected),
            tooltip: 'Pengaturan Printer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanPrinter()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Riwayat Transaksi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HalamanRiwayat()),
              );
            },
          ),
        ],
      ),
      body: isLocked
          ? _buildLayarTerkunci()
          : Stack(
              children: [
                // ==========================================
                // 1. KONTEN UTAMA KASIR (Daftar Produk)
                // ==========================================
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      color: Colors.blueAccent,
                      child: TextField(
                        controller: pencarianController,
                        onChanged: (nilai) => setState(() => kataKunci = nilai),
                        onSubmitted: (nilai) => setState(() => kataKunci = nilai),
                        decoration: InputDecoration(
                          hintText: 'Cari barang / Scan Barcode...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                            onPressed: mulaiScanBarcode,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100, top: 10, left: 10, right: 10),
                              itemCount: dataTersaring.length,
                              itemBuilder: (context, index) {
                                var produk = dataTersaring[index];
                                int qtyDiKeranjang = 0;
                                int idxK = keranjang.indexWhere((k) => k['id'] == produk['id']);
                                if (idxK != -1) {
                                  qtyDiKeranjang = int.tryParse(keranjang[idxK]['qty'].toString()) ?? 0;
                                }

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(produk['nama'] ?? 'Produk', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              const SizedBox(height: 5),
                                              Text('Rp ${produk['harga'] ?? 0}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                                              const SizedBox(height: 5),
                                              Text('Sisa Stok: ${produk['stok'] ?? 0}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        if (qtyDiKeranjang > 0)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () => kurangiDariKeranjang(produk),
                                                child: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 32),
                                              ),
                                              Container(
                                                width: 35,
                                                alignment: Alignment.center,
                                                child: Text('$qtyDiKeranjang', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                              ),
                                              InkWell(
                                                onTap: () => tambahKeKeranjang(produk),
                                                child: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 32),
                                              ),
                                            ],
                                          )
                                        else
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blueAccent,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            onPressed: () => tambahKeKeranjang(produk),
                                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                                            label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // ==========================================
                // 2. MODAL OVERLAY BUKA SHIFT (GAYA WEBSITE)
                // ==========================================
                if (!isShiftTerbuka)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: const Color(0xE60F172A), 
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          elevation: 20,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          child: Padding(
                            padding: const EdgeInsets.all(25),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 15, spreadRadius: 5)
                                    ]
                                  ),
                                  child: const Icon(Icons.point_of_sale, size: 40, color: Colors.white),
                                ),
                                const SizedBox(height: 20),
                                const Text('Buka Shift Kasir', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 10),
                                const Text(
                                  'Silakan masukkan uang modal/kembalian di laci Anda untuk mulai melayani transaksi hari ini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                                ),
                                const SizedBox(height: 30),
                                TextField(
                                  controller: modalAwalCtrl,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                  decoration: InputDecoration(
                                    labelText: 'Uang Modal Awal (Rp)',
                                    hintText: 'Contoh: 100000',
                                    prefixIcon: const Icon(Icons.account_balance_wallet, color: Colors.blueAccent, size: 28),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
                                  ),
                                ),
                                const SizedBox(height: 25),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 0
                                    ),
                                    onPressed: isProsesBukaShift ? null : _prosesBukaShiftLangsung,
                                    icon: isProsesBukaShift
                                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : const Icon(Icons.lock_open, color: Colors.white, size: 22),
                                    label: Text(
                                      isProsesBukaShift ? 'Memproses...' : 'Buka Shift Sekarang',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: (keranjang.isEmpty && getNominalJasa() == 0 || isLocked || !isShiftTerbuka)
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.grey.withAlpha(76), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, -3))
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Belanja', style: TextStyle(color: Colors.grey)),
                      Text('Rp ${getGrandTotal()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      tampilkanLembarKeranjang();
                    },
                    child: const Text('Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}
