import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReferralService {
  final String baseUrl = 'https://smartkasir.shop/api/referral';

  Future<Map<String, dynamic>> getSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
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
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Gagal memuat ringkasan referral');
    }
  }

  Future<List<dynamic>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
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
      return json.decode(response.body)['data'] ?? [];
    } else {
      throw Exception('Gagal memuat riwayat referral');
    }
  }
  
  Future<Map<String, dynamic>> getRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/rewards'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Gagal memuat hadiah referral');
    }
  }

  Future<void> claimReward(String rewardId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

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
