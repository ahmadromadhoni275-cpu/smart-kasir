import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Package PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'core/services/transaction_service.dart';
import 'core/services/printer_service.dart'; 
import 'models/transaction_detail_model.dart';
import 'tema.dart';

// Import halaman form retur
import 'halaman_form_retur.dart';

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
  TransactionDetailModel? _detailData; 

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _service.getTransactionDetail(widget.transactionId);
      setState(() {
        _detailData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tampilPopupCantik('Gagal Memuat', e.toString().replaceAll('Exception: ', ''), Icons.error_outline, AppColors.error);
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    double val = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(val);
  }

  void _tampilPopupCantik(String judul, String pesan, IconData ikon, Color warna) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16), 
                decoration: BoxDecoration(color: warna.withOpacity(0.1), shape: BoxShape.circle), 
                child: Icon(ikon, color: warna, size: 48)
              ),
              const SizedBox(height: 20),
              Text(judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
              const SizedBox(height: 12),
              Text(pesan, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: warna, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cetakUlangStruk() async {
    if (_detailData == null) return;
    
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald)));

    try {
      final receipt = _detailData!.receipt;
      
      final dataCetak = {
        'store_name': receipt.store.name,
        'store_address': receipt.store.address ?? '',
        'store_phone': receipt.store.phone ?? '',
        'invoice_number': receipt.invoiceNumber,
        'created_at': receipt.createdAt,
        'cashier_name': receipt.cashierName,
        'items': receipt.items.map((i) => {
          'name': i.name,
          'order_type': i.orderType,
          'note': i.note,
          'price': i.price,
          'quantity': i.quantity,
        }).toList(),
        'sub_total': receipt.subtotal,
        'discount': receipt.discount,
        'grand_total': receipt.grandTotal,
        'payments': receipt.payments.map((p) => {
          'method': p.method,
          'amount': p.amount,
        }).toList()
      };

      await PrinterService().cetakStruk(dataCetak); 
      
      Navigator.pop(context); 
      _tampilPopupCantik('Cetak Berhasil', 'Struk berhasil dikirim ke printer bluetooth Anda.', Icons.print, AppColors.primaryEmerald);
      
    } catch (e) {
      Navigator.pop(context); 
      _tampilPopupCantik('Gagal Mencetak', e.toString().replaceAll('Exception: ', ''), Icons.print_disabled, AppColors.error);
    }
  }

  Future<void> _bagikanPDF() async {
    if (_detailData == null) return;
    
    final receipt = _detailData!.receipt;
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, 
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(receipt.store.name.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              if (receipt.store.address != null) pw.Text(receipt.store.address!, style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text('** SALINAN STRUK **', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('No:'), pw.Text(receipt.invoiceNumber)]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Tgl:'), pw.Text(receipt.createdAt)]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Ksr:'), pw.Text(receipt.cashierName)]),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              
              ...receipt.items.map((item) {
                String labelName = item.name;
                if (item.orderType == 'TAKEAWAY') labelName += ' (Takeaway)';

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(labelName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    if (item.note != null && item.note!.isNotEmpty)
                      pw.Text('* ${item.note}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('${item.quantity} x ${_formatCurrency(item.price)}'),
                        pw.Text(_formatCurrency(item.price * item.quantity)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                  ]
                );
              }).toList(),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              
              if (receipt.discount > 0)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Subtotal'), pw.Text(_formatCurrency(receipt.subtotal))]),
              if (receipt.discount > 0)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Diskon'), pw.Text('- ${_formatCurrency(receipt.discount)}')]),
                
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL TAGIHAN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(_formatCurrency(receipt.grandTotal), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ]
              ),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              
              ...receipt.payments.map((p) => pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text('BAYAR (${p.method})'), pw.Text(_formatCurrency(p.amount))]
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
      filename: 'Struk_${widget.invoiceNumber}.pdf',
    );
  }

  void _konfirmasiBatal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Transaksi?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
        content: const Text('Tindakan ini akan membatalkan KESELURUHAN transaksi, mengembalikan semua stok barang dan mencatat uang keluar (Refund). Anda yakin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              _prosesBatal();
            }, 
            child: const Text('Ya, Batalkan Semua', style: TextStyle(color: Colors.white))
          )
        ],
      )
    );
  }

  Future<void> _prosesBatal() async {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.error)));
    try {
      await _service.cancelTransaction(widget.transactionId);
      Navigator.pop(context);
      _tampilPopupCantik('Berhasil Dibatalkan', 'Seluruh transaksi telah dibatalkan dan stok dikembalikan.', Icons.check_circle, AppColors.primaryEmerald);
      _fetchDetail(); 
    } catch (e) {
      Navigator.pop(context);
      _tampilPopupCantik('Gagal Membatalkan', 'Terjadi kesalahan sistem.', Icons.error, AppColors.error);
    }
  }

  // FUNGSI BARU: Buka Form Retur (Sebagian barang)
  void _navigasiKeFormRetur() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HalamanFormRetur(
          transactionId: widget.transactionId,
          invoiceNumber: widget.invoiceNumber,
        ),
      ),
    );

    // Jika retur berhasil, fetch ulang data detail
    if (result == true) {
      _fetchDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Transaksi', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, 
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _detailData == null
              ? const Center(child: Text('Data tidak tersedia.', style: TextStyle(color: AppColors.textSecondary)))
              : _buildReceiptUI(),
      
      bottomNavigationBar: _isLoading || _detailData == null ? null : _buildActionButtons(),
    );
  }

  Widget _buildReceiptUI() {
    final receipt = _detailData!.receipt;
    bool isCompleted = receipt.transactionStatus == 'COMPLETED';

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
                      Icon(isCompleted ? Icons.check_circle : Icons.cancel, size: 48, color: isCompleted ? AppColors.primaryEmerald : AppColors.error),
                      const SizedBox(height: 8),
                      Text(widget.invoiceNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                      const SizedBox(height: 4),
                      Text(receipt.createdAt, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted ? AppColors.primaryEmerald.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isCompleted ? 'BERHASIL' : 'DIBATALKAN',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isCompleted ? AppColors.primaryEmerald : AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(thickness: 1, color: AppColors.border),
                ),
                
                const Text('Daftar Pembelian', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                const SizedBox(height: 12),
                
                ...receipt.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navyActive)),
                            if (item.orderType == 'TAKEAWAY')
                               Container(
                                 margin: const EdgeInsets.only(top: 2, bottom: 2),
                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                 decoration: BoxDecoration(color: AppColors.smartBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                 child: const Text('Takeaway', style: TextStyle(fontSize: 9, color: AppColors.smartBlue, fontWeight: FontWeight.bold))
                               ),
                            const SizedBox(height: 2),
                            Text('${item.quantity} x ${_formatCurrency(item.price)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(_formatCurrency(item.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    ],
                  ),
                )),
                
                const Divider(height: 32, color: AppColors.border),
                
                if (receipt.discount > 0)
                  _buildSummaryRow('Subtotal', _formatCurrency(receipt.subtotal)),
                
                if (receipt.discount > 0)
                  _buildSummaryRow('Diskon', '- ${_formatCurrency(receipt.discount)}', isDiscount: true),
                  
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL TAGIHAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                      Text(_formatCurrency(receipt.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryEmerald)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text('Riwayat Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                const SizedBox(height: 12),
                
                ...receipt.payments.map<Widget>((pay) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: AppColors.primaryEmerald),
                          const SizedBox(width: 8),
                          Text(pay.method, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navyActive)),
                        ],
                      ),
                      Text(_formatCurrency(pay.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    ],
                  ),
                )),
                
                // TOMBOL BATAL & RETUR MUNCUL JIKA STATUS COMPLETED
                if (isCompleted) ...[
                  const Divider(height: 32, color: AppColors.border),
                  
                  // Tombol Retur Barang Sebagian
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _navigasiKeFormRetur, 
                      icon: const Icon(Icons.assignment_return_outlined, color: AppColors.warning, size: 20), 
                      label: const Text('Ajukan Retur Barang', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.warning),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Tombol Batal Seluruh Transaksi
                  Center(
                    child: TextButton.icon(
                      onPressed: _konfirmasiBatal, 
                      icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18), 
                      label: const Text('Batalkan Seluruh Transaksi', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))
                    ),
                  )
                ]
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: isDiscount ? AppColors.error : AppColors.navyActive)),
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
                icon: const Icon(Icons.share, color: AppColors.navyActive),
                label: const Text('PDF', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _cetakUlangStruk,
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text('Cetak Struk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
