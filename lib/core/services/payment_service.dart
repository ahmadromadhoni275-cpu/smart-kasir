import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/payment_method_model.dart';

class PaymentService {
  final Dio _dio = ApiClient().dio;

  Future<List<PaymentMethodModel>> getActiveMethods() async {
    try {
      final response = await _dio.get('/payments/methods/active');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        List data = response.data['data'] ?? [];
        return data.map((e) => PaymentMethodModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat metode pembayaran.');
    }
  }
}
