import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart';
import 'core/services/stock_service.dart';

class HalamanRiwayatStok extends StatefulWidget {
  const HalamanRiwayatStok({super.key});

  @override
  State<HalamanRiwayatStok> createState() => _HalamanRiwayatStokState();
}

class _HalamanRiwayatStokState extends State<HalamanRiwayatStok> {
  bool _isLoading = true;
  List<dynamic> _movements = [];
  String _filterType = ''; // '', 'IN', 'OUT', 'ADJUSTMENT', 'RETURN'

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => _isLoading = true);
    try {
      final mvs = await StockService.getMovements(type: _filterType);
      setState(() => _movements = mvs);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
    }
    setState(() => _isLoading = false);
  }

  Color _getColorByType(String type) {
    if (type == 'IN') return Colors.blue;
    if (type == 'OUT') return Colors.red;
    if (type == 'RETURN') return AppColors.primaryEmerald;
    return Colors.orange; // ADJUSTMENT
  }

  IconData _getIconByType(String type) {
    if (type == 'IN') return Icons.arrow_downward;
    if (type == 'OUT') return Icons.arrow_upward;
    if (type == 'RETURN') return Icons.assignment_return;
    return Icons.tune; // ADJUSTMENT
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Pergerakan Stok', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua', ''),
                  const SizedBox(width: 8),
                  _buildFilterChip('Masuk', 'IN'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Keluar', 'OUT'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Penyesuaian', 'ADJUSTMENT'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Retur', 'RETURN'),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
                : _movements.isEmpty
                    ? const Center(child: Text('Tidak ada pergerakan stok.', style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: _fetchRiwayat,
                        color: AppColors.primaryEmerald,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _movements.length,
                          itemBuilder: (ctx, i) {
                            final mv = _movements[i];
                            String type = mv['type'] ?? 'UNKNOWN';
                            int qty = int.tryParse(mv['quantity'].toString()) ?? 0;
                            String prefix = (type == 'IN' || type == 'RETURN' || qty > 0) ? '+' : '';

                            DateTime date = DateTime.parse(mv['created_at']).toLocal();
                            String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                             shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: AppColors.border),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getColorByType(type).withOpacity(0.1),
                                  child: Icon(_getIconByType(type), color: _getColorByType(type)),
                                ),
                                title: Text(mv['product_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('$formattedDate • ${mv['user_name'] ?? 'Sistem'}', style: const TextStyle(fontSize: 12)),
                                    if (mv['note'] != null && mv['note'].toString().isNotEmpty)
                                      Text('Catatan: ${mv['note']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$prefix$qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _getColorByType(type))),
                                    const SizedBox(height: 4),
                                    Text('${mv['stock_before']} ➔ ${mv['stock_after']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                  ],
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

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primaryEmerald,
      backgroundColor: AppColors.lightGray,
      showCheckmark: false,
      onSelected: (val) {
        if (val) {
          setState(() => _filterType = value);
          _fetchRiwayat();
        }
      },
    );
  }
}
