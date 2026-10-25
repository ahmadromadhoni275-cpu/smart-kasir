import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SupportApiService {
  // Ganti dengan Base URL CI4 Anda
  final String baseUrl = 'https://smartkasir.shop/api/support'; 

  // Helper untuk mendapatkan token JWT
  Future<Map<String, String>> _getHeaders() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // String token = prefs.getString('jwt_token') ?? '';
    String token = 'TOKEN_JWT_DARI_LOGIN'; // TODO: Ambil dari storage aktual
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Dapatkan daftar percakapan aktif
  Future<List<dynamic>> getConversations() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/conversations'), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    }
    throw Exception('Gagal memuat percakapan');
  }

  // 2. Buat sesi percakapan baru
  Future<int> startConversation() async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/conversations'), headers: headers);

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['conversation_id'];
    }
    throw Exception('Gagal membuat percakapan baru');
  }

  // 3. Ambil riwayat chat berdasarkan ID percakapan
  Future<List<dynamic>> getMessages(int conversationId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/conversations/$conversationId/messages'), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'] ?? [];
    }
    throw Exception('Gagal memuat riwayat pesan');
  }

  // 4. Kirim pesan ke AI dan tunggu balasan
  Future<Map<String, dynamic>> sendMessage(int conversationId, String text) async {
    final headers = await _getHeaders();
    final body = jsonEncode({'message': text});

    final response = await http.post(
      Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data']; // Berisi pesan dari AI
    }
    throw Exception('Gagal mengirim pesan');
  }

  // 5. Kirim Feedback (Jempol)
  Future<bool> submitFeedback(int messageId, int rating, {String comment = ''}) async {
    final headers = await _getHeaders();
    final body = jsonEncode({'rating': rating, 'comment': comment});

    final response = await http.post(
      Uri.parse('$baseUrl/messages/$messageId/feedback'),
      headers: headers,
      body: body,
    );

    return response.statusCode == 200;
  }
  // --- TIKET BANTUAN ---

  Future<List<dynamic>> getTickets() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/tickets'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'] ?? [];
    throw Exception('Gagal memuat tiket');
  }

  Future<int> createTicket(String subject, String description, String priority) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/tickets'),
      headers: headers,
      body: jsonEncode({'subject': subject, 'description': description, 'priority': priority}),
    );
    if (response.statusCode == 201) return jsonDecode(response.body)['ticket_id'];
    throw Exception('Gagal membuat tiket');
  }

  Future<Map<String, dynamic>> getTicketDetail(int ticketId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/tickets/$ticketId'), headers: headers);
    if (response.statusCode == 200) return jsonDecode(response.body)['data'];
    throw Exception('Gagal memuat detail tiket');
  }

  Future<bool> replyTicket(int ticketId, String message) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/tickets/$ticketId/reply'),
      headers: headers,
      body: jsonEncode({'message': message}),
    );
    return response.statusCode == 201;
  }
  
}
