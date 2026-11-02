class NotificationModel {
  final int notificationId;
  final int userId;
  final String type;
  final String title;
  final String message;
  final String actionRoute;
  bool isRead; // Boleh diubah saat di-tap
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.actionRoute,
    required this.isRead,
    required this.createdAt,
  });

  // 1. Mengubah JSON dari API menjadi Objek Dart (Sudah ada sebelumnya)
  factory NotificationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return NotificationModel(
        notificationId: 0, userId: 0, type: 'SYSTEM', title: 'Info', 
        message: '-', actionRoute: '', isRead: true, createdAt: DateTime.now()
      );
    }
    
    return NotificationModel(
      notificationId: int.tryParse(json['notification_id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString().toUpperCase() ?? 'SYSTEM',
      title: json['title']?.toString() ?? 'Informasi',
      message: json['message']?.toString() ?? '-',
      actionRoute: json['action_route']?.toString() ?? '',
      isRead: (json['is_read']?.toString() == '1'), 
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // 2. TAMBAHKAN INI: Mengubah kembali Objek Dart menjadi Map (JSON) untuk dibaca UI
  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'action_route': actionRoute,
      'is_read': isRead ? 1 : 0, // Kembalikan ke format angka 1/0 agar UI tidak error
      'created_at': createdAt.toIso8601String(),
    };
  }
}
