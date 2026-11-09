import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/user_model.dart';

class UserService {
  final Dio _dio = ApiClient().dio;

    Future<List<UserModel>> getUsers({String search = '', String role = ''}) async {
    try {
      final response = await _dio.get('/users', queryParameters: {
        'search': search,
        'role': role,
      });
      
      // PERBAIKAN 1: Dukung status 'success' (String) maupun true (Boolean)
      if (response.statusCode == 200 && (response.data['status'] == 'success' || response.data['status'] == true)) {
        List data = response.data['data'] ?? [];
        // PERBAIKAN 2: Tambahkan <UserModel> agar Dart tidak membacanya sebagai List<dynamic>
        return data.map<UserModel>((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      // PERBAIKAN 3: Bongkar pesan error asli dari backend (jangan disembunyikan)
      String errorMsg = 'Gagal memuat pengguna';
      if (e.response != null && e.response?.data is Map) {
         errorMsg = e.response?.data['message'] ?? e.response?.data['messages']?.toString() ?? errorMsg;
      } else if (e.message != null) {
         errorMsg = e.message!;
      }
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception('Error sistem: $e');
    }
  }

  Future<void> inviteUser(Map<String, dynamic> data) async {
    try {
      await _dio.post('/users/invite', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menambahkan pengguna');
    }
  }

  Future<void> updateAccess(int userId, Map<String, dynamic> data) async {
    try {
      await _dio.put('/users/access/$userId', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memperbarui akses');
    }
  }
}
