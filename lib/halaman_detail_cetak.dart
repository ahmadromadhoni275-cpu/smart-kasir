import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'tema.dart'; 
import 'models/printer_job_model.dart';
import 'core/services/print_job_service.dart';

class HalamanDetailCetak extends StatefulWidget {
  final PrinterJobModel printJob;

  const HalamanDetailCetak({super.key, required this.printJob});

  @override
  State<HalamanDetailCetak> createState() => _HalamanDetailCetakState();
}

class _HalamanDetailCetakState extends State<HalamanDetailCetak> {
  final PrintJobService _service = PrintJobService();
  bool _isRetrying = false;
  late PrinterJobModel _currentJob;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.printJob;
  }

  void _salinKeClipboard(String teks, String label) {
    Clipboard.setData(ClipboardData(text: teks));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label berhasil disalin!'), backgroundColor: AppColors.primaryEmerald),
    );
  }

  Future<void> _cobaCetakUlang() async {
    setState(() => _isRetrying = true);
    try {
      await _service.retryPrintJob(_currentJob.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perintah cetak ulang berhasil dikirim ke antrean.'), backgroundColor: AppColors.primaryEmerald),
      );
      // Idealnya di sini kita fetch ulang data detail dari API, 
      // namun untuk sementara kita tutup halaman ini agar kembali ke Riwayat.
      Navigator.pop(context, true); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatWaktu = DateFormat('dd MMMM yyyy, HH.mm').format(_currentJob.createdAt);
    
    Color statusBgColor;
    Color statusTextColor;
    String statusTeks;
    IconData statusIcon;

    switch (_currentJob.status) {
      case 'SENT':
        statusBgColor = Colors.green.shade50;
        statusTextColor = Colors.green.shade700;
        statusTeks = 'Terkirim / Berhasil';
        statusIcon = Icons.check_circle;
        break;
      case 'FAILED':
        statusBgColor = Colors.red.shade50;
        statusTextColor = Colors.red.shade700;
        statusTeks = 'Gagal Dicetak';
        statusIcon = Icons.cancel;
        break;
      case 'PRINTING':
      case 'QUEUED':
        statusBgColor = Colors.blue.shade50;
        statusTextColor = Colors.blue.shade700;
        statusTeks = _currentJob.status == 'QUEUED' ? 'Masuk Antrean' : 'Sedang Diproses';
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusBgColor = Colors.grey.shade100;
        statusTextColor = Colors.grey.shade700;
        statusTeks = 'Status Tidak Diketahui';
        statusIcon = Icons.help_outline;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detail Pekerjaan Cetak', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KARTU STATUS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(statusIcon, size: 48, color: statusTextColor),
                  const SizedBox(height: 12),
                  Text(statusTeks, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusTextColor)),
                  const SizedBox(height: 4),
                  Text('Waktu permintaan: $formatWaktu', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  
                  if (_currentJob.errorMessage != null && _currentJob.errorMessage!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pesan Kesalahan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                                const SizedBox(height: 2),
                                Text(_currentJob.errorMessage!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('INFORMASI DOKUMEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 8),
            
            // KARTU INFORMASI
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildListTile('ID Pekerjaan', _currentJob.id, onCopy: () => _salinKeClipboard(_currentJob.id, 'ID Pekerjaan')),
                  const Divider(height: 1),
                  _buildListTile('Nomor Referensi', _currentJob.invoiceNumber, onCopy: () => _salinKeClipboard(_currentJob.invoiceNumber, 'Nomor Referensi')),
                  const Divider(height: 1),
                  _buildListTile('Jenis Dokumen', _currentJob.documentType),
                  const Divider(height: 1),
                  _buildListTile('Perangkat Printer', _currentJob.printerName),
                  const Divider(height: 1),
                  _buildListTile('Metode Koneksi', _currentJob.connectionType),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // TOMBOL AKSI
            if (_currentJob.status == 'FAILED')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isRetrying ? null : _cobaCetakUlang,
                  icon: _isRetrying 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(_isRetrying ? 'Mencoba...' : 'Coba Cetak Lagi', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyActive,
                  side: const BorderSide(color: AppColors.navyActive),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // TODO: Navigasi ke Halaman Detail Transaksi jika diperlukan
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menuju detail transaksi...')));
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text('Lihat Transaksi Terkait', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle, {VoidCallback? onCopy}) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      trailing: onCopy != null 
          ? IconButton(
              icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
              onPressed: onCopy,
              tooltip: 'Salin',
            )
          : null,
    );
  }
}
