import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import 'core/services/transaction_service.dart';
import 'models/transaction_model.dart';
import 'tema.dart'; 
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
  bool _isPrinting = false; // State untuk loading cetak
  String _errorMessage = '';
  
  // Filter State
  String _filterWaktu = 'hari_ini';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedStatus = ''; 
  int _currentPage = 1;
  int _totalPages = 1;
  final int _perPage = 20;

  @override
  void initState() {
    super.initState();
    _terapkanFilterWaktu('hari_ini');
  }

  void _terapkanFilterWaktu(String filter) {
    final now = DateTime.now();
    setState(() {
      _filterWaktu = filter;
      if (filter == 'hari_ini') {
        _startDate = now;
        _endDate = now;
      } else if (filter == 'kemarin') {
        _startDate = now.subtract(const Duration(days: 1));
        _endDate = now.subtract(const Duration(days: 1));
      } else if (filter == 'minggu_ini') {
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
      }
    });
    if (filter != 'rentang') {
      _fetchTransactions();
    }
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
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pilihRentangTanggal(BuildContext context) async {
    DateTimeRange? range = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
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

    if (range != null) {
      setState(() {
        _filterWaktu = 'rentang';
        _startDate = range.start;
        _endDate = range.end;
      });
      _fetchTransactions();
    }
  }

  // ==========================================
  // FITUR CETAK CEPAT DARI LIST
  // ==========================================
  Future<void> _cetakCepat(int transactionId, String invoice) async {
    if (kIsWeb || Platform.isIOS) {
      _showNotif('Platform tidak didukung.', Colors.red);
      return;
    }

    setState(() => _isPrinting = true);
    _showNotif('Menyiapkan struk $invoice...', AppColors.smartBlue);

    try {
      // Tarik detail barang dari API secara diam-diam
      final detail = await _transactionService.getTransactionDetail(transactionId);
      
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.text("SMART KASIR", styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      bytes += generator.text(detail['store_name'] ?? 'Toko Anda', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.row([PosColumn(text: "No", width: 4), PosColumn(text: ": $invoice", width: 8)]);
      bytes += generator.row([PosColumn(text: "Tgl", width: 4), PosColumn(text: ": ${detail['created_at']}", width: 8)]);
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));

      List items = detail['items'] ?? [];
      for (var item in items) {
        bytes += generator.text("${item['product_name']}", styles: const PosStyles(align: PosAlign.left));
        bytes += generator.row([
          PosColumn(text: "${item['qty']} x ${_formatCurrency(item['price'])}", width: 8),
          PosColumn(text: _formatCurrency(item['total']), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      
      bytes += generator.text("--------------------------------", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.row([PosColumn(text: "TOTAL", width: 6, styles: const PosStyles(bold: true)), PosColumn(text: _formatCurrency(detail['grand_total']), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true))]);
      bytes += generator.text("================================", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.text("Terima Kasih", styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);

      bool isConnected = await PrintBluetoothThermal.connectionStatus;
      if (isConnected) {
        await PrintBluetoothThermal.writeBytes(bytes);
        _showNotif('Berhasil mencetak!', AppColors.primaryEmerald);
      } else {
        _showNotif('Printer tidak terhubung.', Colors.red);
      }
    } catch (e) {
      _showNotif('Gagal mencetak: $e', Colors.red);
    } finally {
      setState(() => _isPrinting = false);
    }
  }

  String _formatCurrency(dynamic amount) {
    double val = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(val);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B), // Tema Navy Premium
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Chip Cepat
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Hari Ini', 'hari_ini'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Kemarin', 'kemarin'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Minggu Ini', 'minggu_ini'),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: Text(_filterWaktu == 'rentang' 
                            ? '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}'
                            : 'Pilih Tanggal'),
                        avatar: const Icon(Icons.calendar_month, size: 16),
                        onPressed: () => _pilihRentangTanggal(context),
                        backgroundColor: _filterWaktu == 'rentang' ? AppColors.primaryEmerald.withOpacity(0.1) : AppColors.lightGray,
                        side: BorderSide(color: _filterWaktu == 'rentang' ? AppColors.primaryEmerald : Colors.grey.shade300),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Pencarian & Status
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cari Invoice...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: AppColors.lightGray,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onSubmitted: (_) => _fetchTransactions(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedStatus,
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
                        ? const Center(child: Text('Tidak ada transaksi.', style: TextStyle(color: AppColors.textSecondary)))
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
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('Muat Lebih Banyak', style: TextStyle(color: Colors.white)),
                                  ),
                                );
                              }

                              final tx = _transactions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                                elevation: 0,
                                color: Colors.white,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (context) => HalamanDetailTransaksi(transactionId: tx.transactionId, invoiceNumber: tx.invoiceNumber),
                                    ));
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Baris 1: Invoice & Status
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(tx.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: tx.transactionStatus == 'COMPLETED' ? Colors.green.shade50 : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                tx.transactionStatus,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tx.transactionStatus == 'COMPLETED' ? Colors.green.shade700 : Colors.red.shade700),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 20),
                                        
                                        // Baris 2: Info Kasir & Total
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person_outline, size: 14, color: AppColors.slateGray),
                                                    const SizedBox(width: 4),
                                                    Text(tx.cashierName, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text('${tx.itemQty} Item • ${tx.createdAt}', style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(_formatCurrency(tx.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryEmerald)),
                                                const SizedBox(height: 4),
                                                Text(tx.payments.isNotEmpty ? tx.payments[0].method : '-', style: const TextStyle(fontSize: 11, color: Color(0xFFB8860B), fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        
                                        // Baris 3: Tombol Cetak Cepat
                                        if (tx.transactionStatus == 'COMPLETED') ...[
                                          const SizedBox(height: 12),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: OutlinedButton.icon(
                                              onPressed: _isPrinting ? null : () => _cetakCepat(tx.transactionId, tx.invoiceNumber),
                                              icon: const Icon(Icons.print, size: 16),
                                              label: const Text('Cetak', style: TextStyle(fontSize: 12)),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                foregroundColor: AppColors.primaryEmerald,
                                                side: const BorderSide(color: AppColors.primaryEmerald),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          )
                                        ]
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

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filterWaktu == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12)),
      selected: isSelected,
      selectedColor: const Color(0xFF1E293B), // Navy color
      backgroundColor: AppColors.lightGray,
      onSelected: (_) => _terapkanFilterWaktu(value),
    );
  }
}
