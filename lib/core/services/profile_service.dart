import 'dart:convert';
import 'api_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile() async {
    final response = await ApiService.get('profile');
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    throw Exception('Gagal memuat data profil');
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.put('profile', data);
    final resData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(resData['message'] ?? 'Gagal memperbarui profil');
    }
  }

  static Future<void> changePassword(String oldPassword, String newPassword) async {
    final response = await ApiService.post('profile/change-password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    final resData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(resData['message'] ?? 'Gagal mengubah kata sandi');
    }
  }

  static Future<void> logout() async {
    try {
      await ApiService.post('auth/logout', {});
    } catch (e) {
      // Abaikan error jaringan saat logout, yang penting sesi lokal terhapus
    }
  }
}
