class CurrentStockItem {
  final int productId;
  final String productName;
  final String sku;
  final String categoryName;
  final int stock;
  final int minStock;
  final String unit;

  CurrentStockItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.categoryName,
    required this.stock,
    required this.minStock,
    required this.unit,
  });

  factory CurrentStockItem.fromJson(Map<String, dynamic> json) {
    return CurrentStockItem(
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? 'Produk Tidak Diketahui',
      sku: json['sku']?.toString() ?? '-',
      categoryName: json['category_name']?.toString() ?? 'Umum',
      stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      minStock: int.tryParse(json['min_stock']?.toString() ?? '0') ?? 0,
      unit: json['unit']?.toString() ?? 'Pcs',
    );
  }

  bool get isLowStock => stock <= minStock;
  bool get isOutOfStock => stock <= 0;
}

class StockMovementItem {
  final int movementId;
  final int productId;
  final String productName;
  final String type; // IN, OUT, ADJUSTMENT, RETURN
  final int quantity;
  final int stockBefore;
  final int stockAfter;
  final String referenceType;
  final String userName;
  final String createdAt;

  StockMovementItem({
    required this.movementId,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    required this.referenceType,
    required this.userName,
    required this.createdAt,
  });

  factory StockMovementItem.fromJson(Map<String, dynamic> json) {
    return StockMovementItem(
      movementId: int.tryParse(json['stock_movement_id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? 'Produk Tidak Diketahui',
      type: json['type']?.toString().toUpperCase() ?? 'ADJUSTMENT',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      stockBefore: int.tryParse(json['stock_before']?.toString() ?? '0') ?? 0,
      stockAfter: int.tryParse(json['stock_after']?.toString() ?? '0') ?? 0,
      referenceType: json['reference_type']?.toString().replaceAll('_', ' ') ?? '-',
      userName: json['user_name']?.toString() ?? 'Sistem',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
