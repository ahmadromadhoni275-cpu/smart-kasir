class ProductModel {
  final int productId;
  final int? categoryId;      
  final String? categoryName; 
  final String sku; 
  final String name;
  final double sellingPrice;
  final double purchasePrice; // Penting untuk HPP transaksi
  final int stock;
  final String productType; // PRODUCT / SERVICE

  ProductModel({
    required this.productId,
    this.categoryId,
    this.categoryName,
    required this.sku,
    required this.name,
    required this.sellingPrice,
    required this.purchasePrice,
    required this.stock,
    required this.productType,
  });

  factory ProductModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ProductModel(productId: 0, sku: '', name: 'Unknown', sellingPrice: 0, purchasePrice: 0, stock: 0, productType: 'PRODUCT');
    
    return ProductModel(
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      categoryName: json['category_name']?.toString(),
      sku: json['sku']?.toString() ?? json['barcode']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Produk',
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
      purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? '0') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      productType: json['product_type']?.toString().toUpperCase() ?? 'PRODUCT',
    );
  }
}
