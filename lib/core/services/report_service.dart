import 'package:dio/dio.dart';
import '../network/api_client.dart';

class ReportService {
  final Dio _dio = ApiClient().dio;

  // Helper untuk mengecek status aman (Bisa String 'success' atau Boolean true)
  bool _isSuccess(dynamic status) {
    return status == 'success' || status == true;
  }

  // Memanggil endpoint GET /reports untuk ringkasan (Summary)
  Future> getSummary(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? {}; 
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
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? [];
      }
      throw Exception('Gagal memuat laporan penjualan');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // Memanggil endpoint GET /reports/products
  Future> getProductSales(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports/products',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? {'products': [], 'categories': []};
      }
      throw Exception('Gagal memuat laporan produk');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // Memanggil endpoint GET /reports/payments
  Future<List<dynamic>> getPayments(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports/payments',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? [];
      }
      throw Exception('Gagal memuat laporan pembayaran');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  // Memanggil endpoint GET /reports/profit-loss
  Future> getProfitLoss(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports/profit-loss',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? {};
      }
      throw Exception('Gagal memuat laporan laba rugi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  // GET /reports/stock (Stok Terkini)
  Future<List<dynamic>> getStockReport() async {
    try {
      final response = await _dio.get('/reports/stock');
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? [];
      }
      throw Exception('Gagal memuat laporan stok');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // GET /reports/stock-movements (Riwayat Pergerakan)
  Future<List<dynamic>> getStockMovements(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports/stock-movements',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? [];
      }
      throw Exception('Gagal memuat riwayat pergerakan stok');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  // Memanggil endpoint GET /reports/shifts
  Future<List<dynamic>> getShifts(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports/shifts',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? [];
      }
      throw Exception('Gagal memuat laporan shift');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  // Memanggil endpoint GET /reports/returns
  Future<List<dynamic>> getReturns(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get(
        '/reports/returns',
        queryParameters: {'date_from': dateFrom, 'date_to': dateTo},
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? [];
      }
      throw Exception('Gagal memuat laporan retur');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
}
