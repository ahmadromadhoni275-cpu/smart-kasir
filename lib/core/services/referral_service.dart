import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/referral_model.dart';

class ReferralService {
  // Menggunakan ApiClient yang sudah mengatur Token JWT secara otomatis
  final Dio _dio = ApiClient().dio;

  Future<ReferralSummaryModel> getSummary() async {
    try {
      final response = await _dio.get('/referral/summary');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
         // Data dari API langsung diubah menjadi Model (Bukan dynamic lagi)
         return ReferralSummaryModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memuat ringkasan referral');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan saat memuat data');
    }
  }

  Future<List<dynamic>> getHistory() async {
    try {
      final response = await _dio.get('/referral/history');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
         return response.data['data'] ?? [];
      }
      throw Exception('Gagal memuat riwayat referral');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan');
    }
  }
  
  Future<dynamic> getRewards() async {
    try {
      final response = await _dio.get('/referral/rewards');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
         return response.data['data'];
      }
      throw Exception('Gagal memuat hadiah referral');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan');
    }
  }

  Future<void> claimReward(String rewardId) async {
    try {
      final response = await _dio.post('/referral/rewards/$rewardId/claim');
      
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Gagal mengklaim hadiah');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan saat mengklaim');
    }
  }
}
