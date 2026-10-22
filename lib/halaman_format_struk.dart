import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tema.dart'; // Pastikan AppColors tersedia di tema.dart

class HalamanFormatStruk extends StatefulWidget {
  final String storeId;

  const HalamanFormatStruk({
    super.key,
    this.storeId = '1', // Default ke 1 untuk contoh
  });

  @override
  State<HalamanFormatStruk> createState() => _HalamanFormatStrukState();
}

class _HalamanFormatStrukState extends State<HalamanFormatStruk> {
  bool _isLoading = true;
  bool _isSaving = false;

  // State Pengaturan Struk
  bool _tampilkanLogo = false;
  bool _tampilkanAlamat = true;
  bool _tampilkanHargaSatuan = true;
  bool _tampilkanMetodePembayaran = true;
  int _jumlahSalinan = 1;
  final TextEditingController _catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _muatPengaturan();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _muatPengaturan() async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'struk_format_${widget.storeId}_';
    
    setState(() {
      _tampilkanLogo = prefs.getBool('${prefix}logo') ?? false;
      _tampilkanAlamat = prefs.getBool('${prefix}alamat') ?? true;
      _tampilkanHargaSatuan = prefs.getBool('${prefix}harga_satuan') ?? true;
      _tampilkanMetodePembayaran = prefs.getBool('${prefix}metode_bayar') ?? true;
      _jumlahSalinan = prefs.getInt('${prefix}salinan') ?? 1;
      _catatanController.text = prefs.getString('${prefix}catatan') ?? 'Terima kasih atas kunjungan Anda!';
      _isLoading = false;
    });
  }

  Future<void> _simpanPengaturan() async {
    setState(() => _isSaving = true);
    
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'struk_format_${widget.storeId}_';

    await prefs.setBool('${prefix}logo', _tampilkanLogo);
    await prefs.setBool('${prefix}alamat', _tampilkanAlamat);
    await prefs.setBool('${prefix}harga_satuan', _tampilkanHargaSatuan);
    await prefs.setBool('${prefix}metode_bayar', _tampilkanMetodePembayaran);
    await prefs.setInt('${prefix}salinan', _jumlahSalinan);
    await prefs.setString('${prefix}catatan', _catatanController.text.trim());

    if (!mounted) return;
    setState(() => _isSaving = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Format struk berhasil disimpan!'), backgroundColor: AppColors.primaryEmerald),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Format Struk', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Informasi Toko', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 8),
          _buildCard(
            child: Column(
              children: [
                _buildSwitchTile('Tampilkan Logo Toko', 'Cetak logo di bagian atas struk (jika didukung)', _tampilkanLogo, (val) => setState(() => _tampilkanLogo = val)),
                const Divider(height: 1),
                _buildSwitchTile('Tampilkan Alamat & Telepon', 'Cetak detail kontak di bawah nama toko', _tampilkanAlamat, (val) => setState(() => _tampilkanAlamat = val)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Rincian Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 8),
          _buildCard(
            child: Column(
              children: [
                _buildSwitchTile('Tampilkan Harga Satuan', 'Tampilkan rincian harga x jumlah untuk tiap produk', _tampilkanHargaSatuan, (val) => setState(() => _tampilkanHargaSatuan = val)),
                const Divider(height: 1),
                _buildSwitchTile('Tampilkan Metode Pembayaran', 'Tampilkan jenis pembayaran (Tunai, QRIS, dsb)', _tampilkanMetodePembayaran, (val) => setState(() => _tampilkanMetodePembayaran = val)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Catatan Bawah (Footer)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 8),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Barang yang sudah dibeli tidak dapat ditukar...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Jumlah Salinan Cetak', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14)),
          const SizedBox(height: 8),
          _buildCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Salinan per Transaksi', style: TextStyle(fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryEmerald),
                        onPressed: _jumlahSalinan > 1 ? () => setState(() => _jumlahSalinan--) : null,
                      ),
                      Text('$_jumlahSalinan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryEmerald),
                        onPressed: _jumlahSalinan < 5 ? () => setState(() => _jumlahSalinan++) : null,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSaving ? null : _simpanPengaturan,
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan Format Struk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      color: Colors.white,
      child: child,
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      value: value,
      activeColor: AppColors.primaryEmerald,
      onChanged: onChanged,
    );
  }
}
