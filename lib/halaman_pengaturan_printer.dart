import 'dart:ui';
import 'package:flutter/material.dart';
import 'tema.dart'; 
import 'core/services/printer_service.dart';
import 'models/printer_model.dart';
import 'halaman_format_struk.dart'; 
import 'halaman_riwayat_cetak.dart';

class HalamanPengaturanPrinter extends StatefulWidget {
  final String storeId;
  final String namaCabang; 

  const HalamanPengaturanPrinter({
    super.key,
    required this.storeId,
    this.namaCabang = 'Toko Utama',
  });

  @override
  State<HalamanPengaturanPrinter> createState() => _HalamanPengaturanPrinterState();
}

class _HalamanPengaturanPrinterState extends State<HalamanPengaturanPrinter> {
  final PrinterService _service = PrinterService();
  PrinterModel _printer = const PrinterModel();
  
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final result = await _service.loadSettings(widget.storeId);
      if (!mounted) return;
      setState(() {
        _printer = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings(PrinterModel value) async {
    setState(() => _printer = value);
    try {
      await _service.saveSettings(storeId: widget.storeId, printer: value);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyimpan pengaturan'), backgroundColor: AppColors.error),
      );
    }
  }

  void _cariPerangkat() async {
    if (_printer.connectionType == PrinterConnectionType.wifi) {
      _tampilkanDialogInputIP();
      return;
    }
    
    if (_printer.connectionType == PrinterConnectionType.usb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur USB OTG sedang dalam pengembangan.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final devices = await _service.scanDevices(_printer.connectionType);
      if (!mounted) return;
      setState(() => _busy = false);

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: AppColors.cardSolid),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih Perangkat Bluetooth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    devices.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Tidak ada perangkat ditemukan. Pastikan Bluetooth aktif.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: devices.length,
                            itemBuilder: (context, index) {
                              final dev = devices[index];
                              return ListTile(
                                leading: const Icon(Icons.print, color: AppColors.primaryEmerald),
                                title: Text(dev['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                subtitle: Text(dev['address'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _saveSettings(_printer.copyWith(deviceName: dev['name'], address: dev['address']));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Printer berhasil dihubungkan!'), backgroundColor: AppColors.primaryEmerald),
                                  );
                                },
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memindai: $e'), backgroundColor: AppColors.error));
    }
  }

  void _tampilkanDialogInputIP() {
    final TextEditingController ipController = TextEditingController(text: _printer.address ?? '192.168.1.200');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Konfigurasi Wi-Fi / LAN', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ipController,
            decoration: const InputDecoration(labelText: 'Alamat IP Printer', hintText: 'Contoh: 192.168.1.200', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald),
              onPressed: () {
                Navigator.pop(context);
                _saveSettings(_printer.copyWith(deviceName: 'Network Printer', address: ipController.text.trim()));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('IP Printer disimpan!'), backgroundColor: AppColors.primaryEmerald));
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _jalankanAksi(Future<void> Function() action, String pesanSukses) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesanSukses), backgroundColor: AppColors.primaryEmerald));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));
    }

    bool isPrinterSet = _printer.address != null && _printer.address!.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.7),
        elevation: 0,
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        title: const Text('Pengaturan Printer', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSettings)],
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]))),
          ListView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 24),
            children: [
              // 1. Cabang Aktif
              _buildCrystalCard(
                child: ListTile(
                  leading: const Icon(Icons.storefront, color: AppColors.smartBlue),
                  title: const Text('Cabang Aktif', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  subtitle: Text(widget.namaCabang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Status Printer Utama
              _buildCrystalCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.print, color: AppColors.smartBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Printer Struk Utama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(_printer.deviceName ?? 'Belum ada perangkat terhubung', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          if (isPrinterSet) Text(_printer.address!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPrinterSet ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(isPrinterSet ? 'Tersimpan' : 'Kosong', style: TextStyle(color: isPrinterSet ? Colors.green.shade700 : Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Jenis Koneksi
              const Text('Jenis Koneksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildKoneksiTab(PrinterConnectionType.bluetooth, Icons.bluetooth, 'Bluetooth')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildKoneksiTab(PrinterConnectionType.usb, Icons.usb, 'USB')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildKoneksiTab(PrinterConnectionType.wifi, Icons.wifi, 'Wi-Fi/LAN')),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyActive, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  onPressed: _busy ? null : _cariPerangkat, 
                  child: _busy 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_printer.connectionType == PrinterConnectionType.wifi ? 'Atur IP Printer' : 'Cari Perangkat Printer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Ukuran Kertas & Cetak Otomatis
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ukuran Kertas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        _buildCrystalCard(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Expanded(child: _buildKertasTab(58, '58 mm')),
                              Expanded(child: _buildKertasTab(80, '80 mm')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cetak Otomatis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        _buildCrystalCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Setelah Bayar', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Switch(
                                value: _printer.autoPrint,
                                activeColor: AppColors.primaryEmerald,
                                onChanged: (val) => _saveSettings(_printer.copyWith(autoPrint: val)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Aksi Printer
              const Text('Aksi Printer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildAksiButton(Icons.print_outlined, 'Cetak Tes', () => _jalankanAksi(() => _service.printTest(_printer), 'Struk uji berhasil dicetak!'))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAksiButton(Icons.receipt_outlined, 'Format Struk', () => Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanFormatStruk(storeId: widget.storeId))))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAksiButton(Icons.history, 'Riwayat', () => Navigator.push(context, MaterialPageRoute(builder: (_) => HalamanRiwayatCetak(storeId: widget.storeId, namaCabang: widget.namaCabang))))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrystalCard({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardSolid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildKoneksiTab(PrinterConnectionType type, IconData icon, String label) {
    bool isSelected = _printer.connectionType == type;
    return InkWell(
      onTap: () => _saveSettings(_printer.copyWith(connectionType: type, deviceName: null, address: null)),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.smartBlue.withOpacity(0.1) : AppColors.cardSolid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.smartBlue : AppColors.glassBorder, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.smartBlue : AppColors.textSecondary, size: 20),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.smartBlue : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildKertasTab(int width, String label) {
    bool isSelected = _printer.paperWidth == width;
    return InkWell(
      onTap: () => _saveSettings(_printer.copyWith(paperWidth: width)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryEmerald : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildAksiButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: _buildCrystalCard(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.navyActive, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
