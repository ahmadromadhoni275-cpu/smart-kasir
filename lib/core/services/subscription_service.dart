import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/subscription_model.dart';

class SubscriptionService {
  final Dio _dio = ApiClient().dio;

  Future<List<PlanModel>> getAvailablePlans() async {
    try {
      final response = await _dio.get('/subscriptions/plans');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List data = response.data['data'] ?? [];
        return data.map((e) => PlanModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat daftar paket.');
    }
  }

  Future> getCheckoutInfo(int planId) async {
    try {
      final response = await _dio.get('/subscriptions/checkout-info/$planId');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data['data'];
      }
      throw Exception('Gagal memuat info checkout.');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan saat checkout.');
    }
  }

  Future> createPayment(int planId) async {
    try {
      final response = await _dio.post('/subscriptions/create-payment', data: {'plan_id': planId});
      if (response.statusCode == 201 && response.data['status'] == 'success') {
        return response.data['data'];
      }
      throw Exception('Gagal membuat tagihan.');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan.');
    }
  }
}
