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

  Future<void> savePaymentMethod(Map<String, dynamic> data, {int? id, File? imageFile}) async {
    try {
      FormData formData = FormData.fromMap(data);

      // Jika ada file gambar yang dipilih, tambahkan ke FormData
      if (imageFile != null) {
        formData.files.add(MapEntry(
          'qris_image',
          await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
        ));
      }

      Response response;
      if (id == null) {
        response = await _dio.post('/payment-methods', data: formData);
      } else {
        // Trik khusus untuk CodeIgniter: Gunakan POST tapi beri tahu CI4 bahwa ini adalah PUT
        formData.fields.add(const MapEntry('_method', 'PUT')); 
        response = await _dio.post('/payment-methods/$id', data: formData);
      }
          
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
