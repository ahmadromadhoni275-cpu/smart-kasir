import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Package PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'core/services/transaction_service.dart';
import 'core/services/printer_service.dart'; // Import Printer Service Baru
import 'tema.dart';

class HalamanDetailTransaksi extends StatefulWidget {
  final int transactionId;
  final String invoiceNumber;

  const HalamanDetailTransaksi({
    super.key,
    required this.transactionId,
    required this.invoiceNumber,
  });

  @override
  State<HalamanDetailTransaksi> createState() => _HalamanDetailTransaksiState();
}

class _HalamanDetailTransaksiState extends State<HalamanDetailTransaksi> {
  final TransactionService _service = TransactionService();
  bool _isLoading = true;
  Map<String, dynamic>? _detail;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _service.getTransactionDetail(widget.transactionId);
      setState(() {
        _detail = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    double val = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(val);
  }

  // ==========================================
  // FITUR 1: CETAK ULANG (Menggunakan PrinterService Terpusat)
  // ==========================================
  Future<void> _cetakUlangStruk() async {
    if (_detail == null) return;
    
    _showNotif('Mencetak ulang struk...', AppColors.smartBlue);
    try {
      // PrinterService akan otomatis mengecek cabang aktif, 
      // ukuran kertas, dan koneksi (Bluetooth/Wifi)
      await PrinterService().cetakStruk(_detail!); 
    } catch (e) {
      _showNotif(e.toString().replaceAll('Exception: ', ''), Colors.red);
    }
  }

  // ==========================================
  // FITUR 2: SIMPAN PDF & BAGIKAN (Mendukung Split Payment)
  // ==========================================
  Future<void> _bagikanPDF() async {
    if (_detail == null) return;
    _showNotif('Membuat PDF...', AppColors.primaryEmerald);

    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, 
        build: (pw.Context context) {
          List payments = _detail!['payments'] ?? [];
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('SMART KASIR', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(_detail!['store_name'] ?? 'Toko Anda', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text('** SALINAN STRUK **', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('No:'), pw.Text(widget.invoiceNumber)]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Tgl:'), pw.Text(_detail!['created_at'])]),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              ...(_detail!['items'] as List).map((item) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item['product_name'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${item['qty']} x ${_formatCurrency(item['price'])}'),
                        pw.Text(_formatCurrency(item['total'])),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ]
                );
              }).toList(),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL TAGIHAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(_formatCurrency(_detail!['grand_total']), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ]
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              // RINCIAN PEMBAYARAN PDF
              ...payments.map((p) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text('BAYAR (${p['method']})'), pw.Text(_formatCurrency(p['amount']))]
              )).toList(),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text('Terima Kasih', style: const pw.TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Struk_Copy_${widget.invoiceNumber}.pdf',
    );
  }

  void _showNotif(String pesan, Color warna) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(pesan, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: warna,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B), 
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _buildReceiptUI(),
      
      bottomNavigationBar: _isLoading || _detail == null ? null : _buildActionButtons(),
    );
  }

  Widget _buildReceiptUI() {
    List items = _detail!['items'] ?? [];
    List payments = _detail!['payments'] ?? [];
    bool isCompleted = _detail!['transaction_status'] == 'COMPLETED';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, size: 48, color: AppColors.primaryEmerald),
                      const SizedBox(height: 8),
                      Text(widget.invoiceNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(_detail!['created_at'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCompleted ? 'BERHASIL' : 'DIBATALKAN',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green.shade700 : Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(thickness: 2),
                ),
                
                const Text('Daftar Pembelian', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${item['qty']} x ${_formatCurrency(item['price'])}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(_formatCurrency(item['total']), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
                
                const Divider(height: 32),
                
                _buildSummaryRow('Subtotal', _formatCurrency(_detail!['sub_total'])),
                _buildSummaryRow('Diskon', '- ${_formatCurrency(_detail!['discount_total'])}', isDiscount: true),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL TAGIHAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                    Text(_formatCurrency(_detail!['grand_total']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryEmerald)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                const Text('Riwayat Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: payments.map<Widget>((pay) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: AppColors.primaryEmerald),
                              const SizedBox(width: 8),
                              Text(pay['method'], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                            ],
                          ),
                          Text(_formatCurrency(pay['amount']), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                    )).toList(),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: isDiscount ? Colors.red : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _bagikanPDF,
                icon: const Icon(Icons.share, color: Color(0xFF1E293B)),
                label: const Text('Bagikan / PDF', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF1E293B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                // Memanggil logika router printer yang baru
                onPressed: _cetakUlangStruk,
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text('Cetak Ulang Struk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryEmerald,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
