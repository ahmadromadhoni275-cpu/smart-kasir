import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'tema.dart'; 
import 'core/services/notification_api_service.dart';

class HalamanNotifikasi extends StatefulWidget {
  const HalamanNotifikasi({super.key});

  @override
  State<HalamanNotifikasi> createState() => _HalamanNotifikasiState();
}

class _HalamanNotifikasiState extends State<HalamanNotifikasi> {
  final NotificationApiService _apiService = NotificationApiService();
  
  bool _isLoading = true;
  List<dynamic> _allNotifications = [];
  int _unreadCount = 0;
  String _selectedCategory = 'SEMUA';

  // Daftar Kategori Statis
  final List<String> _categories = ['SEMUA', 'TRANSACTION', 'STOCK', 'SHIFT', 'SYSTEM'];

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
          _allNotifications = res['data'] ?? [];
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
        for (var notif in _allNotifications) {
          notif['is_read'] = 1;
        }
      });
    } catch (e) {
      debugPrint('Gagal menandai semua dibaca: $e');
    }
  }

  Future<void> _hapusNotifikasi(int id, int index, List<dynamic> filteredList) async {
    try {
      await _apiService.deleteNotification(id);
      
      // Update state lokal
      setState(() {
        final notif = filteredList[index];
        if (notif['is_read'] == 0 || notif['is_read'] == "0") {
          if (_unreadCount > 0) _unreadCount--;
        }
        _allNotifications.removeWhere((element) => element['notification_id'].toString() == id.toString());
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus notifikasi'), backgroundColor: AppColors.error));
      _fetchNotifications(); // Refresh data jika gagal hapus
    }
  }

  Future<void> _handleNotifClick(dynamic notif) async {
    // 1. Tandai dibaca
    if (notif['is_read'] == 0 || notif['is_read'] == "0") {
      setState(() {
        notif['is_read'] = 1;
        if (_unreadCount > 0) _unreadCount--;
      });
      _apiService.markAsRead(int.parse(notif['notification_id'].toString()));
    }

    // 2. Navigasi ke halaman tujuan
    final route = notif['action_route'];
    if (route != null && route.toString().isNotEmpty) {
      Navigator.pushNamed(context, route.toString());
    }
  }

  // --- HELPER IKON & WARNA ---
  IconData _getIcon(String type) {
    switch (type.toUpperCase()) {
      case 'TRANSACTION': return Icons.receipt_long;
      case 'STOCK': return Icons.inventory_2_outlined;
      case 'SHIFT': return Icons.swap_horiz;
      case 'SUBSCRIPTION': return Icons.workspace_premium;
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
      case 'SUBSCRIPTION': return AppColors.goldPremium;
      case 'REFERRAL': return Colors.pink;
      case 'SUPPORT': return Colors.blue;
      case 'SECURITY': return AppColors.error;
      case 'SYSTEM': return AppColors.navyActive;
      default: return AppColors.textSecondary;
    }
  }

  String _formatKategoriLabel(String type) {
    switch (type.toUpperCase()) {
      case 'TRANSACTION': return 'Transaksi';
      case 'STOCK': return 'Stok';
      case 'SHIFT': return 'Shift';
      case 'SYSTEM': return 'Sistem';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    // LOGIKA PENGELOMPOKAN / FILTER KATEGORI
    final List<dynamic> filteredNotifs = _selectedCategory == 'SEMUA' 
        ? _allNotifications 
        : _allNotifications.where((n) => n['type'].toString().toUpperCase() == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Dibuat 0 karena ada border di bawah
        iconTheme: const IconThemeData(color: AppColors.navyActive),
        title: const Text('Notifikasi', style: TextStyle(color: AppColors.navyActive, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tandai Semua Dibaca', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
            )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        _formatKategoriLabel(cat), 
                        style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12)
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.smartBlue,
                      backgroundColor: AppColors.lightGray,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.transparent)),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.smartBlue))
          : filteredNotifs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: AppColors.smartBlue,
                  child: ListView.separated(
                    itemCount: filteredNotifs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final notif = filteredNotifs[index];
                      final bool isUnread = notif['is_read'] == 0 || notif['is_read'] == "0";
                      final DateTime date = DateTime.parse(notif['created_at']).toLocal();
                      final iconColor = _getIconColor(notif['type']);

                      // LOGIKA PENGHAPUSAN (SWIPE TO DELETE)
                      return Dismissible(
                        key: Key(notif['notification_id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          color: AppColors.error,
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (direction) => _hapusNotifikasi(int.parse(notif['notification_id'].toString()), index, filteredNotifs),
                        child: Material(
                          color: isUnread ? AppColors.smartBlue.withOpacity(0.05) : Colors.white,
                          child: InkWell(
                            onTap: () => _handleNotifClick(notif),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: iconColor.withOpacity(0.1),
                                    child: Icon(_getIcon(notif['type']), color: iconColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notif['title'],
                                          style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, color: AppColors.navyActive, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif['message'], 
                                          style: TextStyle(color: isUnread ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13, height: 1.4)
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          DateFormat('dd MMM yyyy • HH:mm').format(date),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isUnread)
                                    Container(
                                      margin: const EdgeInsets.only(top: 6, left: 8),
                                      width: 10, height: 10, 
                                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)
                                    ),
                                ],
                              ),
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
          Text(_selectedCategory == 'SEMUA' ? 'Belum Ada Notifikasi' : 'Tidak ada notifikasi ${_formatKategoriLabel(_selectedCategory)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyActive)),
          const SizedBox(height: 8),
          const Text('Semua pembaruan sistem dan info aktivitas\nakan muncul di sini.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
