import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HalamanPegawai extends StatefulWidget {
  const HalamanPegawai({super.key});

  @override
  State<HalamanPegawai> createState() => _HalamanPegawaiState();
}

class _HalamanPegawaiState extends State<HalamanPegawai> {
  // PENTING: URL baseUrl diubah, karena di file Api.php route-nya adalah '/api/pegawai'
  final String baseUrl = 'https://smartkasir.shop/api/pegawai';

  List dataPegawai = [];
  bool isLoading = true;
  int _tokoId = 1;

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tokoId = prefs.getInt('toko_id') ?? 1;
    });
    ambilDataPegawai();
  }

  // --- 1. AMBIL DATA PEGAWAI ---
  Future<void> ambilDataPegawai() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?toko_id=$_tokoId'), 
        headers: {'ngrok-skip-browser-warning': 'true'}
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          dataPegawai = responseData['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error Ambil Data Pegawai: $e");
      setState(() => isLoading = false);
    }
  }

  // --- 2. TAMBAH PEGAWAI BARU ---
  Future<void> simpanPegawai(String username, String email, String noWa, String password) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    
    try {
      final response = await http.post(
        Uri.parse(baseUrl), // Sesuai dengan route POST 'api/pegawai'
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
        body: json.encode({
          'toko_id': _tokoId,
          'username': username,
          'email': email,
          'no_wa': noWa,
          'password': password,
          'role': 'kasir'
        }),
      );

      Navigator.pop(context); // Tutup loading

      if (response.statusCode == 201) {
        await ambilDataPegawai();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kasir baru berhasil didaftarkan!'), backgroundColor: Colors.green));
        }
      } else {
        final data = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Gagal mendaftar'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup loading jika error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error jaringan saat mendaftar'), backgroundColor: Colors.red));
      }
    }
  }

  // --- 3. UBAH STATUS (AKTIF / NON-AKTIF) ---
  Future<void> ubahStatus(int id, int statusSekarang) async {
    // Balik status: jika 1 (aktif) jadikan 0 (nonaktif), dan sebaliknya
    int statusBaru = statusSekarang == 1 ? 0 : 1;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/status/$id'), // Sesuai dengan route POST 'api/pegawai/status/(:num)' di CodeIgniter
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
        body: json.encode({'is_active': statusBaru}),
      );

      if (response.statusCode == 200) {
        await ambilDataPegawai();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(statusBaru == 1 ? 'Akun diaktifkan!' : 'Akun dinonaktifkan!'), backgroundColor: statusBaru == 1 ? Colors.green : Colors.orange));
        }
      }
    } catch (e) {
      debugPrint('Error Status: $e');
    }
  }

  // --- 4. HAPUS PEGAWAI PERMANEN ---
  Future<void> hapusPegawai(int id) async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/hapus/$id'), // Sesuai dengan route POST 'api/pegawai/hapus/(:num)' di CodeIgniter
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      Navigator.pop(context); // Tutup loading

      if (response.statusCode == 200) {
        await ambilDataPegawai();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun pegawai telah dihapus permanen.'), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('Error Hapus: $e');
    }
  }

  // --- DIALOG KONFIRMASI HAPUS ---
  void konfirmasiHapus(int id, String nama) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Apakah Anda yakin ingin menghapus akun $nama secara permanen?\n\nPerhatian: Data yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              hapusPegawai(id);
            },
            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- FORMULIR PENDAFTARAN KASIR (BOTTOM SHEET) ---
  void tampilkanFormTambah() {
    TextEditingController userCtrl = TextEditingController();
    TextEditingController emailCtrl = TextEditingController();
    TextEditingController waCtrl = TextEditingController();
    TextEditingController passCtrl = TextEditingController();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 20,
                  left: 20,
                  right: 20),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                        child: Container(
                            width: 50,
                            height: 5,
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10)))),
                    const SizedBox(height: 20),
                    const Text('👤 Tambah Kasir Baru',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextField(
                        controller: userCtrl,
                        decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                    const SizedBox(height: 15),
                    TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                    const SizedBox(height: 15),
                    TextField(
                        controller: waCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                            labelText: 'No WhatsApp',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                    const SizedBox(height: 15),
                    TextField(
                        controller: passCtrl,
                        obscureText: obscure,
                        decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setModalState(() => obscure = !obscure)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                        onPressed: () {
                          if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Username dan Password wajib diisi!'), backgroundColor: Colors.red));
                            return;
                          }
                          Navigator.pop(context);
                          simpanPegawai(userCtrl.text, emailCtrl.text, waCtrl.text, passCtrl.text);
                        },
                        child: const Text('Daftarkan Kasir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Kelola Pegawai', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dataPegawai.isEmpty
              ? const Center(child: Text('Belum ada data pegawai.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: ambilDataPegawai,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 80),
                    itemCount: dataPegawai.length,
                    itemBuilder: (context, index) {
                      var item = dataPegawai[index];
                      int idPegawai = int.parse(item['id'].toString());
                      bool isActive = int.parse(item['is_active'].toString()) == 1;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: isActive ? Colors.blueAccent.withAlpha(40) : Colors.red.withAlpha(40),
                            child: Icon(Icons.person, color: isActive ? Colors.blueAccent : Colors.red),
                          ),
                          title: Text(item['username'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text('Role: ${item['role'].toString().toUpperCase()}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                              Text('WA: ${item['no_wa'] ?? '-'}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(isActive ? 'Aktif' : 'Nonaktif',
                                    style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'status') {
                                    ubahStatus(idPegawai, isActive ? 1 : 0);
                                  } else if (value == 'hapus') {
                                    konfirmasiHapus(idPegawai, item['username']);
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem(
                                    value: 'status',
                                    child: Row(
                                      children: [
                                        Icon(isActive ? Icons.block : Icons.check_circle, color: isActive ? Colors.orange : Colors.green),
                                        const SizedBox(width: 10),
                                        Text(isActive ? 'Nonaktifkan Akun' : 'Aktifkan Akun'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'hapus',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 10),
                                        Text('Hapus Permanen', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: tampilkanFormTambah,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kasir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
