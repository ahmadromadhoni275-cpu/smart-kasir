class ProductPerformanceItem {
  final int productId;
  final String productName;
  final String categoryName;
  final int qty;
  final double revenue;

  ProductPerformanceItem({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.qty,
    required this.revenue,
  });

  factory ProductPerformanceItem.fromJson(Map<String, dynamic> json) {
    return ProductPerformanceItem(
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? 'Produk Tidak Diketahui',
      categoryName: json['category_name']?.toString() ?? 'Tanpa Kategori',
      qty: int.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      revenue: double.tryParse(json['revenue']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class CategoryPerformanceItem {
  final String categoryName;
  final int qty;
  final double revenue;

  CategoryPerformanceItem({
    required this.categoryName,
    required this.qty,
    required this.revenue,
  });

  factory CategoryPerformanceItem.fromJson(Map<String, dynamic> json) {
    return CategoryPerformanceItem(
      categoryName: json['category_name']?.toString() ?? 'Tanpa Kategori',
      qty: int.tryParse(json['qty']?.toString() ?? '0') ?? 0,
      revenue: double.tryParse(json['revenue']?.toString() ?? '0') ?? 0.0,
    );
  }
}
