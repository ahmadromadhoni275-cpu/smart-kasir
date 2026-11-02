import 'package:flutter/material.dart';
import '../tema.dart';
import '../core/services/notification_api_service.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({super.key});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final res = await NotificationApiService().getNotifications();
      if (mounted) setState(() => _unreadCount = res['unread_count'] ?? 0);
    } catch (_) {
      // Abaikan jika error, badge tidak akan muncul
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.navyActive),
          onPressed: () async {
            // Arahkan ke halaman notifikasi, jika kembali, cek ulang unread count
            await Navigator.pushNamed(context, '/notifikasi');
            _fetchUnreadCount();
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8, right: 8,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }
}
