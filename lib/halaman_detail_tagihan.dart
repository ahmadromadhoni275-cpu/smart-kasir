import 'package:flutter/material.dart';
import 'halaman_pembayaran_langganan.dart';

class HalamanDetailTagihan extends StatelessWidget {
  final Map<String, dynamic> dataTagihan;

  const HalamanDetailTagihan({Key? key, required this.dataTagihan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color navy = const Color(0xFF0F172A);
    final String status = dataTagihan['status'] ?? 'PENDING';
    
    // UBAH: Cek upload bukti menggunakan status 'FAILED' (bukan REJECTED)
    final bool canUploadProof = status == 'PENDING' || status == 'FAILED';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: navy),
        title: Text('Detail Tagihan', style: TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UBAH: Menggunakan 'FAILED'
            if (status == 'FAILED')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pembayaran Ditolak', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    // UBAH: Menggunakan 'notes' (sebelumnya rejection_reason)
                    Text(dataTagihan['notes'] ?? 'Bukti pembayaran tidak valid atau kurang jelas. Silakan unggah ulang.', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  _buildRow('Nomor Tagihan', dataTagihan['invoice_number'] ?? '-'),
                  const Divider(height: 24),
                  _buildRow('Paket', dataTagihan['plan_name'] ?? '-'),
                  const Divider(height: 24),
                  _buildRow('Total', 'Rp${dataTagihan['amount']}', isBold: true),
                  const Divider(height: 24),
                  _buildRow('Status', _getStatusText(status), valueColor: _getStatusColor(status), isBold: true),
                  const Divider(height: 24),
                  _buildRow('Jatuh Tempo', dataTagihan['payment_expires_at'] ?? '-'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            if (canUploadProof)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => HalamanPembayaranLangganan(
                        // UBAH: Menggunakan 'payment_id' (sebelumnya subscription_payment_id)
                        paymentId: dataTagihan['payment_id'].toString(),
                        invoiceNumber: dataTagihan['invoice_number'],
                        planName: dataTagihan['plan_name'],
                        amount: 'Rp${dataTagihan['amount']}',
                      )
                    )).then((isSuccess) {
                      if (isSuccess == true) {
                        Navigator.pop(context, true); // Kembali ke riwayat agar merefresh data
                      }
                    });
                  },
                  // UBAH: Teks tombol jika status FAILED
                  child: Text(status == 'FAILED' ? 'Unggah Ulang Bukti' : 'Konfirmasi & Unggah Bukti', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor ?? Colors.black87)),
      ],
    );
  }

  // UBAH: Menyesuaikan warna berdasarkan status database
  Color _getStatusColor(String status) {
    switch (status) {
      case 'SUCCESS': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'FAILED': return Colors.red;
      default: return Colors.blue; 
    }
  }

  // TAMBAHAN: Fungsi helper agar teks status lebih rapi
  String _getStatusText(String status) {
    switch (status) {
      case 'SUCCESS': return 'Lunas & Aktif';
      case 'FAILED': return 'Ditolak';
      case 'PENDING': return 'Menunggu Verifikasi';
      default: return status;
    }
  }
}
