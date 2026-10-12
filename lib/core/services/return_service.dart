import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/return_model.dart';

class ReturnService {
  final Dio _dio = ApiClient().dio;

  // Mengambil daftar histori retur
  Future<List<ReturnData>> getReturns({String search = ''}) async {
    try {
      final response = await _dio.get('/returns', queryParameters: {'search': search});
      if (response.statusCode == 200 && response.data['status'] == true) {
        List data = response.data['data'] ?? [];
        return data.map((e) => ReturnData.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat data retur');
    }
  }

  // Mengambil barang yang masih bisa diretur dari sebuah transaksi
  Future<List<ReturnItem>> getReturnableItems(int transactionId) async {
    try {
      final response = await _dio.get('/transactions/$transactionId/returnable-items');
      if (response.statusCode == 200 && response.data['status'] == true) {
        List items = response.data['data']['items'] ?? [];
        return items.map((e) => ReturnItem.fromJson(e)).toList();
      }
      throw Exception('Gagal memuat barang retur');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }

  // Mengirim pengajuan retur
  Future<Map<String, dynamic>> createReturn(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('/returns', data: payload);
      if (response.statusCode == 201 && response.data['status'] == true) {
        return response.data['data'];
      }
      throw Exception('Gagal menyimpan retur');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memproses retur ke server');
    }
  }

  // Mengambil detail retur spesifik
  Future<Map<String, dynamic>> getReturnDetail(int returnId) async {
    try {
      final response = await _dio.get('/returns/$returnId');
      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data['data'];
      }
      throw Exception('Gagal memuat detail retur');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan');
    }
  }
}
