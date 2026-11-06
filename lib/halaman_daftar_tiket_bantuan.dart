import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart';
import 'models/support_ticket_model.dart';
import 'core/services/support_ticket_service.dart';
import 'halaman_detail_tiket_bantuan.dart'; 

class HalamanDaftarTiket extends StatefulWidget {
  const HalamanDaftarTiket({super.key});

  @override
  State<HalamanDaftarTiket> createState() => _HalamanDaftarTiketState();
}

class _HalamanDaftarTiketState extends State<HalamanDaftarTiket> {
  final SupportTicketService _ticketService = SupportTicketService();
  bool _isLoading = true;
  List<SupportTicketModel> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final data = await _ticketService.getTickets();
      if (mounted) setState(() => _tickets = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN': return AppColors.error;
      case 'IN_PROGRESS': return AppColors.smartBlue;
      case 'RESOLVED': return AppColors.primaryEmerald;
      case 'CLOSED': return AppColors.textSecondary;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Daftar Tiket', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.7),
        flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        actions: [IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primaryEmerald), onPressed: () {} /* Navigasi Form Tiket */)],
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.backgroundGradientStart, AppColors.background, AppColors.backgroundGradientEnd]))),
          
          _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
              : _tickets.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_turned_in, size: 64, color: AppColors.textSecondary.withOpacity(0.3)), const SizedBox(height: 16), const Text('Tidak ada tiket aktif', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyActive))]))
                  : RefreshIndicator(
                      onRefresh: _loadTickets,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight + 16, left: 16, right: 16, bottom: 40),
                        itemCount: _tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = _tickets[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: AppColors.shadowBlue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('#${ticket.ticketId}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryEmerald, fontSize: 13)),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _getStatusColor(ticket.status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(ticket.status, style: TextStyle(color: _getStatusColor(ticket.status), fontSize: 10, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(ticket.subject, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyActive)),
                                  const SizedBox(height: 4),
                                  Text(ticket.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  const Divider(height: 24, color: AppColors.border),
                                  Text('Update: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(ticket.updatedAt).toLocal())}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                              onTap: () {}, // Buka halaman detail
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
