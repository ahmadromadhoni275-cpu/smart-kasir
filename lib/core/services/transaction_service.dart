import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/transaction_model.dart';

class TransactionService {
  final Dio _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getTransactions({
    required String dateFrom,
    required String dateTo,
    int page = 1,
    int perPage = 20,
    String status = '',
    String search = '',
  }) async {
    try {
      final response = await _dio.get(
        '/transactions',
        queryParameters: {
          'date_from': dateFrom,
          'date_to': dateTo,
          'page': page,
          'limit': perPage,
          'status': status,
          'search': search,
        },
      );

      final data = response.data;
      if (response.statusCode == 200) {
        final List records = data['data'] ?? [];
        final pagination = data['pagination'] ?? {};
        
        return {
          'transactions': records.map((e) => TransactionReport.fromJson(e)).toList(),
          'total_pages': pagination['total_pages'] ?? 1,
          'current_page': pagination['current_page'] ?? 1,
        };
      }
      throw Exception('Gagal memuat histori transaksi');
    } on DioException catch (e) {
      final errorMsg = e.response?.data['message'] ?? e.message ?? 'Terjadi kesalahan jaringan';
      throw Exception(errorMsg);
    }
  }
  
  Future<Map<String, dynamic>> getTransactionDetail(int transactionId) async {
    try {
      final response = await _dio.get('/transactions/$transactionId');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return response.data['data']; 
      }
      throw Exception('Gagal memuat detail transaksi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  Future<void> createTransaction(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/transactions', data: data);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal memproses transaksi');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

}
  