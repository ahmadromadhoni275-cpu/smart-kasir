import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/category_model.dart';

class CategoryService {
  final Dio _dio = ApiClient().dio;

  Future<List<Category>> getCategories({String search = ''}) async {
    try {
      final response = await _dio.get('/categories', queryParameters: {'search': search});
      if (response.statusCode == 200 && response.data['status'] == true) {
        List data = response.data['data'] ?? [];
        return data.map((e) => Category.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat kategori');
    }
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    try {
      await _dio.post('/categories', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menambah kategori');
    }
  }

  Future<void> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/categories/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengubah kategori');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete('/categories/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menghapus kategori');
    }
  }
}
