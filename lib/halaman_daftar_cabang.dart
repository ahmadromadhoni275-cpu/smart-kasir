import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart';
import 'core/services/store_service.dart';
import 'halaman_tambah_cabang.dart';
// import 'halaman_profil_toko.dart'; // Aktifkan jika HalamanProfilToko sudah bisa menerima parameter ID Toko spesifik

class HalamanDaftarCabang extends StatefulWidget {
  const HalamanDaftarCabang({super.key});

  @override
  State<HalamanDaftarCabang> createState() => _HalamanDaftarCabangState();
}

class _HalamanDaftarCabangState extends State<HalamanDaftarCabang> {
  bool _isLoading = true;
  List<dynamic> _stores = [];
  int _currentStoreId = 0;

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    setState(() => _isLoading = true);
    try {
      // Ambil ID Cabang yang sedang aktif digunakan di sesi ini
      final prefs = await SharedPreferences.getInstance();
      _currentStoreId = prefs.getInt('store_id') ?? 0;
      
      // Ambil daftar seluruh cabang dari API
      final data = await StoreService.getStores();
      setState(() => _stores = data);
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNotif(String pesan, Color warna) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: warna, behavior: SnackBarBehavior.floating),
    );
  }

  void _ubahStatusCabang(int storeId, String currentStatus) {
    // TODO: Implementasi pemanggilan API untuk mengubah status cabang (PATCH /api/stores/{id}/status)
    // Karena endpoint ini belum kita buat detail di StoreService, kita tampilkan notifikasi sementara
    final newStatus = currentStatus == 'ACTIVE' ? 'Nonaktif' : 'Aktif';
    _showNotif('Fitur ubah status ke $newStatus akan segera tersedia.', Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Cabang', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryEmerald,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('Tambah Cabang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          // Navigasi ke halaman Tambah Cabang, lalu refresh data jika berhasil
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const HalamanTambahCabang())
          ).then((berhasil) {
            if (berhasil == true) _fetchStores();
          });
        },
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : _stores.isEmpty
          ? const Center(child: Text('Belum ada cabang yang terdaftar.', style: TextStyle(color: AppColors.textSecondary)))
          : ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80), // Bottom 80 agar tidak tertutup FAB
              itemCount: _stores.length,
              itemBuilder: (context, index) {
                final store = _stores[index];
                final bool isCurrent = int.parse(store['store_id'].toString()) == _currentStoreId;
                final bool isActive = store['store_status'] == 'ACTIVE';
                
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), 
                    side: BorderSide(color: isCurrent ? AppColors.primaryEmerald : AppColors.border, width: isCurrent ? 2 : 1)
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: isCurrent ? AppColors.primaryEmerald.withOpacity(0.1) : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(10)
                      ),
                      child: Icon(Icons.storefront, color: isCurrent ? AppColors.primaryEmerald : AppColors.navyActive),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(store['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 16)),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primaryEmerald, borderRadius: BorderRadius.circular(4)),
                            child: const Text('Aktif Saat Ini', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(child: Text(store['address'] ?? 'Alamat belum diatur', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(store['phone'] ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Badge Status Operasional Cabang
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green.shade50 : Colors.red.shade50, 
                                borderRadius: BorderRadius.circular(6)
                              ),
                              child: Text(
                                isActive ? 'Buka / Aktif' : 'Tutup / Nonaktif', 
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red)
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Badge Role Pengguna di Cabang Tersebut
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                              child: Text('Peran: ${store['role']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                            )
                          ],
                        )
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                      onSelected: (value) {
                        if (value == 'edit') {
                           _showNotif('Fitur edit spesifik cabang segera hadir.', Colors.blue);
                           // Nantinya Anda bisa arahkan ke: 
                           // Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanProfilToko(storeId: store['store_id'])));
                        } else if (value == 'status') {
                          _ubahStatusCabang(int.parse(store['store_id'].toString()), store['store_status']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Edit Profil Cabang')])),
                        PopupMenuItem(
                          value: 'status', 
                          child: Row(children: [
                            Icon(isActive ? Icons.block : Icons.check_circle, size: 18, color: isActive ? Colors.red : Colors.green), 
                            const SizedBox(width: 8), 
                            Text(isActive ? 'Nonaktifkan Cabang' : 'Aktifkan Cabang')
                          ])
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
