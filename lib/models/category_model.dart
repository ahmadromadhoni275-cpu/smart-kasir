class Category {
  final int categoryId;
  final String name;
  final String status;
  final int productCount; 

  Category({
    required this.categoryId,
    required this.name,
    required this.status,
    this.productCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      name: json['name'] ?? '',
      status: json['status'] ?? 'ACTIVE',
      productCount: int.tryParse(json['product_count'].toString()) ?? 0,
    );
  }
}
