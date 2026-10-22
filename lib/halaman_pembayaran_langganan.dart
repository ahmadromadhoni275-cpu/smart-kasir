import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HalamanPembayaranLangganan extends StatefulWidget {
  final String paymentId;
  final String invoiceNumber;
  final String planName;
  final String amount;

  const HalamanPembayaranLangganan({
    Key? key,
    required this.paymentId,
    required this.invoiceNumber,
    required this.planName,
    required this.amount,
  }) : super(key: key);

  @override
  _HalamanPembayaranLanggananState createState() => _HalamanPembayaranLanggananState();
}

class _HalamanPembayaranLanggananState extends State<HalamanPembayaranLangganan> {
  final Color navy = const Color(0xFF0F172A);
  final Color gold = const Color(0xFFD4AF37);
  final String baseUrl = 'https://smartkasir.shop/api';

  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Kompresi awal
    );

    if (pickedFile != null) {
      final File file = File(pickedFile.path);
      // Validasi ukuran di sisi klien (Opsional, max 5MB)
      int sizeInBytes = await file.length();
      if (sizeInBytes > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran file maksimal 5 MB.'), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() => _imageFile = file);
    }
  }

  Future<void> _uploadProof() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final storeId = prefs.getInt('store_id')?.toString() ?? '';

      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('$baseUrl/subscriptions/payments/${widget.paymentId}/proof')
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'X-Store-Id': storeId,
      });

      request.files.add(await http.MultipartFile.fromPath(
        'proof_image',
        _imageFile!.path,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _isUploading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti berhasil diunggah. Menunggu verifikasi.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Kembali ke halaman sebelumnya dan beri tanda sukses
      } else {
        final resData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resData['message'] ?? 'Gagal mengunggah bukti.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: navy),
        title: Text('Pembayaran langganan', style: TextStyle(color: navy, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.planName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: navy)), // e.g. Smart Kasir Pro[span_2](start_span)[span_2](end_span)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Text('Menunggu pembayaran', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KARTU RINCIAN TAGIHAN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildDetailRow('Nomor tagihan', widget.invoiceNumber, isBold: true), // e.g. INV-SUB-000123[span_3](start_span)[span_3](end_span)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                  _buildDetailRow('Paket', '${widget.planName} — 1 bulan'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Total tagihan', widget.amount, isBold: true, valueColor: navy), // e.g. Rp99.000[span_4](start_span)[span_4](end_span)
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 24),
              child: Text('Data ilustrasi. Nilai aktual harus berasal dari API tagihan.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            // INSTRUKSI PEMBAYARAN
            const Text('Instruksi pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('1. Transfer sesuai nominal tagihan ke rekening atau QRIS resmi platform.\n2. Pastikan transaksi berhasil.\n3. Unggah bukti pembayaran yang jelas.', style: TextStyle(height: 1.6, color: Colors.black87)), //[span_5](start_span)[span_5](end_span)
            const SizedBox(height: 24),

            // PEMILIH GAMBAR BUKTI PEMBAYARAN
            const Text('Bukti pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Format JPG, PNG, atau WebP. Maksimal 5 MB sebagai contoh kebijakan.', style: TextStyle(fontSize: 12, color: Colors.grey)), //[span_6](start_span)[span_6](end_span)
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.download_rounded, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          const Text('Belum ada bukti dipilih', style: TextStyle(color: Colors.grey)), //[span_7](start_span)[span_7](end_span)
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 32),

            // TOMBOL UPLOAD
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _imageFile == null ? Colors.grey : navy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _imageFile == null || _isUploading ? null : _uploadProof,
                child: _isUploading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kirim Bukti Pembayaran', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value, 
          style: TextStyle(
            fontSize: isBold ? 16 : 14, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal, 
            color: valueColor ?? Colors.black87
          )
        ),
      ],
    );
  }
}
