import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'core/services/transaction_service.dart';
import 'models/transaction_model.dart';
import 'tema.dart'; 
// PENTING: Tambahkan import untuk HalamanDetailTransaksi
import 'halaman_detail_transaksi.dart'; 

class HalamanLaporanTransaksi extends StatefulWidget {
  const HalamanLaporanTransaksi({super.key});

  @override
  State<HalamanLaporanTransaksi> createState() => _HalamanLaporanTransaksiState();
}

class _HalamanLaporanTransaksiState extends State<HalamanLaporanTransaksi> {
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _searchCtrl = TextEditingController();
  
  List<TransactionReport> _transactions = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Filter & Pagination State
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  String _selectedStatus = ''; // Kosong berarti semua
  int _currentPage = 1;
  int _totalPages = 1;
  final int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions({bool isNextPage = false}) async {
    if (isNextPage) {
      if (_currentPage >= _totalPages) return;
      _currentPage++;
    } else {
      _currentPage = 1;
      _transactions.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final DateFormat apiFormat = DateFormat('yyyy-MM-dd');
      final result = await _transactionService.getTransactions(
        dateFrom: apiFormat.format(_startDate),
        dateTo: apiFormat.format(_endDate),
        page: _currentPage,
        perPage: _perPage,
        status: _selectedStatus,
        search: _searchCtrl.text.trim(),
      );

      setState(() {
        if (isNextPage) {
          _transactions.addAll(result['transactions']);
        } else {
          _transactions = result['transactions'];
        }
        _totalPages = result['total_pages'];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pilihTanggal(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryEmerald),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) _startDate = _endDate;
        }
      });
      _fetchTransactions();
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat displayFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryEmerald,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // PANEL FILTER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari No. Invoice...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primaryEmerald),
                      onPressed: () => _fetchTransactions(),
                    ),
                    filled: true,
                    fillColor: AppColors.lightGray,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (_) => _fetchTransactions(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pilihTanggal(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Text(displayFormat.format(_startDate), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pilihTanggal(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Text(displayFormat.format(_endDate), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedStatus,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            items: const [
                              DropdownMenuItem(value: '', child: Text('Semua', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'COMPLETED', child: Text('Selesai', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'CANCELED', child: Text('Batal', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedStatus = value!);
                              _fetchTransactions();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LIST TRANSAKSI
          Expanded(
            child: _isLoading && _transactions.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                    : _transactions.isEmpty
                        ? const Center(child: Text('Tidak ada transaksi pada periode ini.', style: TextStyle(color: AppColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _transactions.length + (_currentPage < _totalPages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _transactions.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _fetchTransactions(isNextPage: true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryEmerald,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Muat Lebih Banyak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              }

                              final tx = _transactions[index];
                              
                              // PERUBAHAN: Membungkus Card dengan InkWell untuk navigasi
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HalamanDetailTransaksi(
                                        transactionId: tx.transactionId,
                                        invoiceNumber: tx.invoiceNumber,
                                      ),
                                    ),
                                  );
                                },
                                // Berikan sedikit efek membulat saat ditekan
                                borderRadius: BorderRadius.circular(16), 
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  elevation: 0,
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(tx.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: tx.transactionStatus == 'COMPLETED' ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: tx.transactionStatus == 'COMPLETED' ? Colors.green.shade200 : Colors.red.shade200),
                                              ),
                                              child: Text(
                                                tx.transactionStatus,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: tx.transactionStatus == 'COMPLETED' ? Colors.green.shade700 : Colors.red.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 12),
                                          child: Divider(height: 1, thickness: 1),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${tx.itemQty} Item', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                                const SizedBox(height: 4),
                                                Text(tx.createdAt, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(_formatCurrency(tx.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryEmerald)),
                                                const SizedBox(height: 4),
                                                Text(tx.payments.map((p) => p.method).join(', '), style: const TextStyle(fontSize: 11, color: AppColors.slateGray, fontWeight: FontWeight.bold)),
                                              ],
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
        ],
      ),
    );
  }
}
