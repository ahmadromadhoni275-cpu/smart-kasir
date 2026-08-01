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
  // URL telah disesuaikan ke hosting AnymHost Anda
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

  String formatWaktu(String waktuServer) {
    try {
      DateTime parsed =
          DateTime.parse("${waktuServer.replaceAll(' ', 'T')}+07:00").toLocal();
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
        title: const Text('Notifikasi Perangkat Owner',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dataNotifikasi.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('Belum ada notifikasi sistem.',
                          style: TextStyle(color: Colors.grey)),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isUnread ? Colors.blue.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: isUnread
                              ? Border.all(color: Colors.blue.shade200)
                              : null,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withAlpha(20),
                                blurRadius: 5,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor:
                                isUnread ? Colors.blueAccent : Colors.grey,
                            child: const Icon(Icons.notifications,
                                color: Colors.white),
                          ),
                          title: Text(
                            item['judul'] ?? 'Pemberitahuan',
                            style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text(item['pesan'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize:
                                          13)), // <-- TYPO DIPERBAIKI DI SINI
                              const SizedBox(height: 8),
                              Text(formatWaktu(item['created_at'].toString()),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11)),
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
