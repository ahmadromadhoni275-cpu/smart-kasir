import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../network/api_client.dart';

class AuthService {
  // Panggil instance Dio yang sudah kita pasangi Interceptor
  final Dio _dio = ApiClient().dio;

  /// Fungsi untuk memproses Login
  Future<bool> login(String email, String password) async {
    try {
      // 1. Siapkan Info Perangkat & Token FCM
      String? fcmToken;
      String deviceName = 'Perangkat Tidak Dikenal';
      String deviceId = 'unknown_device';

      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          deviceName = '${androidInfo.brand} ${androidInfo.model}';
          deviceId = androidInfo.id; 
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          deviceName = iosInfo.name;
          deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
        }
      } catch (e) {
        print('Gagal mengambil info perangkat/FCM: $e'); // Abaikan agar login tetap jalan
      }

      // 2. Kirim request POST ke endpoint login API dengan data tambahan
      final response = await _dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          'fcm_token': fcmToken,
          'device_name': deviceName,
          'device_id': deviceId,
        },
      );

      // 3. Jika sukses (HTTP 200), ekstrak data dari JSON
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data;
        final token = data['token'];
                
        // Ambil store_id dari array stores 
        final stores = data['data']['stores'] as List;
        if (stores.isEmpty) {
          throw Exception('Akun ini tidak terdaftar di toko mana pun.');
        }
        
        final storeId = stores[0]['store_id'].toString();
        final userName = data['data']['name'];
        final role = stores[0]['role'];

        // 4. Simpan Token dan Info User ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        
        // PENTING: Gunakan 'jwt_token' agar selaras dengan AuthChecker & Interceptor
        await prefs.setString('jwt_token', token);
        await prefs.setString('token', token); // Cadangan
        
        await prefs.setInt('store_id', int.parse(storeId));
        await prefs.setString('user_name', userName);
        await prefs.setString('role', role);
        await prefs.setBool('is_logged_in', true);

        return true; 
      }
      return false;
      
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Gagal menghubungi server.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Fungsi untuk Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
  }

  /// Fungsi untuk mengecek status login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }
}
