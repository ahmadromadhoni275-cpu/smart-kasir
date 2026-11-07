import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';
import 'core/services/store_service.dart';
import 'models/store_model.dart';
import 'kerangka_navigasi.dart';

class HalamanPilihCabang extends StatefulWidget {
  const HalamanPilihCabang({super.key});

  @override
  State<HalamanPilihCabang> createState() => _HalamanPilihCabangState();
}

class _HalamanPilihCabangState extends State<HalamanPilihCabang> {
  bool _isLoading = true;
  bool _isSelecting = false;

  List<StoreModel> _stores = [];

  int _currentStoreId = 0;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  // ============================================================
  // NOTIFIKASI SUKSES
  // ============================================================

  void _tampilNotifSukses(String judul, String pesan) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowBlue,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryEmerald,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                judul,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyActive,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pesan,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AMBIL DAFTAR CABANG DARI API
  // ============================================================

  Future<void> _fetchStores() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      _currentStoreId = prefs.getInt('store_id') ?? 0;

      // Ambil data cabang dari backend.
      final List<dynamic> rawData = await StoreService.getStores();

      // Konversi JSON menjadi StoreModel.
      final List<StoreModel> data = rawData.map((item) {
        return StoreModel.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();

      // Hanya tampilkan cabang yang aktif dan memiliki akses aktif.
      final List<StoreModel> activeStores = data.where((store) {
        return store.storeId > 0 &&
            store.status == 'ACTIVE' &&
            store.accessStatus == 'ACTIVE';
      }).toList();

      if (!mounted) return;

      // Jika hanya memiliki satu cabang aktif, langsung masuk.
      if (activeStores.length == 1) {
        await _gantiCabang(activeStores.first, isAuto: true);
        return;
      }

      setState(() {
        _stores = activeStores;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _stores = [];
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // PILIH / GANTI CABANG
  // ============================================================

  Future<void> _gantiCabang(
    StoreModel store, {
    bool isAuto = false,
  }) async {
    if (_isSelecting) return;

    if (store.storeId <= 0 ||
        store.status != 'ACTIVE' ||
        store.accessStatus != 'ACTIVE') {
      _tampilNotifSukses(
        'Cabang tidak tersedia',
        'Cabang ini tidak aktif atau akses pengguna tidak tersedia.',
      );
      return;
    }

    setState(() {
      _isSelecting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('store_id', store.storeId);
      await prefs.setString('nama_toko', store.name);
      await prefs.setString('role', store.role);

      if (!mounted) return;

      if (!isAuto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil beralih ke ${store.name}'),
            backgroundColor: AppColors.primaryEmerald,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const KerangkaNavigasi(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSelecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih cabang: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  // ============================================================
  // FORM BUAT CABANG BARU
  // ============================================================

  void _tampilFormBuatCabang() {
    final namaCtrl = TextEditingController();
    final alamatCtrl = TextEditingController();
    final teleponCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.storefront,
              color: AppColors.smartBlue,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Buat Cabang Baru',
                style: TextStyle(
                  color: AppColors.navyActive,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Cabang *',
                  hintText: 'Contoh: Toko Pusat',
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: alamatCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Alamat Cabang',
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: teleponCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'No. Telepon',
                  filled: true,
                  fillColor: AppColors.lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              namaCtrl.dispose();
              alamatCtrl.dispose();
              teleponCtrl.dispose();
            },
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final nama = namaCtrl.text.trim();

              if (nama.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nama cabang wajib diisi'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              namaCtrl.dispose();
              alamatCtrl.dispose();
              teleponCtrl.dispose();

              if (!mounted) return;

              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });

              try {
                await StoreService.createStore({
                  'name': nama,
                  'address': alamatCtrl.text.trim(),
                  'phone': teleponCtrl.text.trim(),
                });

                if (!mounted) return;

                await _fetchStores();

                if (!mounted) return;

                _tampilNotifSukses(
                  'Berhasil!',
                  'Cabang baru berhasil dibuat.',
                );
              } catch (e) {
                if (!mounted) return;

                setState(() {
                  _isLoading = false;
                  _errorMessage = null;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst('Exception: ', ''),
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Simpan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU CABANG
  // ============================================================

  Widget _buildStoreCard(StoreModel store) {
    final bool isCurrent = store.storeId == _currentStoreId;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrent
              ? AppColors.smartBlue
              : AppColors.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: isCurrent
              ? AppColors.smartBlue.withOpacity(0.1)
              : AppColors.lightGray,
          child: Icon(
            Icons.storefront,
            color: isCurrent
                ? AppColors.smartBlue
                : AppColors.navyActive,
          ),
        ),
        title: Text(
          store.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCurrent
                ? AppColors.smartBlue
                : AppColors.navyActive,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              store.address.isNotEmpty
                  ? store.address
                  : 'Alamat belum diatur',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Akses: ${store.role}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'CABANG AKTIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: isCurrent
            ? const Icon(
                Icons.check_circle,
                color: AppColors.smartBlue,
              )
            : ElevatedButton(
                onPressed: _isSelecting
                    ? null
                    : () => _gantiCabang(store),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyActive,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Pilih',
                  style: TextStyle(color: Colors.white),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // KONDISI KOSONG
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_mall_directory_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Cabang',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.navyActive,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Anda belum memiliki atau terdaftar di cabang aktif manapun.\nSilakan buat cabang pertama Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _tampilFormBuatCabang,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Buat Toko Pertama',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // KONDISI ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Cabang',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.navyActive,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Terjadi kesalahan saat mengambil data.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchStores,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.smartBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pilih Cabang',
          style: TextStyle(
            color: AppColors.navyActive,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(
          color: AppColors.navyActive,
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _isLoading ? null : _fetchStores,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading || _isSelecting
            ? null
            : _tampilFormBuatCabang,
        backgroundColor: AppColors.smartBlue,
        icon: const Icon(
          Icons.add_business,
          color: Colors.white,
        ),
        label: const Text(
          'Cabang Baru',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.smartBlue,
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _stores.isEmpty
                  ? _buildEmptyState()
                  : Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: _fetchStores,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              16,
                              16,
                              100,
                            ),
                            children: [
                              const Text(
                                'Pilih toko atau cabang yang ingin Anda kelola.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._stores.map(_buildStoreCard),
                            ],
                          ),
                        ),
                        if (_isSelecting)
                          Container(
                            color: Colors.black.withOpacity(0.15),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.smartBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
