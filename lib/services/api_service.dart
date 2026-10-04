import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Ganti dengan URL utama API Anda
  static const String baseUrl = 'https://smartkasir.shop/api';

  // =================================================================
  // 1. FUNGSI PEMBUAT HEADER OTOMATIS (Menyisipkan Kredensial RBAC)
  // =================================================================
    static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final int storeId = prefs.getInt('store_id') ?? 0;
    
    // AMBIL TOKEN DARI SESI LOGIN
    final String token = prefs.getString('jwt_token') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Kirim Token ke Satpam CI4
      'X-Store-Id': storeId.toString(), // Kasih tau CI4 toko mana yang mau dibuka
      
      // KITA SUDAH TIDAK MENGIRIM X-User-Id LAGI!
      // Biarkan Backend yang mencari tau siapa user-nya dari dalam token JWT.
    };
  }

  // =================================================================
  // 2. PEMBUNGKUS METHOD POST (Bisa Dipakai Berkali-kali)
  // =================================================================
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/$endpoint');
    
    return await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );
  }

  // =================================================================
  // 3. PEMBUNGKUS METHOD GET (Bisa Dipakai Berkali-kali)
  // =================================================================
  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$baseUrl/$endpoint');
    
    return await http.get(url, headers: headers);
  }

  // Anda bisa menambahkan method PUT dan DELETE di sini jika diperlukan
}
