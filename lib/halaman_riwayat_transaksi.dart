import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'core/services/transaction_service.dart';
import 'models/transaction_model.dart'; 
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

  // --- FILTER STATE ---
  String _selectedFilterDate = 'Hari Ini';
  String _selectedStatus = 'SEMUA'; // SEMUA, COMPLETED, CANCELED
  String _selectedPayment = 'SEMUA'; // SEMUA, CASH, QRIS, dll
  
  late DateTime _dateFrom;
  late DateTime _dateTo;

  // --- PAGINATION ---
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _setFilterDate('Hari Ini');
  }

  void _setFilterDate(String filterType) {
    DateTime now = DateTime.now();
    setState(() {
      _selectedFilterDate = filterType;
      _currentPage = 1;
      
      if (filterType == 'Hari Ini') {
        _dateFrom = now;
        _dateTo = now;
      } else if (filterType == '7 Hari Terakhir') {
        _dateFrom = now.subtract(const Duration(days: 7));
        _dateTo = now;
      } else if (filterType == 'Bulan Ini') {
        _dateFrom = DateTime(now.year, now.month, 1);
        _dateTo = DateTime(now.year, now.month + 1, 0); 
      }
    });
    _fetchTransactions();
  }

  void _applyFilter({String? status, String? payment}) {
    setState(() {
      if (status != null) _selectedStatus = status;
      if (payment != null) _selectedPayment = payment;
      _currentPage = 1;
    });
    _fetchTransactions();
  }

  Future<void> _fetchTransactions({bool loadMore = false}) async {
    if (loadMore) {
      if (_currentPage >= _totalPages) return; 
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
      
      // Catatan: Pastikan _service.getTransactions mendukung parameter status & metode jika backend sudah siap.
      // Jika belum, kita hanya passing status dasar ke backend.
      final result = await _service.getTransactions(
        dateFrom: strDateFrom,
        dateTo: strDateTo,
        search: _searchCtrl.text.trim(),
        status: _selectedStatus == 'SEMUA' ? '' : _selectedStatus,
        page: _currentPage,
        perPage: 20, 
      );

      List<TransactionReport> fetched = result['transactions'] as List<TransactionReport>;
      
      // Filter Manual Sisi Client untuk Payment Method (Jika backend belum support query filter payment)
      if (_selectedPayment != 'SEMUA') {
        fetched = fetched.where((t) => t.payments.any((p) => p.method == _selectedPayment)).toList();
      }

      setState(() {
        if (loadMore) {
          _transactions.addAll(fetched);
        } else {
          _transactions = fetched;
          if (_transactions.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _tampilPopupCantik('Data Kosong', 'Tidak ada transaksi pada filter yang dipilih.', Icons.receipt_long, AppColors.textSecondary);
            });
          }
        }
        _totalPages = result['total_pages'];
      });
    } catch (e) {
      if (!loadMore) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tampilPopupCantik('Gagal Memuat', _errorMessage, Icons.error_outline, AppColors.error);
        });
      } else {
         _tampilPopupCantik('Gagal Memuat Lanjutan', e.toString().replaceAll('Exception: ', ''), Icons.warning, AppColors.warning);
        _currentPage--; 
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // --- POPUP NOTIFIKASI CANTIK ---
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

  // --- HELPER FORMATTER ---
  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);
  }
  
  String _formatDateUI(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  // --- BOTTOM SHEET FILTER ---
  void _tampilkanModalFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filter Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Status Transaksi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['SEMUA', 'COMPLETED', 'CANCELED'].map((s) {
                    bool isSelected = _selectedStatus == s;
                    return ChoiceChip(
                      label: Text(s == 'COMPLETED' ? 'Berhasil' : (s == 'CANCELED' ? 'Batal' : 'Semua'), style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary)),
                      selected: isSelected,
                      selectedColor: AppColors.primaryEmerald,
                      onSelected: (val) {
                        setModalState(() => _selectedStatus = s);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['SEMUA', 'CASH', 'QRIS', 'TRANSFER'].map((p) {
                    bool isSelected = _selectedPayment == p;
                    return ChoiceChip(
                      label: Text(p, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary)),
                      selected: isSelected,
                      selectedColor: AppColors.smartBlue,
                      onSelected: (val) {
                        setModalState(() => _selectedPayment = p);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryEmerald, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _applyFilter();
                    },
                    child: const Text('Terapkan Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.navyActive),
            onPressed: _tampilkanModalFilter,
          )
        ],
      ),
      body: Column(
        children: [
          // PANEL PENCARIAN & FILTER TANGGAL
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari Nomor Invoice / Kasir...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (_) => _fetchTransactions(),
                ),
                const SizedBox(height: 16),
                
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
                          selectedColor: AppColors.navyActive,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Menampilkan: $_selectedFilterDate', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)),
                if (_selectedStatus != 'SEMUA' || _selectedPayment != 'SEMUA')
                  const Icon(Icons.filter_alt, size: 16, color: AppColors.primaryEmerald)
              ],
            ),
          ),

          // DAFTAR TRANSAKSI
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _transactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('Belum ada transaksi.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryEmerald,
                      onRefresh: () => _fetchTransactions(loadMore: false),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                        itemCount: _transactions.length + 1, 
                        itemBuilder: (context, index) {
                          if (index == _transactions.length) {
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

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HalamanDetailTransaksi(
                                      transactionId: trx.transactionId,
                                      invoiceNumber: trx.invoiceNumber,
                                    ),
                                  ),
                                ).then((_) => _fetchTransactions()); // Auto-refresh setelah kembali dari detail
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
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)),
                                              child: const Icon(Icons.receipt_outlined, size: 16, color: AppColors.navyActive),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(trx.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyActive)),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: isCompleted ? AppColors.primaryEmerald.withOpacity(0.1) : AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                          child: Text(
                                            isCompleted ? 'BERHASIL' : 'BATAL',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompleted ? AppColors.primaryEmerald : AppColors.error),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Divider(height: 1, color: AppColors.border),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_formatDateUI(trx.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            const SizedBox(height: 4),
                                            Text('Ksr: ${trx.cashierName} • ${trx.itemQty} Item', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            const SizedBox(height: 4),
                                            Text(trx.payments.isNotEmpty ? trx.payments.map((p) => p.method).join(', ') : 'CASH', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.smartBlue)),
                                          ],
                                        ),
                                        Text(
                                          _formatCurrency(trx.grandTotal),
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isCompleted ? AppColors.primaryEmerald : Colors.grey),
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
