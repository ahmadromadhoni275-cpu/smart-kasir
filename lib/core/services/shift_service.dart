import 'package:dio/dio.dart';
import '../network/api_client.dart';

class ShiftService {
  final Dio _dio = ApiClient().dio;

  // 1. Cek Shift Aktif
  Future<Map<String, dynamic>?> getCurrentShift() async {
    try {
      final response = await _dio.get('/shifts/current');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return response.data['data']; // Mengembalikan data shift jika OPEN
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null; // 404 berarti belum ada shift buka
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat status shift');
    }
  }

  // 2. Buka Shift
  Future<void> openShift(double openingCash, String notes) async {
    try {
      await _dio.post('/shifts/open', data: {
        'opening_cash': openingCash,
        'notes': notes,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal membuka shift');
    }
  }

  // 3. Kas Masuk / Keluar
  Future<void> recordCashMovement(String type, double amount, String description) async {
    try {
      String endpoint = type == 'CASH_IN' ? '/shifts/cash-in' : '/shifts/cash-out';
      await _dio.post(endpoint, data: {
        'amount': amount,
        'description': description,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mencatat pergerakan kas');
    }
  }

  // 4. Tutup Shift
  Future<Map<String, dynamic>> closeShift(double actualCash, String notes) async {
    try {
      final response = await _dio.post('/shifts/close', data: {
        'actual_cash': actualCash,
        'notes': notes,
      });
      return response.data['data'] ?? {};
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menutup shift');
    }
  }
}
