import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/faq_model.dart';

class HelpService {
  final Dio _dio = ApiClient().dio;

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get('/support/conversations');
      if (response.statusCode == 200) return response.data['data'] ?? [];
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat percakapan');
    }
  }

  Future<int> startConversation() async {
    try {
      final response = await _dio.post('/support/conversations');
      if (response.statusCode == 201) return response.data['conversation_id'];
      throw Exception('Gagal membuat percakapan baru');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan');
    }
  }

  Future<List<dynamic>> getMessages(int conversationId) async {
    try {
      final response = await _dio.get('/support/conversations/$conversationId/messages');
      if (response.statusCode == 200) return response.data['data'] ?? [];
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat riwayat pesan');
    }
  }

  Future<dynamic> sendMessage(int conversationId, String text) async {
    try {
      final response = await _dio.post('/support/conversations/$conversationId/messages', data: {'message': text});
      if (response.statusCode == 200) return response.data['data'];
      throw Exception('Gagal mengirim pesan');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menghubungi Smart Assist');
    }
  }

  Future<bool> submitFeedback(int messageId, int rating, {String comment = ''}) async {
    try {
      final response = await _dio.post('/support/messages/$messageId/feedback', data: {'rating': rating, 'comment': comment});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<FaqModel>> getFaqs() async {
    try {
      final response = await _dio.get('/support/faqs');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => FaqModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
