import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

class AuthService {
  // Panggil instance Dio yang sudah kita pasangi Interceptor tadi
    final Dio _dio = ApiClient().dio;

      /// Fungsi untuk memproses Login
        Future<bool> login(String email, String password) async {
            try {
                  // 1. Kirim request POST ke endpoint login CodeIgniter
                        final response = await _dio.post(
                                '/login',
                                        data: {
                                                  'email': email,
                                                            'password': password,
                                                                    },
                                                                          );

                                                                                // 2. Jika sukses (HTTP 200), ekstrak data dari JSON
                                                                                      if (response.statusCode == 200 && response.data['status'] == 'success') {
                                                                                              final data = response.data;
                                                                                                      final token = data['token'];
                                                                                                              
                                                                                                                      // Ambil store_id dari array stores (kita ambil toko pertama sebagai default)
                                                                                                                              final stores = data['data']['stores'] as List;
                                                                                                                                      if (stores.isEmpty) {
                                                                                                                                                throw Exception('Akun ini tidak terdaftar di toko mana pun.');
                                                                                                                                                        }
                                                                                                                                                                final storeId = stores[0]['store_id'].toString();
                                                                                                                                                                        final userName = data['data']['name'];
                                                                                                                                                                                final role = stores[0]['role'];

                                                                                                                                                                                        // 3. Simpan Token dan Info User ke SharedPreferences
                                                                                                                                                                                                final prefs = await SharedPreferences.getInstance();
                                                                                                                                                                                                        await prefs.setString('token', token);
                                                                                                                                                                                                                await prefs.setString('store_id', storeId);
                                                                                                                                                                                                                        await prefs.setString('user_name', userName);
                                                                                                                                                                                                                                await prefs.setString('role', role);

                                                                                                                                                                                                                                        return true; // Login Berhasil
                                                                                                                                                                                                                                              }
                                                                                                                                                                                                                                                    return false;
                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                              } on DioException catch (e) {
                                                                                                                                                                                                                                                                    // Menangkap error dari API (misal password salah / HTTP 401)
                                                                                                                                                                                                                                                                          final errorMessage = e.response?.data['message'] ?? 'Gagal menghubungi server.';
                                                                                                                                                                                                                                                                                throw Exception(errorMessage);
                                                                                                                                                                                                                                                                                    } catch (e) {
                                                                                                                                                                                                                                                                                          // Menangkap error sistem lainnya
                                                                                                                                                                                                                                                                                                throw Exception('Terjadi kesalahan: $e');
                                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                                      }

                                                                                                                                                                                                                                                                                                        /// Fungsi untuk Logout
                                                                                                                                                                                                                                                                                                          Future<void> logout() async {
                                                                                                                                                                                                                                                                                                              final prefs = await SharedPreferences.getInstance();
                                                                                                                                                                                                                                                                                                                  await prefs.clear(); // Hapus semua data sesi (Token, Store ID, dll)
                                                                                                                                                                                                                                                                                                                    }

                                                                                                                                                                                                                                                                                                                      /// Fungsi untuk mengecek apakah user sudah login (berguna untuk auto-login saat buka aplikasi)
                                                                                                                                                                                                                                                                                                                        Future<bool> isLoggedIn() async {
                                                                                                                                                                                                                                                                                                                            final prefs = await SharedPreferences.getInstance();
                                                                                                                                                                                                                                                                                                                                final token = prefs.getString('token');
                                                                                                                                                                                                                                                                                                                                    return token != null && token.isNotEmpty;
                                                                                                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                                                                                                      }
                                                                                                                                                                                                                                                                                                                                      