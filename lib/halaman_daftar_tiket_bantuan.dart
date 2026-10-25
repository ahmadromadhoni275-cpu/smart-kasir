import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart'; // File tema (AppColors)
import 'core/services/support_api_service.dart';
import 'halaman_detail_tiket_bantuan.dart'; // Import halaman detail tiket

class HalamanDaftarTiket extends StatefulWidget {
  const HalamanDaftarTiket({super.key});

  @override
  State<HalamanDaftarTiket> createState() => _HalamanDaftarTiketState();
}

class _HalamanDaftarTiketState extends State<HalamanDaftarTiket> {
  final SupportApiService _apiService = SupportApiService();
  bool _isLoading = true;
  List<dynamic> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getTickets();
      if (mounted) {
        setState(() {
          _tickets = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat daftar tiket.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN': return AppColors.error; // Merah/Penting
      case 'IN_PROGRESS': return Colors.blue;
      case 'RESOLVED': return AppColors.primaryEmerald;
      case 'CLOSED': return AppColors.textSecondary;
      default: return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'OPEN': return 'Menunggu Balasan';
      case 'IN_PROGRESS': return 'Sedang Ditangani';
      case 'RESOLVED': return 'Selesai';
      case 'CLOSED': return 'Ditutup';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        title: const Text(
          'Daftar Tiket Bantuan', 
          style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _tickets.isEmpty
              ? _buildEmptyState()
              : _buildTicketList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada tiket bantuan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyActive),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jika Anda memiliki kendala teknis,\ntanyakan pada Smart Assist terlebih dahulu.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            label: const Text('Buka Smart Assist', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryEmerald,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return RefreshIndicator(
      onRefresh: _loadTickets,
      color: AppColors.primaryEmerald,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          final DateTime updatedAt = DateTime.parse(ticket['updated_at']).toLocal();
          
          return InkWell(
            onTap: () async {
              // Buka halaman detail, tunggu hingga kembali, lalu refresh list tiket
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HalamanDetailTiket(ticketId: int.parse(ticket['support_ticket_id'].toString()))),
              );
              _loadTickets();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${ticket['support_ticket_id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryEmerald, fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(ticket['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(ticket['status']),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(ticket['status'])),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ticket['subject'],
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyActive),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket['description'],
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Diperbarui: ${DateFormat('dd MMM yyyy, HH:mm').format(updatedAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
