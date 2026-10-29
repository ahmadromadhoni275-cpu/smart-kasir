import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

class FcmService {
  // Panggil fungsi ini tepat SETELAH kasir/owner berhasil Login
  static Future<void> registerDeviceToken() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 1. Minta Izin
      NotificationSettings settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

      // 2. Ambil Token FCM
      String? fcmToken = await messaging.getToken();
      if (fcmToken == null) return;

      // 3. Identifikasi Perangkat
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = 'unknown';
      String deviceName = 'Mobile Device';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; 
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios';
        deviceName = iosInfo.name;
      }

      // 4. Kirim ke API CI4
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token') ?? '';

      // TODO: Sesuaikan baseUrl API Anda
      final url = Uri.parse('https://smartkasir.shop/api/profile/save-fcm-token');
      
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'device_id': deviceId,
          'fcm_token': fcmToken,
          'device_name': deviceName,
        }),
      );
      
      print("FCM Token berhasil diregistrasi di server.");
    } catch (e) {
      print("Gagal registrasi FCM Token: $e");
    }
  }
}
