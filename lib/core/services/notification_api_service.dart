import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/notification_model.dart';

class NotificationApiService {
  final Dio _dio = ApiClient().dio;

  // Mendapatkan daftar notifikasi dan jumlah yang belum dibaca
  Future> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List<dynamic> rawData = response.data['data'];
        final int unreadCount = response.data['unread_count'] ?? 0;
        
        final List<NotificationModel> notifications = 
            rawData.map((json) => NotificationModel.fromJson(json)).toList();
            
        return {'data': notifications, 'unread_count': unreadCount};
      }
      return {'data': <NotificationModel>[], 'unread_count': 0};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat notifikasi.');
    }
  }

  // Menandai satu notifikasi telah dibaca
  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
    } catch (e) {
      throw Exception('Gagal memperbarui status notifikasi.');
    }
  }
  
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _dio.delete('/notifications/$notificationId');
    } catch (e) {
      throw Exception('Gagal menghapus notifikasi.');
    }
  }

  // Menandai seluruh notifikasi telah dibaca
  Future<void> markAllAsRead() async {
    try {
      await _dio.put('/notifications/read-all');
    } catch (e) {
      throw Exception('Gagal memperbarui notifikasi.');
    }
  }
}
