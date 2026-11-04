class ProductModel {
  final int productId;
  final int? categoryId;      
  final String? categoryName; 
  final String sku; 
  final String? barcode;       // <-- TAMBAHAN
  final String name;
  final double sellingPrice;
  final double purchasePrice; 
  final int stock;
  final String? unit;          // <-- TAMBAHAN
  final String? image;         // <-- TAMBAHAN
  final String status;         // <-- TAMBAHAN
  final String productType; 

  ProductModel({
    required this.productId,
    this.categoryId,
    this.categoryName,
    required this.sku,
    this.barcode,
    required this.name,
    required this.sellingPrice,
    required this.purchasePrice,
    required this.stock,
    this.unit,
    this.image,
    required this.status,
    required this.productType,
  });

  factory ProductModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ProductModel(
        productId: 0, 
        sku: '', 
        name: 'Unknown', 
        sellingPrice: 0, 
        purchasePrice: 0, 
        stock: 0, 
        status: 'ACTIVE',
        productType: 'PRODUCT'
      );
    }
    
    return ProductModel(
      productId: int.tryParse(json['product_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      categoryId: json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null,
      categoryName: json['category_name']?.toString(),
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      name: json['name']?.toString() ?? 'Produk',
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
      purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? '0') ?? 0.0,
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      unit: json['unit']?.toString() ?? 'Pcs',
      image: json['image']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'ACTIVE',
      productType: json['product_type']?.toString().toUpperCase() ?? 'PRODUCT',
    );
  }
}
