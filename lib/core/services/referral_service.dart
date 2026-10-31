import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReferralService {
  final String baseUrl = 'https://smartkasir.shop/api/referral';

  Future> getSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? ''; // Pastikan key token Anda benar ('jwt_token' atau 'token')
    final storeId = prefs.getInt('store_id')?.toString() ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/summary'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Store-Id': storeId,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      if (res['status'] == 'success' || res['status'] == true) {
         return res['data'];
      }
      throw Exception(res['message'] ?? 'Gagal memuat ringkasan referral');
    } else {
      throw Exception('Gagal memuat: Server mengembalikan status ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? ''; 
    final storeId = prefs.getInt('store_id')?.toString() ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-Store-Id': storeId,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      if (res['status'] == 'success' || res['status'] == true) {
         return res['data'] ?? [];
      }
      throw Exception(res['message'] ?? 'Gagal memuat riwayat referral');
    } else {
      throw Exception('Gagal memuat riwayat referral');
    }
  }
  
  Future> getRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/rewards'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      if (res['status'] == 'success' || res['status'] == true) {
         return res['data'];
      }
      throw Exception(res['message'] ?? 'Gagal memuat hadiah referral');
    } else {
      throw Exception('Gagal memuat hadiah referral');
    }
  }

  Future<void> claimReward(String rewardId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/rewards/$rewardId/claim'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode != 201) {
      final res = json.decode(response.body);
      throw Exception(res['message'] ?? 'Gagal mengklaim hadiah');
    }
  }
}
