import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'tema.dart'; // Pastikan AppColors tersedia
import 'models/printer_job_model.dart';
import 'core/services/print_job_service.dart';

class HalamanRiwayatCetak extends StatefulWidget {
  final String storeId;
  final String namaCabang;

  const HalamanRiwayatCetak({
    super.key,
    required this.storeId,
    this.namaCabang = 'Toko Utama',
  });

  @override
  State<HalamanRiwayatCetak> createState() => _HalamanRiwayatCetakState();
}

class _HalamanRiwayatCetakState extends State<HalamanRiwayatCetak> {
  final PrintJobService _service = PrintJobService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  String _filterStatus = 'SEMUA';
  String _searchQuery = '';

  List<PrinterJobModel> _riwayat = [];
  int _totalJobs = 0;
  int _failedJobs = 0;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() => _isLoading = true);
    try {
      // Panggil API secara paralel (List Data & Ringkasan Angka)
      final results = await Future.wait([
        _service.getPrintJobs(
          storeId: widget.storeId, 
          statusFilter: _filterStatus, 
          searchQuery: _searchQuery
        ),
        _service.getPrintSummary(widget.storeId),
      ]);

      if (!mounted) return;
      setState(() {
        _riwayat = results[0] as List<PrinterJobModel>;
        final summary = results[1] as Map<String, int>;
        _totalJobs = summary['total'] ?? 0;
        _failedJobs = summary['failed'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      _muatData();
    });
  }

  void _ubahFilter(String status) {
    setState(() => _filterStatus = status);
    _muatData();
  }

  Future<void> _cobaCetakUlang(String jobId) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      await _service.retryPrintJob(jobId);
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pekerjaan cetak masuk antrean!'), backgroundColor: AppColors.primaryEmerald));
      _muatData(); // Refresh data
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Cetak', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Pantau aktivitas dan status pencetakan', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _muatData),
        ],
      ),
      body: Column(
        children: [
          // Header (Cabang & Summary)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CABANG AKTIF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.storefront, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(widget.namaCabang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Total pekerjaan', _totalJobs.toString(), Colors.blue.shade50, Colors.blue.shade700)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSummaryCard('Gagal cetak', _failedJobs.toString(), Colors.red.shade50, Colors.red.shade700)),
                  ],
                ),
              ],
            ),
          ),
          
          // Pencarian & Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari invoice, printer, atau ID...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua', 'SEMUA'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Berhasil', 'SENT'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Gagal', 'FAILED'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Diproses', 'PRINTING'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Antrean', 'QUEUED'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.shade200),

          // ListView Data
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                : _riwayat.isEmpty
                    ? _buildKosong()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _riwayat.length,
                        itemBuilder: (context, index) {
                          return _buildKartuRiwayat(_riwayat[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8))),
          const SizedBox(height: 4),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filterStatus == value;
    return InkWell(
      onTap: () => _ubahFilter(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildKartuRiwayat(PrinterJobModel data) {
    Color statusBgColor;
    Color statusTextColor;
    String statusTeks;

    switch (data.status) {
      case 'SENT':
        statusBgColor = Colors.green.shade50;
        statusTextColor = Colors.green.shade700;
        statusTeks = 'Terkirim';
        break;
      case 'FAILED':
        statusBgColor = Colors.red.shade50;
        statusTextColor = Colors.red.shade700;
        statusTeks = 'Gagal';
        break;
      case 'PRINTING':
      case 'QUEUED':
        statusBgColor = Colors.blue.shade50;
        statusTextColor = Colors.blue.shade700;
        statusTeks = data.status == 'QUEUED' ? 'Antrean' : 'Diproses';
        break;
      default:
        statusBgColor = Colors.grey.shade100;
        statusTextColor = Colors.grey.shade700;
        statusTeks = 'Tidak Diketahui';
    }

    String formatWaktu = DateFormat('dd MMM yyyy, HH.mm').format(data.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(statusTeks, style: TextStyle(color: statusTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text('${data.documentType} · ${data.connectionType}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(formatWaktu, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          
          if (data.errorMessage != null && data.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data.errorMessage!, style: TextStyle(fontSize: 11, color: Colors.red.shade700))),
                ],
              ),
            ),
          ],
          
          if (data.status == 'FAILED') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () => _cobaCetakUlang(data.id),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Coba Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildKosong() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Tidak ada pekerjaan cetak', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Ubah filter atau lakukan pencarian lain.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
