import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/report_model.dart';
import '../../models/stock_movement_model.dart'; // Digunakan untuk laporan stok

class ReportService {
  final Dio _dio = ApiClient().dio;

  bool _isSuccess(dynamic status) {
    return status == 'success' || status == true;
  }

  // 1. Ringkasan (Summary) - Dikonsumsi oleh halaman_laporan.dart
  Future<dynamic> getSummary(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get('/reports', queryParameters: {'date_from': dateFrom, 'date_to': dateTo});
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? {}; 
      }
      throw Exception('Gagal memuat ringkasan laporan');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  // 2. Laporan Penjualan
  Future<List<SalesReportItem>> getSales(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get('/reports/sales', queryParameters: {'date_from': dateFrom, 'date_to': dateTo});
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        List data = response.data['data'] ?? [];
        return data.map((e) => SalesReportItem.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // 3. Laporan Transaksi Lengkap (Pagination)
  Future> getTransactions({
    required String dateFrom, 
    required String dateTo, 
    String status = '', 
    String search = '', 
    int page = 1, 
    int perPage = 20
  }) async {
    try {
      final response = await _dio.get(
        '/reports/transactions',
        queryParameters: {
          'date_from': dateFrom, 'date_to': dateTo, 'status': status,
          'search': search, 'page': page, 'per_page': perPage,
        },
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data;
      }
      throw Exception('Gagal memuat data transaksi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // 4. Laporan Produk Terjual
  Future<ProductReportData> getProductSales(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get('/reports/products', queryParameters: {'date_from': dateFrom, 'date_to': dateTo});
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return ProductReportData.fromJson(response.data['data'] ?? {});
      }
      throw Exception('Gagal memuat laporan produk');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // 5. Laporan Pembayaran
  Future<List<PaymentReportItem>> getPayments(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get('/reports/payments', queryParameters: {'date_from': dateFrom, 'date_to': dateTo});
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        List data = response.data['data'] ?? [];
        return data.map((e) => PaymentReportItem.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  // 6. Laporan Laba Rugi
  Future<ProfitLossData> getProfitLoss(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get('/reports/profit-loss', queryParameters: {'date_from': dateFrom, 'date_to': dateTo});
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return ProfitLossData.fromJson(response.data['data'] ?? {});
      }
      throw Exception('Gagal memuat laporan laba rugi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  // 7. Laporan Stok Terkini
  Future<List<dynamic>> getStockReport() async {
    try {
      final response = await _dio.get('/reports/stock');
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // 8. Laporan Riwayat Pergerakan Stok
  Future<List<StockMovementModel>> getStockMovements(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get('/reports/stock-movements', queryParameters: {'date_from': dateFrom, 'date_to': dateTo});
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        List data = response.data['data'] ?? [];
        return data.map((e) => StockMovementModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  // 9. Laporan Shift
  Future<List<dynamic>> getShifts(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get('/reports/shifts', queryParameters: {'date_from': dateFrom, 'date_to': dateTo});
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        return response.data['data'] ?? [];
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
  
  // 10. Laporan Pengembalian (Retur)
  Future<List<ReturnReportItem>> getReturns(String dateFrom, String dateTo) async {
    try {
      final response = await _dio.get('/reports/returns', queryParameters: {'date_from': dateFrom, 'date_to': dateTo});
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        List data = response.data['data'] ?? [];
        return data.map((e) => ReturnReportItem.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
}
