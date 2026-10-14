import 'dart:convert';
import 'api_service.dart';

class StoreService {
  static Future<List<dynamic>> getStores() async {
    final response = await ApiService.get('stores');
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    throw Exception('Gagal memuat daftar cabang');
  }

  static Future<void> createStore(Map<String, dynamic> data) async {
    final response = await ApiService.post('stores', data);
    final resData = json.decode(response.body);
    if (response.statusCode != 201) {
      throw Exception(resData['message'] ?? 'Gagal membuat cabang');
    }
  }

  static Future<void> updateCurrentStore(Map<String, dynamic> data) async {
    final response = await ApiService.put('stores/current', data);
    if (response.statusCode != 200) {
      throw Exception('Gagal memperbarui profil toko');
    }
  }
}
