import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart';
import 'core/services/store_service.dart';
import 'kerangka_navigasi_utama.dart'; // Untuk me-restart UI ke awal

class HalamanPilihCabang extends StatefulWidget {
  const HalamanPilihCabang({super.key});

  @override
  State<HalamanPilihCabang> createState() => _HalamanPilihCabangState();
}

class _HalamanPilihCabangState extends State<HalamanPilihCabang> {
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
      final prefs = await SharedPreferences.getInstance();
      _currentStoreId = prefs.getInt('store_id') ?? 0;
      
      final data = await StoreService.getStores();
      setState(() => _stores = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _gantiCabang(dynamic store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('store_id', int.parse(store['store_id'].toString()));
    await prefs.setString('nama_toko', store['name']);
    await prefs.setString('role', store['role']); // Role user di cabang tsb
    
    // Opsional: Hapus keranjang kasir (cart) yang tersimpan jika ada agar tidak tercampur

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil beralih ke ${store['name']}'), backgroundColor: AppColors.primaryEmerald));
    
    // RESTART APLIKASI / NAVIGASI KE AWAL AGAR SEMUA DATA ME-REFRESH
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const KerangkaNavigasiUtama()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pilih Cabang', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _stores.length,
            itemBuilder: (context, index) {
              final store = _stores[index];
              final bool isCurrent = int.parse(store['store_id'].toString()) == _currentStoreId;
              
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), 
                  side: BorderSide(color: isCurrent ? AppColors.primaryEmerald : AppColors.border, width: isCurrent ? 2 : 1)
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightGray,
                    child: Icon(Icons.storefront, color: AppColors.navyActive),
                  ),
                  title: Text(store['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? AppColors.primaryEmerald : AppColors.navyActive)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(store['address'] ?? 'Alamat belum diatur', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text('Peran Anda: ${store['role']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                      )
                    ],
                  ),
                  trailing: isCurrent 
                      ? const Icon(Icons.check_circle, color: AppColors.primaryEmerald)
                      : ElevatedButton(
                          onPressed: () => _gantiCabang(store),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyActive, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('Gunakan', style: TextStyle(color: Colors.white)),
                        ),
                ),
              );
            },
          ),
    );
  }
}
