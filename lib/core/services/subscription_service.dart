import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/plan_model.dart';
import '../../models/subscription_model.dart';
import '../../models/payment_history_model.dart';

class SubscriptionService {
  final Dio _dio = ApiClient().dio;

  Future<SubscriptionModel> getCurrentSubscription() async {
    try {
      final response = await _dio.get('/subscriptions/current');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return SubscriptionModel.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Gagal memuat langganan.');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan.');
    }
  }

  Future<List<PlanModel>> getAvailablePlans() async {
    try {
      final response = await _dio.get('/plans');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List data = response.data['data'] ?? [];
        return data.map((e) => PlanModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat daftar paket.');
    }
  }

  Future<List<PaymentHistoryModel>> getHistory() async {
    try {
      final response = await _dio.get('/subscriptions/history');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List data = response.data['data'] ?? [];
        return data.map((e) => PaymentHistoryModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan memuat riwayat.');
    }
  }

  Future<dynamic> getCheckoutInfo(int planId) async {
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

  Future<void> createPayment(int planId) async {
    try {
      final response = await _dio.post('/subscriptions/create-payment', data: {'plan_id': planId});
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Gagal membuat tagihan.');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan membuat tagihan.');
    }
  }
}
