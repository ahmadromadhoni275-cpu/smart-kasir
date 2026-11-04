import 'package:flutter/material.dart';
import 'tema.dart';
import 'core/services/payment_method_service.dart';

class HalamanPengaturanEwallet extends StatefulWidget {
  final dynamic data;
  const HalamanPengaturanEwallet({super.key, this.data});

  @override
  State<HalamanPengaturanEwallet> createState() => _HalamanPengaturanEwalletState();
}

class _HalamanPengaturanEwalletState extends State<HalamanPengaturanEwallet> {
  final PaymentMethodService _service = PaymentMethodService();
  String _ewalletName = 'GoPay';
  final _accountNoCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;

  final List<String> _providerList = ['GoPay', 'OVO', 'DANA', 'ShopeePay', 'LinkAja'];

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _ewalletName = widget.data['name'] ?? 'GoPay';
      if (!_providerList.contains(_ewalletName)) _ewalletName = 'GoPay';
      _accountNoCtrl.text = widget.data['account_number'] ?? ''; 
      _accountNameCtrl.text = widget.data['account_name'] ?? '';
      _isActive = widget.data['status'] == 'ACTIVE';
    }
  }

  void _simpan() async {
    if (_accountNoCtrl.text.isEmpty || _accountNameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _service.savePaymentMethod({
        'method': 'EWALLET',
        'name': _ewalletName,
        'account_number': _accountNoCtrl.text.trim(),
        'account_name': _accountNameCtrl.text.trim(),
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
      appBar: AppBar(title: const Text('Akun E-Wallet', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, iconTheme: const IconThemeData(color: AppColors.navyActive), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Layanan E-Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _ewalletName,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.navyActive),
                  decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))),
                  items: _providerList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (val) => setState(() => _ewalletName = val!),
                ),
                const SizedBox(height: 16),
                const Text('Nomor HP / Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _accountNoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))),
                ),
                const SizedBox(height: 16),
                const Text('Nama Pemilik Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _accountNameCtrl,
                  decoration: InputDecoration(filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border))),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    title: const Text('Aktifkan E-Wallet Ini', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive, fontSize: 14)),
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
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SIMPAN E-WALLET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
