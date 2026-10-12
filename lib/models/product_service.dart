import 'package:dio/dio.dart';
import '../network/api_client.dart';

// --- MODEL PRODUK ---
class Product {
  final int id;
  final String sku; // Kode Barang / Barcode
  final String name;
  final double price;
  final int stock;
  final String? image;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.stock,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['id'].toString()) ?? 0,
      sku: json['sku']?.toString() ?? '',
      name: json['name'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      image: json['image'],
    );
  }
}

// --- SERVICE PRODUK ---
class ProductService {
  final Dio _dio = ApiClient().dio;

  // 1. Ambil Daftar Produk
  Future<List<Product>> getProducts({String search = ''}) async {
    try {
      final response = await _dio.get('/products', queryParameters: {'search': search});
      if (response.statusCode == 200) {
        List data = response.data['data'] ?? [];
        return data.map((e) => Product.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Gagal memuat produk');
    }
  }

  // 2. Tambah Produk Baru
  Future<void> createProduct(Map<String, dynamic> data) async {
    try {
      await _dio.post('/products', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menambah produk');
    }
  }

  // 3. Update Produk
  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/products/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal mengubah produk');
    }
  }

  // 4. Hapus Produk
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete('/products/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Gagal menghapus produk');
    }
  }
}
