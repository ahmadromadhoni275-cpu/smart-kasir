class BestSellingProductModel {
  final int productId;
  final String name;
  final int soldQuantity;

  BestSellingProductModel({
    required this.productId,
    required this.name,
    required this.soldQuantity,
  });

  factory BestSellingProductModel.fromJson(Map<String, dynamic> json) {
    return BestSellingProductModel(
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '-',
      soldQuantity: int.tryParse(json['jumlah_terjual']?.toString() ?? '0') ?? 0,
    );
  }
}
