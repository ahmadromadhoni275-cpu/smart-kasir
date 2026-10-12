import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/transaction_service.dart';
import 'models/transaction_model.dart'; // <-- Sesuaikan jika model Anda ada di tempat lain
import 'tema.dart';
import 'halaman_detail_transaksi.dart';

class HalamanRiwayatTransaksi extends StatefulWidget {
  const HalamanRiwayatTransaksi({super.key});

  @override
  State<HalamanRiwayatTransaksi> createState() => _HalamanRiwayatTransaksiState();
}

class _HalamanRiwayatTransaksiState extends State<HalamanRiwayatTransaksi> {
  final TransactionService _service = TransactionService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<TransactionReport> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Filter Tanggal
  String _selectedFilterDate = 'Hari Ini';
  late DateTime _dateFrom;
  late DateTime _dateTo;

  // Pagination (Opsional, untuk menangani data yang banyak)
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _setFilterDate('Hari Ini'); // Default mengambil transaksi hari ini
  }

  void _setFilterDate(String filterType) {
    DateTime now = DateTime.now();
    setState(() {
      _selectedFilterDate = filterType;
      _currentPage = 1; // Reset ke halaman pertama jika filter berubah
      
      if (filterType == 'Hari Ini') {
        _dateFrom = now;
        _dateTo = now;
      } else if (filterType == '7 Hari Terakhir') {
        _dateFrom = now.subtract(const Duration(days: 7));
        _dateTo = now;
      } else if (filterType == 'Bulan Ini') {
        _dateFrom = DateTime(now.year, now.month, 1);
        _dateTo = DateTime(now.year, now.month + 1, 0); // Hari terakhir bulan ini
      }
    });
    _fetchTransactions();
  }

  Future<void> _fetchTransactions({bool loadMore = false}) async {
    if (loadMore) {
      if (_currentPage >= _totalPages) return; // Sudah di halaman terakhir
      setState(() => _isLoadingMore = true);
      _currentPage++;
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final String strDateFrom = DateFormat('yyyy-MM-dd').format(_dateFrom);
      final String strDateTo = DateFormat('yyyy-MM-dd').format(_dateTo);

      final result = await _service.getTransactions(
        dateFrom: strDateFrom,
        dateTo: strDateTo,
        search: _searchCtrl.text.trim(),
        page: _currentPage,
        perPage: 20, // Ambil 20 data per tarikan
      );

      setState(() {
        if (loadMore) {
          _transactions.addAll(result['transactions'] as List<TransactionReport>);
        } else {
          _transactions = result['transactions'] as List<TransactionReport>;
        }
        _totalPages = result['total_pages'];
      });
    } catch (e) {
      if (!loadMore) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      } else {
        _showNotif(e.toString().replaceAll('Exception: ', ''), AppColors.error);
        _currentPage--; // Kembalikan halaman jika gagal load more
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);
  }
  
  // Format tanggal dari API (misal: "2026-10-12 14:30:00" -> "12 Okt 2026, 14:30")
  String _formatDateUI(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  void _showNotif(String pesan, Color warna) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: warna, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        // Jika Halaman ini masuk ke dalam KerangkaNavigasi (BottomNav), biasanya tidak perlu tombol Back.
        // Tapi kita biarkan iconTheme menyesuaikan agar tetap elegan.
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Column(
        children: [
          // PANEL PENCARIAN & FILTER
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari Nomor Invoice...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(icon: const Icon(Icons.send, color: AppColors.primaryEmerald), onPressed: () => _fetchTransactions()),
                    filled: true,
                    fillColor: AppColors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (_) => _fetchTransactions(),
                ),
                const SizedBox(height: 12),
                
                // CHIPS FILTER TANGGAL
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Hari Ini', '7 Hari Terakhir', 'Bulan Ini'].map((filter) {
                      bool isSelected = _selectedFilterDate == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: AppColors.primaryEmerald,
                          backgroundColor: AppColors.lightGray,
                          showCheckmark: false,
                          onSelected: (val) {
                            if (val) _setFilterDate(filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Menampilkan data: $_selectedFilterDate', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),

          // DAFTAR TRANSAKSI
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage, style: const TextStyle(color: AppColors.error)))
                  : _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              const Text('Belum ada transaksi.', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primaryEmerald,
                          onRefresh: () => _fetchTransactions(loadMore: false),
                          child: ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                            itemCount: _transactions.length + 1, // +1 untuk tombol Load More
                            itemBuilder: (context, index) {
                              if (index == _transactions.length) {
                                // Tampilkan tombol Load More jika masih ada halaman berikutnya
                                return _currentPage < _totalPages
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: _isLoadingMore
                                            ? const CircularProgressIndicator(color: AppColors.primaryEmerald)
                                            : TextButton(
                                                onPressed: () => _fetchTransactions(loadMore: true),
                                                child: const Text('Muat Lebih Banyak', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold)),
                                              ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                              }

                              final trx = _transactions[index];
                              bool isCompleted = trx.transactionStatus == 'COMPLETED';

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  // Navigasi ke Halaman Detail Transaksi jika ditekan
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HalamanDetailTransaksi(
                                          transactionId: trx.transactionId,
                                          invoiceNumber: trx.invoiceNumber,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.receipt, size: 18, color: AppColors.textSecondary),
                                                const SizedBox(width: 8),
                                                Text(trx.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(color: isCompleted ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                              child: Text(
                                                isCompleted ? 'BERHASIL' : 'BATAL',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? Colors.green.shade700 : Colors.red.shade700),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(_formatDateUI(trx.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                const SizedBox(height: 4),
                                                Text('Kasir: ${trx.cashierName} • ${trx.itemQty} Item', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                                const SizedBox(height: 4),
                                                Text(trx.payments.isNotEmpty ? trx.payments[0].method : 'Tunai', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB8860B))),
                                              ],
                                            ),
                                            Text(
                                              _formatCurrency(trx.grandTotal),
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCompleted ? AppColors.primaryEmerald : Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
          ),
        ],
      ),
    );
  }
}
