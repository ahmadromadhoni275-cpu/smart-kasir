import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class HalamanNotifikasi extends StatefulWidget {
  const HalamanNotifikasi({super.key});

  @override
  State<HalamanNotifikasi> createState() => _HalamanNotifikasiState();
}

class _HalamanNotifikasiState extends State<HalamanNotifikasi> {
  final String baseUrl = 'https://smartkasir.shop/api/notifikasi';
  List dataNotifikasi = [];
  bool isLoading = true;
  int tokoId = 1;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tokoId = prefs.getInt('toko_id') ?? 1;
    });
    ambilNotifikasi();
  }

  Future<void> ambilNotifikasi() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?toko_id=$tokoId'),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() {
          dataNotifikasi = res['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Fungsi untuk menandai satu pesan telah dibaca
  Future<void> tandaiDibaca(int idNotif, int index) async {
    // Ubah UI seketika agar terasa cepat
    setState(() {
      dataNotifikasi[index]['is_read'] = 1;
    });

    try {
      await http.post(
        Uri.parse('$baseUrl/tandai-dibaca'),
        body: jsonEncode({'id': idNotif}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      debugPrint('Gagal update status baca: $e');
    }
  }

  // Fungsi massal: Tandai semua dibaca
  Future<void> tandaiSemuaDibaca() async {
    setState(() {
      for (var item in dataNotifikasi) {
        item['is_read'] = 1;
      }
    });

    try {
      await http.post(
        Uri.parse('$baseUrl/tandai-semua-dibaca'),
        body: jsonEncode({'toko_id': tokoId}),
        headers: {'Content-Type': 'application/json'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua notifikasi ditandai telah dibaca')),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // Fungsi massal: Hapus semua
  Future<void> hapusSemua() async {
    setState(() => isLoading = true);
    try {
      await http.post(
        Uri.parse('$baseUrl/hapus-semua'),
        body: jsonEncode({'toko_id': tokoId}),
        headers: {'Content-Type': 'application/json'},
      );
      setState(() {
        dataNotifikasi.clear();
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua notifikasi berhasil dihapus')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Menampilkan Pop-up detail pesan ala aplikasi chat
  void tampilkanDetailPesan(Map item, int index) {
    // Jika belum dibaca, langsung tandai dibaca saat di-klik
    if (item['is_read'].toString() == '0') {
      tandaiDibaca(int.parse(item['id'].toString()), index);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(
                item['tipe'] == 'pembayaran' ? Icons.payment : Icons.campaign,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['judul'] ?? 'Pemberitahuan',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatWaktu(item['created_at'].toString()),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  item['pesan'] ?? '',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  String formatWaktu(String waktuServer) {
    try {
      DateTime parsed = DateTime.parse("${waktuServer.replaceAll(' ', 'T')}+07:00").toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(parsed);
    } catch (e) {
      return waktuServer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'tandai') {
                tandaiSemuaDibaca();
              } else if (value == 'hapus') {
                hapusSemua();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'tandai',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Tandai semua dibaca'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'hapus',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Hapus semua'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dataNotifikasi.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('Belum ada notifikasi sistem.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: ambilNotifikasi,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: dataNotifikasi.length,
                    itemBuilder: (context, index) {
                      var item = dataNotifikasi[index];
                      bool isUnread = item['is_read'].toString() == '0';

                      // Menentukan ikon berdasarkan tipe (opsional, jika dari server ada field 'tipe')
                      IconData iconNotif = Icons.notifications;
                      if (item['tipe'] == 'pembayaran') iconNotif = Icons.receipt_long;
                      if (item['tipe'] == 'pengumuman') iconNotif = Icons.campaign;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isUnread ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: isUnread ? Border.all(color: Colors.blue.shade200) : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(20),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: ListTile(
                          onTap: () => tampilkanDetailPesan(item, index),
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: isUnread ? Colors.blueAccent : Colors.grey.shade400,
                            child: Icon(iconNotif, color: Colors.white),
                          ),
                          title: Text(
                            item['judul'] ?? 'Pemberitahuan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Terpotong jika terlalu panjang
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                item['pesan'] ?? '',
                                maxLines: 2, // Pesan di luar hanya tampil 2 baris
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatWaktu(item['created_at'].toString()),
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
