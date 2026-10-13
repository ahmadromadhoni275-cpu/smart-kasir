import 'package:dio/dio.dart';
import '../network/api_client.dart';

class ReportService {
  final Dio _dio = ApiClient().dio;

  // Memanggil endpoint GET /reports untuk ringkasan (Summary)
  Future<Map<String, dynamic>> getSummary(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports',
        queryParameters: {
          'date_from': dateFrom,
          'date_to': dateTo,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data['data']; 
      }
      throw Exception('Gagal memuat ringkasan laporan');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
    // Memanggil endpoint GET /reports/sales untuk Laporan Penjualan
  Future<List<dynamic>> getSales(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports/sales',
        queryParameters: {
          'date_from': dateFrom,
          'date_to': dateTo,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data['data'] ?? [];
      }
      throw Exception('Gagal memuat laporan penjualan');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // (Nanti tambahkan fungsi getSales, getPayments, dll di sini saat sub-halaman dibangun)
  // Memanggil endpoint GET /reports/payments
  Future<List<dynamic>> getPayments(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports/payments',
        queryParameters: {
          'date_from': dateFrom,
          'date_to': dateTo,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data['data'] ?? [];
      }
      throw Exception('Gagal memuat laporan pembayaran');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

}
