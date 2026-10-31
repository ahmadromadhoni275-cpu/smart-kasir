import 'dart:convert';
import 'api_service.dart';

class StockService {
  // PERBAIKAN: Menggunakan dynamic
  static Future<dynamic> getSummary() async {
    final response = await ApiService.get('stock');
    if (response.statusCode == 200) {
      final resData = json.decode(response.body);
      if (resData['status'] == 'success' || resData['status'] == true) { 
        return resData['data'];
      }
    }
    throw Exception('Gagal memuat ringkasan stok');
  }

  static Future<List<dynamic>> getProducts({String search = ''}) async {
    final response = await ApiService.get('stock/products?search=$search');
    
    if (response.statusCode == 200) {
      final resData = json.decode(response.body);
      if (resData['status'] == 'success' || resData['status'] == true) {
        return resData['data'] ?? [];
      }
      throw Exception(resData['message'] ?? 'Format data produk tidak valid');
    } else {
      throw Exception('Error Server: ${response.statusCode}');
    }
  }

  static Future<void> stockIn(int productId, int quantity, String note) async {
    final response = await ApiService.post('stock/in', {
      'product_id': productId,
      'quantity': quantity,
      'note': note,
    });
    
    final resData = json.decode(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(resData['message'] ?? 'Gagal mencatat stok masuk');
    }
  }

  static Future<void> adjustStock(int productId, int actualStock, String note) async {
    final response = await ApiService.post('stock/adjustment', {
      'product_id': productId,
      'actual_stock': actualStock,
      'note': note,
    });

    final resData = json.decode(response.body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(resData['message'] ?? 'Gagal menyesuaikan stok');
    }
  }

  static Future<List<dynamic>> getMovements({String type = '', int page = 1}) async {
    final response = await ApiService.get('stock/movements?type=$type&page=$page');
    if (response.statusCode == 200) {
      final resData = json.decode(response.body);
      if (resData['status'] == 'success' || resData['status'] == true) {
         return resData['data'] ?? [];
      }
      throw Exception(resData['message'] ?? 'Gagal memuat riwayat stok');
    }
    throw Exception('Gagal menghubungi server');
  }
}
