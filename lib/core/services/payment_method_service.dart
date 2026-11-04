import 'package:dio/dio.dart';
import '../network/api_client.dart';

class PaymentMethodService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getPaymentMethods() async {
    try {
      final response = await _dio.get('/payment-methods');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data['data'] ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat metode pembayaran');
    }
  }

  Future<void> savePaymentMethod(Map<String, dynamic> data, {int? id}) async {
    try {
      final response = id == null 
          ? await _dio.post('/payment-methods', data: data)
          : await _dio.put('/payment-methods/$id', data: data);
          
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Gagal menyimpan metode pembayaran');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  Future<void> toggleStatus(int id, String newStatus) async {
    try {
      final response = await _dio.patch('/payment-methods/$id/status', data: {'status': newStatus});
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Gagal mengubah status');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  Future<void> deletePaymentMethod(int id) async {
    try {
      final response = await _dio.delete('/payment-methods/$id');
      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Gagal menghapus metode pembayaran');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
}
