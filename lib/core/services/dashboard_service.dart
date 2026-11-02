import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/dashboard_model.dart';

class DashboardService {
  final Dio _dio = ApiClient().dio;

  Future<DashboardModel> getDashboardData() async {
    try {
      final response = await _dio.get('/dashboard');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        return DashboardModel.fromJson(response.data['data']);
      }
      throw Exception('Format respon tidak sesuai standar.');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Terjadi kesalahan jaringan saat memuat dashboard.');
    } catch (e) {
      throw Exception('Gagal memproses data dashboard: $e');
    }
  }
}
