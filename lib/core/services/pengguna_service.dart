import 'dart:convert';
import 'api_service.dart';

class PenggunaService {
  static Future<List<dynamic>> getPengguna({String search = '', String role = ''}) async {
    final response = await ApiService.get('users?search=$search&role=$role');
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    throw Exception('Gagal memuat daftar pengguna');
  }

  static Future<void> invitePengguna(Map<String, dynamic> data) async {
    final response = await ApiService.post('users/invite', data);
    final resData = json.decode(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(resData['message'] ?? 'Gagal menambahkan pengguna');
    }
  }

  static Future<void> updateAkses(int userId, Map<String, dynamic> data) async {
    final response = await ApiService.put('users/$userId/access', data);
    final resData = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(resData['message'] ?? 'Gagal memperbarui akses');
    }
  }
}
