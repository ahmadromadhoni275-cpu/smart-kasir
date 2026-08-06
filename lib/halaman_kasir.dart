import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart'; 
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
  bool isFiturJasaAktif = true;
  bool isFiturMejaAktif = false; 

  List data = [];
  bool isLoading = true;
  String kataKunci = "";
  TextEditingController pencarianController = TextEditingController();
  TextEditingController noMejaCtrl = TextEditingController(); 

  List<Map<String, dynamic>> keranjang = [];

  int persenPpn = 0;
  TextEditingController namaJasaCtrl = TextEditingController();
  TextEditingController nominalJasaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muatDataPenggunaDanToko();
  }

  Future<void> _muatDataPenggunaDanToko() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idTokoAktif = prefs.getInt('toko_id') ?? 1;
      idKasirAktif = prefs.getInt('user_id') ?? 1;
      userRole = prefs.getString('role') ?? 'kasir';
      namaToko = prefs.getString('nama_toko') ?? 'Smart Kasir';
      isFiturJasaAktif = prefs.getBool('fitur_jasa_aktif') ?? true;
      isFiturMejaAktif = prefs.getBool('fitur_meja_aktif') ?? false;
    });

    try {
      final res = await http.get(Uri.parse('$baseUrl/toko/$idTokoAktif'),
          headers: {'ngrok-skip-browser-warning': 'true'});

      if (res.statusCode == 200) {
        final tokoData = json.decode(res.body)['data'];
        int ppnToko =
            int.tryParse(tokoData['ppn_persen']?.toString() ?? '0') ?? 0;

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

    if (!isLocked) {
      ambilDataProduk();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> ambilDataProduk() async {
    final url = Uri.parse('$baseUrl/produk');
    try {
      final response =
          await http.get(url, headers: {'ngrok-skip-browser-warning': 'true'});
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
      String hasilScan = await FlutterBarcodeScanner.scanBarcode(
        '#ff6600',
        'Batal',
        true,
        ScanMode.BARCODE,
      );

      if (hasilScan != '-1') {
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
    setState(() {
      int index = keranjang.indexWhere((item) => item['id'] == produk['id']);
      int harga = int.tryParse(produk['harga'].toString()) ?? 0;

      if (index != -1) {
        keranjang[index]['qty'] += 1;
        keranjang[index]['subtotal'] = keranjang[index]['qty'] * harga;
      } else {
        keranjang.add({
          'id': produk['id'],
          'nama': produk['nama'] ?? 'Produk',
          'harga': harga,
          'qty': 1,
          'subtotal': harga,
          'kategori_id': produk['kategori_id'], // Diperlukan untuk multi-printer di struk
        });
      }
    });
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
  }

  // --- FUNGSI PROSES TRANSAKSI DENGAN PARAMETER NAMA PELANGGAN (KASBON) ---
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
      finalDetailBelanja.add({
        'id': item['id'],
        'nama': item['nama'] ?? 'Produk',
        'harga': h,
        'qty': q,
        'subtotal': h * q,
        'kategori_id': item['kategori_id'], // Kirim kategori_id untuk HalamanStruk
      });
    }

    if (nominalJasa > 0) {
      String namaJasa =
          namaJasaCtrl.text.isEmpty ? 'Jasa Tambahan' : namaJasaCtrl.text;
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
      // NAMA PELANGGAN UNTUK KASBON
      "nama_pelanggan": metode == 'kasbon' ? namaPelanggan : null, 
      "no_meja": isFiturMejaAktif && noMejaCtrl.text.isNotEmpty ? noMejaCtrl.text : null,
      "items": finalDetailBelanja
          .map((item) => {
                "product_id": int.tryParse(item['id'].toString()) ?? 0,
                "qty": int.tryParse(item['qty'].toString()) ?? 1,
                "harga_satuan": int.tryParse(item['harga'].toString()) ?? 0,
                "subtotal": int.tryParse(item['subtotal'].toString()) ?? 0
              })
          .toList()
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
              int indexProduk =
                  data.indexWhere((p) => p['id'] == itemKeranjang['id']);
              if (indexProduk != -1 && data[indexProduk]['stok'] != null) {
                int stokLama =
                    int.tryParse(data[indexProduk]['stok'].toString()) ?? 0;
                int qtyBeli =
                    int.tryParse(itemKeranjang['qty'].toString()) ?? 0;
                data[indexProduk]['stok'] = (stokLama - qtyBeli).toString();
              }
            }
          }
        });

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HalamanStruk(
                keranjang: finalDetailBelanja,
                totalBelanja: finalGrandTotal,
                subtotal: getSubtotal(),
                ppnNominal: finalPpnNominal,
                biayaJasa: nominalJasa,
                uangDiterima: uangBayar,
                uangKembalian: kembalian,
                noStruk: 'INV-${DateTime.now().millisecondsSinceEpoch}',
                tanggal: DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                metodePembayaran: metode == 'tunai' ? 'Tunai' : (metode == 'kasbon' ? 'Kasbon/Hutang' : 'Non-Tunai'),
                noMeja: isFiturMejaAktif ? noMejaCtrl.text : null,
              ),
            ),
          );
        }
        kosongkanKeranjang();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gagal oleh server: ${response.statusCode}'),
              backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Terjadi kesalahan koneksi!'),
            backgroundColor: Colors.red));
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

                    // KONDISI JIKA METODE KASBON DIPILIH
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

                    // KONDISI JIKA METODE TUNAI DIPILIH
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

                      // --- TOMBOL "UANG PAS" ---
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

                          // --- PEMANGGILAN FUNGSI DENGAN DATA KASBON ---
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
                  const Text("Rincian Belanja",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                              int sub = h * q;

                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(item['nama'] ?? 'Produk',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text('Rp $h / item'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Rp $sub',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent)),
                                    const SizedBox(width: 15),
                                    InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          if (keranjang[i]['qty'] > 1) {
                                            keranjang[i]['qty'] -= 1;
                                            keranjang[i]['subtotal'] =
                                                keranjang[i]['qty'] * h;
                                          } else {
                                            keranjang.removeAt(i);
                                          }
                                        });
                                        setState(() {}); 
                                      },
                                      child: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.redAccent,
                                          size: 28),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Text('$q',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          keranjang[i]['qty'] += 1;
                                          keranjang[i]['subtotal'] =
                                              keranjang[i]['qty'] * h;
                                        });
                                        setState(() {});
                                      },
                                      child: const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.green,
                                          size: 28),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  
                  if (isFiturMejaAktif) ...[
                    const Divider(thickness: 2),
                    const Text('Informasi Pemesanan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black54)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noMejaCtrl,
                      decoration: InputDecoration(
                        hintText: 'Nomor Meja (Cth: VIP 1 / Meja 05)',
                        prefixIcon: const Icon(Icons.table_restaurant, color: Colors.orange),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        setModalState(() {});
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (isFiturJasaAktif) ...[
                    const Divider(thickness: 2),
                    const Text('Layanan Tambahan / Jasa (Opsional)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black54)),
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
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
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
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 10),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (val) {
                              setModalState(() {});
                              setState(() {});
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
                          Text('PPN Otomatis ($persenPpn%)',
                              style: const TextStyle(color: Colors.grey)),
                          Text('Rp ${getPpnNominal()}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran',
                          style: TextStyle(fontSize: 18, color: Colors.grey)),
                      Text('Rp ${getGrandTotal()}',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: keranjang.isEmpty && getNominalJasa() == 0
                          ? null
                          : () {
                              Navigator.pop(context);
                              tampilkanDialogPembayaran();
                            },
                      child: const Text('Konfirmasi & Proses',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
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
            const Text('Akses Kasir Terkunci',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
            const Text('Smart Kasir',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(namaToko,
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
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
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  color: Colors.blueAccent,
                  child: TextField(
                    controller: pencarianController,
                    onChanged: (nilai) {
                      setState(() {
                        kataKunci = nilai;
                      });
                    },
                    onSubmitted: (nilai) {
                      setState(() {
                        kataKunci = nilai;
                      });
                    },
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              bottom: 100, top: 10, left: 10, right: 10),
                          itemCount: dataTersaring.length,
                          itemBuilder: (context, index) {
                            var produk = dataTersaring[index];

                            int qtyDiKeranjang = 0;
                            int idxK = keranjang
                                .indexWhere((k) => k['id'] == produk['id']);
                            if (idxK != -1) {
                              qtyDiKeranjang = int.tryParse(
                                      keranjang[idxK]['qty'].toString()) ?? 0;
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(produk['nama'] ?? 'Produk',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          const SizedBox(height: 5),
                                          Text('Rp ${produk['harga'] ?? 0}',
                                              style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15)),
                                          const SizedBox(height: 5),
                                          Text('Sisa Stok: ${produk['stok'] ?? 0}',
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    if (qtyDiKeranjang > 0)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () =>
                                                kurangiDariKeranjang(produk),
                                            child: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.redAccent,
                                                size: 32),
                                          ),
                                          Container(
                                            width: 35,
                                            alignment: Alignment.center,
                                            child: Text('$qtyDiKeranjang',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18)),
                                          ),
                                          InkWell(
                                            onTap: () =>
                                                tambahKeKeranjang(produk),
                                            child: const Icon(Icons.add_circle,
                                                color: Colors.blueAccent,
                                                size: 32),
                                          ),
                                        ],
                                      )
                                    else
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        onPressed: () =>
                                            tambahKeKeranjang(produk),
                                        icon: const Icon(Icons.add_shopping_cart,
                                            size: 18),
                                        label: const Text('Tambah',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
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
      bottomNavigationBar:
          (keranjang.isEmpty && getNominalJasa() == 0 || isLocked)
              ? const SizedBox.shrink()
              : Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withAlpha(76),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, -3))
                    ],
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Belanja',
                              style: TextStyle(color: Colors.grey)),
                          Text('Rp ${getGrandTotal()}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          tampilkanLembarKeranjang();
                        },
                        child: const Text('Bayar',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                ),
    );
  }
}
