import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HalamanKategori extends StatefulWidget {
  const HalamanKategori({super.key});

  @override
  State<HalamanKategori> createState() => _HalamanKategoriState();
}

class _HalamanKategoriState extends State<HalamanKategori> {
  final String baseUrl = 'https://smartkasir.shop/api/kategori';
  List daftarKategori = [];
  bool isLoading = true;
  final TextEditingController _kategoriCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ambilKategori();
  }

  Future<void> ambilKategori() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(baseUrl), headers: {
        'ngrok-skip-browser-warning': 'true',
      });
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        setState(() {
          daftarKategori = res['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> tambahKategori(String nama) async {
    if (nama.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: json.encode({'nama_kategori': nama}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _kategoriCtrl.clear();
        ambilKategori();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori berhasil ditambahkan!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> hapusKategori(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: {
        'ngrok-skip-browser-warning': 'true',
      });
      if (response.statusCode == 200) {
        ambilKategori();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kategori dihapus'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void tampilkanDialogTambah() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Tambah Kategori / Divisi'),
          content: TextField(
            controller: _kategoriCtrl,
            decoration: InputDecoration(
              hintText: 'Cth: Makanan, Minuman, Dapur',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () {
                Navigator.pop(context);
                tambahKategori(_kategoriCtrl.text);
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Kelola Kategori / Divisi Printer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : daftarKategori.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.category_outlined, size: 70, color: Colors.grey),
                      const SizedBox(height: 10),
                      const Text('Belum ada kategori/divisi.\nSistem otomatis menggunakan mode Kasir Tunggal.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                        onPressed: tampilkanDialogTambah,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Kategori Pertama'),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: ambilKategori,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: daftarKategori.length,
                    itemBuilder: (context, index) {
                      var kat = daftarKategori[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Icon(Icons.print, color: Colors.white, size: 20),
                          ),
                          title: Text(kat['nama_kategori'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => hapusKategori(int.parse(kat['id'].toString())),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: daftarKategori.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: Colors.blueAccent,
              onPressed: tampilkanDialogTambah,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Kategori', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
