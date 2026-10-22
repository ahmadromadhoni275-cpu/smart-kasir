import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/printer_job_model.dart';

class PrintJobService {
  // Ganti baseUrl sesuai dengan endpoint API backend Anda
  final String baseUrl = 'https://smartkasir.shop/api/print-jobs';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Mengambil daftar riwayat berdasarkan filter dan pencarian
  Future<List<PrinterJobModel>> getPrintJobs({
    required String storeId,
    String statusFilter = 'SEMUA',
    String searchQuery = '',
  }) async {
    final headers = await _getHeaders();
    
    // Membangun query parameters untuk request API
    Map<String, String> queryParams = {'store_id': storeId};
    if (statusFilter != 'SEMUA') queryParams['status'] = statusFilter;
    if (searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> resData = json.decode(response.body);
      final List<dynamic> listData = resData['data'] ?? [];
      return listData.map((e) => PrinterJobModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat riwayat cetak');
    }
  }

  /// Mengambil ringkasan jumlah (Total & Gagal)
  Future<Map<String, int>> getPrintSummary(String storeId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/summary?store_id=$storeId');
    
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> resData = json.decode(response.body);
      return {
        'total': resData['data']['total'] ?? 0,
        'failed': resData['data']['failed'] ?? 0,
      };
    } else {
      return {'total': 0, 'failed': 0};
    }
  }

  /// Meminta backend untuk mencoba cetak ulang via endpoint
  Future<void> retryPrintJob(String printJobId) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl/$printJobId/retry');

    final response = await http.post(uri, headers: headers);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final res = json.decode(response.body);
      throw Exception(res['message'] ?? 'Gagal mencoba cetak ulang');
    }
  }
}
