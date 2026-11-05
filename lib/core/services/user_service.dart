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
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        List data = response.data['data'] ?? [];
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat pengguna');
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
