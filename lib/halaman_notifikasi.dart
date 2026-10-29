import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart'; // File tema yang memuat AppColors
import 'core/services/notification_api_service.dart';

class HalamanNotifikasi extends StatefulWidget {
  const HalamanNotifikasi({super.key});

  @override
  State<HalamanNotifikasi> createState() => _HalamanNotifikasiState();
}

class _HalamanNotifikasiState extends State<HalamanNotifikasi> {
  final NotificationApiService _apiService = NotificationApiService();
  
  bool _isLoading = true;
  List<dynamic> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = res['data'] ?? [];
          _unreadCount = res['unread_count'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat notifikasi.'), backgroundColor: AppColors.error)
        );
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _apiService.markAllAsRead();
      setState(() {
        _unreadCount = 0;
        for (var notif in _notifications) {
          notif['is_read'] = 1;
        }
      });
    } catch (e) {
      debugPrint('Gagal menandai semua dibaca: $e');
    }
  }

  Future<void> _handleNotifClick(dynamic notif) async {
    // 1. Tandai sebagai dibaca jika statusnya belum dibaca (0)
    if (notif['is_read'] == 0 || notif['is_read'] == "0") {
      setState(() {
        notif['is_read'] = 1;
        if (_unreadCount > 0) _unreadCount--;
      });
      _apiService.markAsRead(int.parse(notif['notification_id'].toString()));
    }

    // 2. Navigasi ke Action Route jika tersedia
    final route = notif['action_route'];
    if (route != null && route.toString().isNotEmpty) {
      // Pastikan route yang dikirim dari server sudah didaftarkan di MaterialApp(routes: {...})
      Navigator.pushNamed(context, route.toString());
    }
  }

  // --- HELPER IKON & WARNA BERDASARKAN KATEGORI ---
  IconData _getIcon(String type) {
    switch (type.toUpperCase()) {
      case 'TRANSACTION': return Icons.receipt_long;
      case 'STOCK': return Icons.inventory_2_outlined;
      case 'SHIFT': return Icons.swap_horiz;
      case 'SUBSCRIPTION': return Icons.diamond_outlined;
      case 'REFERRAL': return Icons.card_giftcard;
      case 'SUPPORT': return Icons.headset_mic_outlined;
      case 'SECURITY': return Icons.security;
      case 'SYSTEM': return Icons.campaign_outlined;
      default: return Icons.notifications_none; 
    }
  }

  Color _getIconColor(String type) {
    switch (type.toUpperCase()) {
      case 'TRANSACTION': return AppColors.primaryEmerald;
      case 'STOCK': return Colors.orange;
      case 'SHIFT': return Colors.teal;
      case 'SUBSCRIPTION': return Colors.purple;
      case 'REFERRAL': return Colors.pink;
      case 'SUPPORT': return Colors.blue;
      case 'SECURITY': return AppColors.error;
      case 'SYSTEM': return AppColors.navyActive;
      default: return AppColors.textSecondary;
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
        title: const Text('Notifikasi', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tandai Semua Dibaca', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
            )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryEmerald))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: AppColors.primaryEmerald,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final bool isUnread = notif['is_read'] == 0 || notif['is_read'] == "0";
                      final DateTime date = DateTime.parse(notif['created_at']).toLocal();
                      
                      final iconColor = _getIconColor(notif['type']);

                      return Material(
                        color: isUnread ? AppColors.primaryEmerald.withOpacity(0.05) : Colors.white,
                        child: InkWell(
                          onTap: () => _handleNotifClick(notif),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Ikon Kategori
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: iconColor.withOpacity(0.1),
                                  child: Icon(_getIcon(notif['type']), color: iconColor, size: 22),
                                ),
                                const SizedBox(width: 12),
                                
                                // Konten Teks
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif['title'],
                                        style: TextStyle(
                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, 
                                          color: AppColors.navyActive, 
                                          fontSize: 14
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['message'], 
                                        style: TextStyle(
                                          color: isUnread ? AppColors.textPrimary : AppColors.textSecondary, 
                                          fontSize: 13,
                                          height: 1.4
                                        )
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormat('dd MMM yyyy • HH:mm').format(date),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),

                                // Indikator Titik Merah (Unread)
                                if (isUnread)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6, left: 8),
                                    width: 10, 
                                    height: 10, 
                                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 72, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Belum Ada Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
          const SizedBox(height: 8),
          const Text(
            'Pengumuman sistem, info transaksi,\ndan pembaruan stok akan muncul di sini.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)
          ),
        ],
      ),
    );
  }
}
