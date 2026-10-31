import 'dart:convert';
import 'api_service.dart';

class StockService {
  // PERBAIKAN: Menambahkan > yang terhapus
  static Future> getSummary() async {
    final response = await ApiService.get('stock');
    if (response.statusCode == 200) {
      final resData = json.decode(response.body);
      // Mendukung 'success' ataupun true
      if (resData['status'] == 'success' || resData['status'] == true) { 
        return resData['data'];
      }
    }
    throw Exception('Gagal memuat ringkasan stok');
  }

  // 2. Daftar Produk untuk Stok
  static Future<List<dynamic>> getProducts({String search = ''}) async {
    // Pastikan endpoint ini sesuai dengan routes di CI4 (biasanya '/stock/products')
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

  // 3. Stok Masuk
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

  // 4. Penyesuaian Stok (Stock Opname)
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

  // 5. Riwayat Pergerakan
  static Future<List<dynamic>> getMovements({String type = '', int page = 1}) async {
    final response = await ApiService.get('stock/movements?type=$type&page=$page');
    if (response.statusCode == 200) {
      final resData = json.decode(response.body);
      // Mendukung 'success' ataupun true agar aman
      if (resData['status'] == 'success' || resData['status'] == true) {
         return resData['data'] ?? [];
      }
      throw Exception(resData['message'] ?? 'Gagal memuat riwayat stok');
    }
    throw Exception('Gagal menghubungi server');
  }
}
