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
        const SnackBar(content: Text('Gagal menyimpan pengaturan')),
      );
    }
  }

  // --- LOGIKA MENCARI PERANGKAT BLUETOOTH / USB ---
  void _cariPerangkat() async {
    if (_printer.connectionType == PrinterConnectionType.wifi) {
      _tampilkanDialogInputIP();
      return;
    }
    
    if (_printer.connectionType == PrinterConnectionType.usb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur USB sedang dalam pengembangan. Gunakan Bluetooth/Wi-Fi.'), backgroundColor: Colors.orange),
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
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Perangkat Printer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                devices.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Tidak ada perangkat ditemukan. Pastikan Bluetooth aktif dan printer sudah dipairing.', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final dev = devices[index];
                          return ListTile(
                            leading: const Icon(Icons.print, color: Color(0xFF10B981)),
                            title: Text(dev['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(dev['address'] ?? '', style: const TextStyle(color: Colors.grey)),
                            onTap: () {
                              Navigator.pop(context);
                              _saveSettings(
                                _printer.copyWith(
                                  deviceName: dev['name'],
                                  address: dev['address'],
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Printer berhasil dipilih dan disimpan!'), backgroundColor: Color(0xFF10B981)),
                              );
                            },
                          );
                        },
                      ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memindai perangkat: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- LOGIKA INPUT IP UNTUK JARINGAN LAN/WIFI ---
  void _tampilkanDialogInputIP() {
    final TextEditingController ipController = TextEditingController(text: _printer.address ?? '192.168.1.200');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Konfigurasi Wi-Fi / LAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: TextField(
            controller: ipController,
            decoration: const InputDecoration(
              labelText: 'Alamat IP Printer',
              hintText: 'Contoh: 192.168.1.200',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                Navigator.pop(context);
                _saveSettings(
                  _printer.copyWith(
                    deviceName: 'Network Printer (LAN)',
                    address: ipController.text.trim(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('IP Printer berhasil disimpan!'), backgroundColor: Color(0xFF10B981)),
                );
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- LOGIKA MENJALANKAN AKSI (CETAK TES / PUTUS KONEKSI) ---
  Future<void> _jalankanAksi(Future<void> Function() action, String pesanSukses) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanSukses), backgroundColor: const Color(0xFF10B981)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    bool isPrinterSet = _printer.address != null && _printer.address!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pengaturan Printer', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Kelola perangkat cetak toko', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSettings(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- 1. CABANG AKTIF ---
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('CABANG AKTIF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.storefront, color: Colors.black54),
              ),
              title: const Text('Cabang yang dipilih', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(widget.namaCabang, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              onTap: () {
                // Logika pindah cabang jika diperlukan dari halaman ini (bisa diarahkan ke HalamanPilihCabang)
              },
            ),
          ),
          const SizedBox(height: 16),

          // --- 2. KARTU PRINTER UTAMA ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.print, color: Colors.black87),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Printer struk utama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        _printer.deviceName ?? 'Belum ada perangkat terhubung',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (isPrinterSet) ...[
                        const SizedBox(height: 2),
                        Text(_printer.address!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ]
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPrinterSet ? Colors.green.shade50 : const Color(0xFFFFF7E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPrinterSet ? 'Tersimpan' : 'Kosong',
                    style: TextStyle(
                      color: isPrinterSet ? Colors.green.shade700 : const Color(0xFFD97706),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 3. JENIS KONEKSI & CARI PERANGKAT ---
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Jenis koneksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A), // Navy
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _busy ? null : _cariPerangkat, 
              child: _busy 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _printer.connectionType == PrinterConnectionType.wifi ? 'Atur IP Printer' : 'Cari Perangkat Printer', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                  ),
            ),
          ),
          const SizedBox(height: 20),

          // --- 4. UKURAN KERTAS & CETAK OTOMATIS ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.receipt_long, size: 18, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('Ukuran Kertas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
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
                    const Row(
                      children: [
                        Icon(Icons.settings_suggest_outlined, size: 18, color: Colors.grey),
                        SizedBox(width: 6),
                        Text('Cetak Otomatis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Setelah\npembayaran', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.2)),
                          Switch(
                            value: _printer.autoPrint,
                            activeColor: const Color(0xFF10B981), // Emerald
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

          // --- 5. AKSI PRINTER ---
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Aksi Printer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          Row(
            children: [
              Expanded(
                child: _buildAksiButton(
                  Icons.print_outlined, 
                  'Cetak Tes', 
                  () => _jalankanAksi(() => _service.printTest(_printer), 'Struk uji berhasil dicetak!')
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAksiButton(
                  Icons.receipt_outlined, 
                  'Format Struk', 
                  () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HalamanFormatStruk()));
                  }
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAksiButton(
                  Icons.history, 
                  'Riwayat', 
                  () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => HalamanRiwayatCetak(storeId: widget.storeId)
                      )
                    );
                  }
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildKoneksiTab(PrinterConnectionType type, IconData icon, String label) {
    bool isSelected = _printer.connectionType == type;
    return InkWell(
      onTap: () {
        // Jika ganti koneksi, reset nama & address printer lama
        _saveSettings(_printer.copyWith(connectionType: type, deviceName: null, address: null));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent, // Gold
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildKertasTab(int width, String label) {
    bool isSelected = _printer.paperWidth == width;
    return InkWell(
      onTap: () => _saveSettings(_printer.copyWith(paperWidth: width)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryEmerald : Colors.transparent, // Sesuaikan warna jika error
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryEmerald : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildAksiButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
