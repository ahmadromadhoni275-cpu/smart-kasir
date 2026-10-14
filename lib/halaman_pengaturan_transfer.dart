import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/payment_method_service.dart';

class HalamanPengaturanTransfer extends StatefulWidget {
  final dynamic data;
  const HalamanPengaturanTransfer({super.key, this.data});

  @override
  State<HalamanPengaturanTransfer> createState() => _HalamanPengaturanTransferState();
}

class _HalamanPengaturanTransferState extends State<HalamanPengaturanTransfer> {
  final _bankNameCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _bankNameCtrl.text = widget.data['name'] ?? ''; // Disimpan sbg name di DB
      // Contoh split string detail: "123456789 a.n John Doe"
      // Untuk kemudahan, kita asumsikan tersimpan dalam JSON atau dipisah manual
      _accountNoCtrl.text = widget.data['account_number'] ?? ''; 
      _accountNameCtrl.text = widget.data['account_name'] ?? '';
      _isActive = widget.data['status'] == 'ACTIVE';
    }
  }

  void _simpan() async {
    setState(() => _isLoading = true);
    try {
      await PaymentMethodService.savePaymentMethod({
        'type': 'TRANSFER',
        'name': _bankNameCtrl.text,
        'account_number': _accountNoCtrl.text,
        'account_name': _accountNameCtrl.text,
        'details': '${_accountNoCtrl.text} a.n ${_accountNameCtrl.text}', // Kombinasi untuk ditampilkan di list
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
      appBar: AppBar(title: const Text('Rekening Transfer', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: AppColors.navyActive)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _bankNameCtrl,
                  decoration: InputDecoration(labelText: 'Nama Bank (Cth: BCA, Mandiri)', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _accountNoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Nomor Rekening', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _accountNameCtrl,
                  decoration: InputDecoration(labelText: 'Nama Pemilik Rekening', filled: true, fillColor: AppColors.lightGray, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Aktifkan Rekening Ini', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN REKENING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
