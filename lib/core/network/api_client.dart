import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                                                                                                            @override
                                                                                                              void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
                                                                                                                  final prefs = await SharedPreferences.getInstance();
                                                                                                                      
                                                                                                                          // Ambil token dan store_id yang disimpan saat Login
                                                                                                                              final token = prefs.getString('token');
                                                                                                                                  final storeId = prefs.getString('store_id'); 

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
                                                                                                                                                                                // Anda bisa memodifikasi atau me-log response global di sini
                                                                                                                                                                                    return super.onResponse(response, handler);
                                                                                                                                                                                      }

                                                                                                                                                                                        @override
                                                                                                                                                                                          void onError(DioException err, ErrorInterceptorHandler handler) {
                                                                                                                                                                                              // Tangani error global, misalnya jika token kedaluwarsa (401)
                                                                                                                                                                                                  if (err.response?.statusCode == 401) {
                                                                                                                                                                                                        // TODO: Implementasi logika Auto-Logout dan navigasi ke halaman Login
                                                                                                                                                                                                              print('Token Expired atau Unauthorized. Harap Login Ulang.');
                                                                                                                                                                                                                  }
                                                                                                                                                                                                                      
                                                                                                                                                                                                                          return super.onError(err, handler);
                                                                                                                                                                                                                            }
                                                                                                                                                                                                                            }
                                                                                                                                                                                                                            