import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/return_model.dart'; // Pastikan path model ini sesuai dengan struktur Anda

class ReturnService {
  final Dio _dio = ApiClient().dio;

  // 1. Mendapatkan daftar item yang BISA diretur dari sebuah transaksi
  Future< List< ReturnItem > > getReturnableItems(int transactionId) async {
    try {
      // Menyesuaikan dengan standar endpoint RESTful Anda
      final response = await _dio.get('/transactions/$transactionId/returnable-items');
      
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == true)) {
        List data = response.data['data'] ?? [];
        return data.map((e) => ReturnItem.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat barang yang bisa diretur.');
    }
  }

  // 2. Mengirim data pengajuan retur baru
  Future< Map<String, dynamic> > createReturn(Map<String, dynamic> payload) async {
    try {
      final response = await _dio.post('/returns', data: payload);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mengembalikan Map utuh agar UI bisa mengambil 'return_number'
        return response.data['data'] ?? response.data; 
      }
      throw Exception('Gagal memproses pengajuan retur.');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan.');
    }
  }
  
  // 3. Mendapatkan daftar riwayat retur (Jika dibutuhkan untuk halaman riwayat retur)
  Future< Map<String, dynamic> > getReturns({
    int page = 1, 
    int perPage = 20, 
    String search = ''
  }) async {
    try {
      final response = await _dio.get(
        ('/returns'),
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'search': search,
        }
      );
      
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == true)) {
        return <String, dynamic>{
          'returns': response.data['data'] ?? [],
          'total_pages': response.data['meta']?['last_page'] ?? 1,
        };
      }
      throw Exception('Gagal memuat riwayat retur.');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan saat memuat data.');
    }
  }
}
