import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart';
import 'core/services/store_service.dart';
import 'kerangka_navigasi.dart'; 

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
      
      // ==================================================
      // FITUR PINTAR: AUTO-REDIRECT JIKA HANYA PUNYA 1 TOKO
      // ==================================================
      if (data.length == 1) {
        await _gantiCabang(data[0], isAuto: true);
        return; // Hentikan render UI Pilih Cabang, langsung lompat!
      }
      
      if (mounted) setState(() => _stores = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tambahkan parameter opsional isAuto
  Future<void> _gantiCabang(dynamic store, {bool isAuto = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('store_id', int.tryParse(store['store_id'].toString()) ?? 0);
    await prefs.setString('nama_toko', store['name'] ?? 'Toko');
    await prefs.setString('role', store['role'] ?? 'KASIR'); 
    
    if (!mounted) return;
    
    // Jika user klik manual, tampilkan notifikasi. Jika otomatis, diam-diam saja.
    if (!isAuto) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil beralih ke ${store['name']}'), backgroundColor: AppColors.greenAccent));
    }
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const KerangkaNavigasi()),
      (route) => false,
    );
  }

  // FITUR BARU: Dialog untuk Membuat Cabang
  void _tampilFormBuatCabang() {
    final namaCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final teleponCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Cabang Baru', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl, 
                decoration: const InputDecoration(labelText: 'Nama Cabang *', hintText: 'Contoh: Toko Pusat')
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatCtrl, 
                decoration: const InputDecoration(labelText: 'Alamat Cabang')
              ),
              const SizedBox(height: 12),
              TextField(
                controller: teleponCtrl, 
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'No. Telepon')
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama cabang wajib diisi'), backgroundColor: AppColors.error));
                return;
              }
              
              Navigator.pop(context); // Tutup dialog
              setState(() => _isLoading = true);
              
              try {
                // Panggil endpoint POST /api/stores
                await StoreService.createStore({
                  'name': namaCtrl.text.trim(),
                  'address': alamatCtrl.text.trim(),
                  'phone': teleponCtrl.text.trim(),
                });
                
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cabang berhasil dibuat!'), backgroundColor: AppColors.greenAccent));
                _fetchStores(); // Refresh daftar cabang
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
      
      // FITUR BARU: Tombol Tambah Cabang
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tampilFormBuatCabang,
        backgroundColor: AppColors.primaryEmerald,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('Cabang Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
        : _stores.isEmpty
            // TAMPILAN JIKA DATA KOSONG (SOLUSI LAYAR BLANK)
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_mall_directory_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Belum Ada Cabang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    const SizedBox(height: 8),
                    const Text('Anda belum terdaftar di cabang manapun.\nSilakan buat cabang pertama Anda.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 60), // Spasi agar tidak tertutup FAB
                  ],
                ),
              )
            // TAMPILAN JIKA ADA DATA
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
                      leading: CircleAvatar(
                        backgroundColor: isCurrent ? AppColors.primaryEmerald.withOpacity(0.1) : AppColors.lightGray,
                        child: Icon(Icons.storefront, color: isCurrent ? AppColors.primaryEmerald : AppColors.navyActive),
                      ),
                      title: Text(store['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? AppColors.primaryEmerald : AppColors.navyActive)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(store['address'] != null && store['address'].toString().isNotEmpty ? store['address'] : 'Alamat belum diatur', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
