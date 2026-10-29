import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationApiService {
  // TODO: Sesuaikan dengan URL Base backend Anda
  final String baseUrl = 'https://smartkasir.shop/api/notifications';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Mengambil daftar notifikasi dan jumlah yang belum dibaca
  Future<Map<String, dynamic>> getNotifications() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Gagal memuat notifikasi');
  }

  // Menandai satu notifikasi telah dibaca
  Future<void> markAsRead(int id) async {
    final headers = await _getHeaders();
    await http.put(Uri.parse('$baseUrl/read/$id'), headers: headers);
  }

  // Menandai semua notifikasi telah dibaca
  Future<void> markAllAsRead() async {
    final headers = await _getHeaders();
    await http.put(Uri.parse('$baseUrl/read/all'), headers: headers);
  }
}
