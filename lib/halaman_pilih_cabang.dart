import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart';
import 'core/services/store_service.dart';
import 'models/store_model.dart'; // Import model yang sudah dibuat
import 'kerangka_navigasi.dart'; 

class HalamanPilihCabang extends StatefulWidget {
  const HalamanPilihCabang({super.key});

  @override
  State<HalamanPilihCabang> createState() => _HalamanPilihCabangState();
}

class _HalamanPilihCabangState extends State<HalamanPilihCabang> {
  bool _isLoading = true;
  List<StoreModel> _stores = [];
  int _currentStoreId = 0;

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  void _tampilNotifSukses(String judul, String pesan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle, color: AppColors.primaryEmerald, size: 48),
              ),
              const SizedBox(height: 20),
              Text(judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 12),
              Text(pesan, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchStores() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentStoreId = prefs.getInt('store_id') ?? 0;
      
      // Mengambil dynamic list dari API, mapping menjadi List<StoreModel>
      final List<dynamic> rawData = await StoreService.getStores();
      final List<StoreModel> data = rawData.map((e) => StoreModel.fromJson(e)).toList();
      
      // LOGIKA: Auto-Redirect jika hanya punya 1 toko yang aktif
      if (data.length == 1) {
        await _gantiCabang(data[0], isAuto: true);
        return; 
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

  Future<void> _gantiCabang(StoreModel store, {bool isAuto = false}) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('store_id', store.storeId);
    await prefs.setString('nama_toko', store.name);
    await prefs.setString('role', store.role); 
    
    if (!mounted) return;
    
    if (!isAuto) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Berhasil beralih ke ${store.name}'), 
        backgroundColor: AppColors.primaryEmerald,
        behavior: SnackBarBehavior.floating,
      ));
    }
    
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const KerangkaNavigasi()), (route) => false);
  }

  void _tampilFormBuatCabang() {
    final namaCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final teleponCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storefront, color: AppColors.smartBlue),
            SizedBox(width: 12),
            Text('Buat Cabang Baru', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl, 
                decoration: InputDecoration(
                  labelText: 'Nama Cabang *', 
                  hintText: 'Contoh: Toko Pusat',
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatCtrl, 
                decoration: InputDecoration(
                  labelText: 'Alamat Cabang',
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                )
              ),
              const SizedBox(height: 12),
              TextField(
                controller: teleponCtrl, 
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'No. Telepon',
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                )
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama cabang wajib diisi'), backgroundColor: AppColors.warning));
                return;
              }
              
              Navigator.pop(context); // Tutup dialog
              setState(() => _isLoading = true);
              
              try {
                await StoreService.createStore({
                  'name': namaCtrl.text.trim(),
                  'address': alamatCtrl.text.trim(),
                  'phone': teleponCtrl.text.trim(),
                });
                
                // Tampilkan popup sukses yang cantik
                _tampilNotifSukses('Berhasil!', 'Cabang baru telah dibuat dan ditambahkan ke daftar Anda.');
                _fetchStores(); // Refresh daftar
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tampilFormBuatCabang,
        backgroundColor: AppColors.smartBlue,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('Cabang Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.smartBlue))
        : _stores.isEmpty
            // LOGIKA: Jika tidak ada toko sama sekali, paksa buat
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_mall_directory_outlined, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Belum Ada Cabang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    const SizedBox(height: 8),
                    const Text('Anda belum memiliki atau terdaftar di cabang manapun.\nSilakan buat cabang pertama Anda.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _tampilFormBuatCabang,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Buat Toko Pertama', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 60), 
                  ],
                ),
              )
            // LOGIKA: Menampilkan pilihan toko
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _stores.length,
                itemBuilder: (context, index) {
                  final store = _stores[index];
                  final bool isCurrent = store.storeId == _currentStoreId;
                  
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), 
                      side: BorderSide(color: isCurrent ? AppColors.smartBlue : AppColors.border, width: isCurrent ? 2 : 1)
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: isCurrent ? AppColors.smartBlue.withOpacity(0.1) : AppColors.lightGray,
                        child: Icon(Icons.storefront, color: isCurrent ? AppColors.smartBlue : AppColors.navyActive),
                      ),
                      title: Text(store.name, style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? AppColors.smartBlue : AppColors.navyActive, fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(store.address.isNotEmpty ? store.address : 'Alamat belum diatur', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Text('Akses: ${store.role}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                              ),
                              const SizedBox(width: 8),
                              if (store.status != 'ACTIVE')
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('NONAKTIF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                                ),
                            ],
                          )
                        ],
                      ),
                      trailing: isCurrent 
                          ? const Icon(Icons.check_circle, color: AppColors.smartBlue)
                          : ElevatedButton(
                              onPressed: () => _gantiCabang(store),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyActive, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                              ),
                              child: const Text('Pilih', style: TextStyle(color: Colors.white)),
                            ),
                    ),
                  );
                },
              ),
    );
  }
}
