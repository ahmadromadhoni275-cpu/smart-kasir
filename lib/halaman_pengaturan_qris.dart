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
  final PaymentMethodService _service = PaymentMethodService();
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
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _service.savePaymentMethod({
        'method': 'QRIS', // Sesuai kolom database
        'name': _nameCtrl.text.trim(),
        'status': _isActive ? 'ACTIVE' : 'INACTIVE',
      }, id: widget.data != null ? int.parse(widget.data['payment_method_id'].toString()) : null);
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
      appBar: AppBar(title: const Text('Pengaturan QRIS', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: AppColors.navyActive), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 200, width: 200,
                    decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border, style: BorderStyle.solid)),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Ketuk untuk unggah QRIS\n(Segera Hadir)', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Nama Tampilan Kasir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: const Text('Aktifkan Pembayaran Ini', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 14)),
                    value: _isActive,
                    activeColor: AppColors.primaryEmerald,
                    onChanged: (val) => setState(() => _isActive = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    onPressed: _isLoading ? null : _simpan,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN PENGATURAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
