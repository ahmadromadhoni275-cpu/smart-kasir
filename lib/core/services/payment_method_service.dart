import 'dart:convert';
import 'api_service.dart'; // Pastikan ini mengarah ke file ApiService CI4 Anda

class PaymentMethodService {
  static Future<List<dynamic>> getPaymentMethods() async {
    final response = await ApiService.get('payment-methods');
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    throw Exception('Gagal memuat metode pembayaran');
  }

  static Future<void> savePaymentMethod(Map<String, dynamic> data, {int? id}) async {
    final response = id == null 
        ? await ApiService.post('payment-methods', data)
        : await ApiService.put('payment-methods/$id', data);
        
    final resData = json.decode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(resData['message'] ?? 'Gagal menyimpan metode pembayaran');
    }
  }

  static Future<void> toggleStatus(int id, String currentStatus) async {
    final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final response = await ApiService.patch('payment-methods/$id/status', {'status': newStatus});
    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah status metode pembayaran');
    }
  }
}
