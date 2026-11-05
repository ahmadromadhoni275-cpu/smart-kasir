import 'dart:convert';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/profile_model.dart';

class ProfileService {
  static final Dio _dio = ApiClient().dio;

  static Future<ProfileModel> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == true)) {
        return ProfileModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memuat data profil');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/profile', data: data);
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Gagal memperbarui profil');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  static Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.post('/profile/change-password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Gagal mengubah kata sandi');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  static Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Abaikan error jaringan saat logout, yang penting sesi lokal terhapus
    }
  }
}
