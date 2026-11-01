import 'package:dio/dio.dart';
import '../network/api_client.dart';

class ReportService {
  final Dio _dio = ApiClient().dio;

  // Helper untuk mengecek status aman (Bisa String 'success' atau Boolean true)
  bool _isSuccess(dynamic status) {
    return status == 'success' || status == true;
  }

  // 1. Ringkasan (Summary)
  Future<dynamic> getSummary(String dateFrom, String dateTo) async {
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
  
  // 2. Laporan Penjualan (Data Mentah)
  Future<dynamic> getSales(String dateFrom, String dateTo) async {
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

  // 3. FITUR BARU: Laporan Transaksi Lengkap (Dengan Pagination & Filter dari CI4)
  Future<dynamic> getTransactions({
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
          'date_from': dateFrom,
          'date_to': dateTo,
          'status': status,
          'search': search,
          'page': page,
          'per_page': perPage,
        },
      );
      if (response.statusCode == 200 && _isSuccess(response.data['status'])) {
        // Mengembalikan seluruh response (termasuk meta pagination) bukan hanya 'data'
        return response.data;
      }
      throw Exception('Gagal memuat data transaksi');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // 4. Laporan Produk Terjual
  Future<dynamic> getProductSales(String dateFrom, String dateTo) async {
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

  // 5. Laporan Pembayaran (Metode Kas)
  Future<dynamic> getPayments(String dateFrom, String dateTo) async {
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
  
  // 6. Laporan Laba Rugi (Profit & Loss)
  Future<dynamic> getProfitLoss(String dateFrom, String dateTo) async {
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
  
  // 7. Laporan Stok Terkini
  Future<dynamic> getStockReport() async {
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

  // 8. Laporan Riwayat Pergerakan Stok
  Future<dynamic> getStockMovements(String dateFrom, String dateTo) async {
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
  
  // 9. Laporan Riwayat Shift Kasir
  Future<dynamic> getShifts(String dateFrom, String dateTo) async {
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
  
  // 10. Laporan Pengembalian (Retur)
  Future<dynamic> getReturns(String dateFrom, String dateTo) async {
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
