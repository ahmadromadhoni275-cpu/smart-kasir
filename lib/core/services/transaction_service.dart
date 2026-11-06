import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_detail_model.dart';

class TransactionService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getTransactions({
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
        // Fallback aman jika backend tidak mengirim pagination
        final pagination = data['pagination'] ?? {'total_pages': 1, 'current_page': 1};
        
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
  
  Future<TransactionDetailModel> getTransactionDetail(int transactionId) async {
    try {
      final response = await _dio.get('/transactions/$transactionId');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return TransactionDetailModel.fromJson(response.data['data']); 
      }
      throw Exception('Gagal memuat detail transaksi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  Future<dynamic> createTransaction(Map<String, dynamic> data) async {
    try {
      // 1. Lakukan Checkout
      final response = await _dio.post('/transactions', data: data);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data['data'] ?? {};
        final int transactionId = int.tryParse(responseData['transaction_id'].toString()) ?? 0;
        
        // 2. AMBIL DATA STRUK LENGKAP UNTUK PRINTER
        // Jika sukses, kita panggil GET detail agar data cetak struk super lengkap
        if (transactionId > 0) {
          try {
            final detailResponse = await _dio.get('/transactions/$transactionId');
            if (detailResponse.statusCode == 200 && detailResponse.data['status'] == 'success') {
              // Mengembalikan objek 'receipt' dari backend yang sudah sangat rapi
              return detailResponse.data['data']['receipt'] ?? responseData;
            }
          } catch (_) {
            // Jika gagal ambil detail, kembalikan data seadanya (tidak merusak flow bayar)
            return responseData;
          }
        }
        return responseData;
      }
      throw Exception('Gagal memproses transaksi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  Future<void> cancelTransaction(int transactionId) async {
    try {
      final response = await _dio.post('/transactions/$transactionId/cancel');
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Gagal membatalkan transaksi');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
}
