import 'dart:convert';
import 'api_service.dart';

class StoreService {
  static Future<List<dynamic>> getStores() async {
    final response = await ApiService.get('stores');

    dynamic decoded;

    try {
      decoded = json.decode(response.body);
    } catch (_) {
      throw Exception(
        'Respons server bukan JSON yang valid (${response.statusCode}).',
      );
    }

    if (response.statusCode == 200) {
      if (decoded is Map && decoded['data'] is List) {
        return List<dynamic>.from(decoded['data']);
      }

      throw Exception('Format data cabang dari server tidak sesuai.');
    }

    final message = decoded is Map
        ? decoded['message'] ??
            (decoded['messages'] is Map
                ? decoded['messages']['error']
                : null)
        : null;

    throw Exception(
      message?.toString() ??
          'Gagal memuat daftar cabang (${response.statusCode}).',
    );
  }

  static Future<void> createStore(Map<String, dynamic> data) async {
    final response = await ApiService.post('stores', data);
    final resData = json.decode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        resData['message'] ?? 'Gagal membuat cabang',
      );
    }
  }

  static Future<void> updateCurrentStore(
    Map<String, dynamic> data,
  ) async {
    final response = await ApiService.put('stores/current', data);

    if (response.statusCode != 200) {
      throw Exception('Gagal memperbarui profil toko');
    }
  }
}