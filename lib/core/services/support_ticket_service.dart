import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../../models/support_ticket_model.dart';
import '../../models/support_reply_model.dart';

class SupportTicketService {
  final Dio _dio = ApiClient().dio;

  Future<List<SupportTicketModel>> getTickets() async {
    try {
      final response = await _dio.get('/support/tickets');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final List data = response.data['data'] ?? [];
        return data.map((e) => SupportTicketModel.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal memuat daftar tiket');
    }
  }

  Future<int> createTicket(String subject, String description, String priority) async {
    try {
      final response = await _dio.post('/support/tickets', data: {
        'subject': subject, 'description': description, 'priority': priority
      });
      if (response.statusCode == 201) return response.data['ticket_id'];
      throw Exception('Gagal membuat tiket');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan');
    }
  }

  Future<dynamic> getTicketDetail(int ticketId) async {
    try {
      final response = await _dio.get('/support/tickets/$ticketId');
      if (response.statusCode == 200) {
        return {
          'ticket': SupportTicketModel.fromJson(response.data['data']['ticket']),
          'messages': (response.data['data']['messages'] as List).map((e) => SupportReplyModel.fromJson(e)).toList(),
        };
      }
      throw Exception('Gagal memuat detail tiket');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Kesalahan jaringan');
    }
  }

  Future<bool> replyTicket(int ticketId, String message) async {
    try {
      final response = await _dio.post('/support/tickets/$ticketId/reply', data: {'message': message});
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> closeTicket(int ticketId) async {
    try {
      final response = await _dio.post('/support/tickets/$ticketId/close');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
