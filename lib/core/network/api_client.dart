import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart'; // Import navigatorKey dari main.dart
import '../../tema.dart'; // Import tema Anda
import '../../halaman_login.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;

  // Gunakan Singleton pattern agar instance Dio sama di seluruh aplikasi
  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://smartkasir.shop/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Tambahkan Interceptor untuk Token & Store ID
    dio.interceptors.add(AuthInterceptor());
  }
}

class AuthInterceptor extends Interceptor {
  // Flag agar popup tidak muncul tumpang tindih jika banyak API gagal bersamaan
  static bool _isSessionExpiredShowing = false; 

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil token dan store_id yang disimpan saat Login
    final token = prefs.getString('jwt_token'); 
    final storeId = prefs.getInt('store_id')?.toString(); 

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    if (storeId != null && storeId.isNotEmpty) {
      options.headers['X-Store-Id'] = storeId;
    }

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Tangani error global jika token kedaluwarsa (401)
    if (err.response?.statusCode == 401) {
      debugPrint('Token Expired atau Unauthorized. Memicu Auto-Logout.');
      _prosesLogoutOtomatis();
    }
    
    return super.onError(err, handler);
  }

  // ========================================================
  // LOGIKA POPUP & LOGOUT OTOMATIS
  // ========================================================
  static void _prosesLogoutOtomatis() async {
    if (_isSessionExpiredShowing) return;
    _isSessionExpiredShowing = true;

    // 1. Bersihkan semua sesi dari memori perangkat
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 2. Ambil konteks UI secara global (melewati Batasan State)
    // Pastikan navigatorKey di main.dart tidak bersifat private (tanpa underscore '_')
    // Pada file main.dart Anda, navigatorKey sudah berada di dalam class State _SmartKasirAppState,
    // yang berarti tidak bisa diakses dari luar. 
    // KITA AKAN PERBAIKI INI DI LANGKAH SELANJUTNYA.
    final context = navigatorKey.currentContext; 
    if (context == null) {
      _isSessionExpiredShowing = false;
      return;
    }

    // 3. Tampilkan Popup Cantik
    showDialog(
      context: context,
      barrierDismissible: false, // Wajib diklik tombolnya
      builder: (ctx) => PopScope(
        canPop: false, // Cegah tombol back fisik di HP
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: AppColors.shadowBlue, blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_clock_outlined, color: Colors.orange, size: 48),
                ),
                const SizedBox(height: 24),
                
                const Text('Sesi Berakhir', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.navyActive)),
                const SizedBox(height: 12),
                
                const Text(
                  'Masa aktif sesi Anda telah habis demi keamanan data toko. Silakan masuk kembali untuk melanjutkan pekerjaan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.smartBlue, // Sesuai tema aplikasi Anda
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      _isSessionExpiredShowing = false;
                      // Hapus semua tumpukan rute UI dan arahkan kembali ke Halaman Login
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HalamanLogin()),
                        (route) => false,
                      );
                    },
                    child: const Text('Login Ulang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
