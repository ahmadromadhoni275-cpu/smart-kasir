import 'package:dio/dio.dart';
import '../network/api_client.dart';

// --- MODEL PRODUK ---
class Product {
  final int id;
  final int? categoryId;      
  final String? categoryName; 
  final String sku; 
  final String name;
  final double sellingPrice;
  final int stock;
  final String? image;

  Product({
    required this.id,
    this.categoryId,
    this.categoryName,
    required this.sku,
    required this.name,
    required this.sellingPrice,
    required this.stock,
    this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      // Mengambil 'product_id' dari CI4, jika tidak ada fallback ke 'id'
      id: int.tryParse(json['product_id']?.toString() ?? json['id']?.toString() ?? '') ?? 0,
      
      // Data Kategori
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      categoryName: json['category_name']?.toString(),
      
      // Mengambil 'sku' atau 'barcode'
      sku: json['sku']?.toString() ?? json['barcode']?.toString() ?? '',
      
      name: json['name'] ?? '',
      
      // Mengambil 'selling_price' sesuai tabel CI4 Anda
      price: double.tryParse(json['selling_price']?.toString() ?? json['price']?.toString() ?? '') ?? 0.0,
      
      stock: int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      image: json['image']?.toString(),
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
