import 'dart:convert';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/store_setting_model.dart';

class StoreSettingService {
  static final Dio _dio = ApiClient().dio;

  static Future<StoreSettingModel> getSettings() async {
    try {
      final response = await _dio.get('/stores/current/settings');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return StoreSettingModel.fromJson(response.data['data']);
      }
      throw Exception('Format respons tidak valid');
    } on DioException catch (e) {
      String errorMsg = 'Gagal memuat pengaturan toko';
      if (e.response != null && e.response?.data is Map) {
         errorMsg = e.response?.data['message'] ?? e.response?.data['messages']?.toString() ?? errorMsg;
      } else if (e.message != null) {
         errorMsg = e.message!;
      }
      throw Exception(errorMsg);
    }
  }

  static Future<void> updateSettings(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/stores/current/settings', data: data);
      if (response.statusCode != 200 || response.data['status'] != 'success') {
        throw Exception(response.data['message'] ?? 'Gagal memperbarui pengaturan');
      }
    } on DioException catch (e) {
      // PERBAIKAN: Ekstrak pesan error asli secara dinamis agar tidak ditutupi "kesalahan jaringan"
      String errorMsg = 'Terjadi kesalahan jaringan';
      if (e.response != null && e.response?.data is Map) {
         errorMsg = e.response?.data['message'] ?? e.response?.data['messages']?.toString() ?? errorMsg;
      } else if (e.message != null) {
         errorMsg = e.message!;
      }
      throw Exception(errorMsg);
    }
  }
}
