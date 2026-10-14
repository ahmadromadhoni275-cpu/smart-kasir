import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/payment_method_service.dart';

class HalamanPengaturanQris extends StatefulWidget {
  final dynamic data;
  const HalamanPengaturanQris({super.key, this.data});

  @override
  State<HalamanPengaturanQris> createState() => _HalamanPengaturanQrisState();
}

class _HalamanPengaturanQrisState extends State<HalamanPengaturanQris> {
  final _nameCtrl = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _nameCtrl.text = widget.data['name'] ?? '';
      _isActive = widget.data['status'] == 'ACTIVE';
    } else {
      _nameCtrl.text = 'QRIS Toko';
    }
  }

  void _simpan() async {
    setState(() => _isLoading = true);
    try {
      await PaymentMethodService.savePaymentMethod({
        'type': 'QRIS',
        'name': _nameCtrl.text,
        'details': 'QRIS Statis',
        'status': _isActive ? 'ACTIVE' : 'INACTIVE',
      }, id: widget.data?['id']);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pengaturan QRIS', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: AppColors.navyActive)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                // Ilustrasi Upload QR (UI saja untuk versi awal)
                Container(
                  height: 200, width: 200,
                  decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Ketuk untuk unggah QRIS', style: TextStyle(color: Colors.grey, fontSize: 12))
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(labelText: 'Nama Tampilan Kasir', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Aktifkan Metode Ini', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _isActive,
                  activeColor: AppColors.primaryEmerald,
                  onChanged: (val) => setState(() => _isActive = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isLoading ? null : _simpan,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN QRIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
