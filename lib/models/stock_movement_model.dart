class StockMovementModel {
  final int stockMovementId;
  final int productId;
  final String productName;
  final String sku;
  final String type; // IN, OUT, ADJUSTMENT, RETURN
  final int quantity;
  final int stockBefore;
  final int stockAfter;
  final String? referenceType;
  final String? note;
  final String? userName;
  final String createdAt;

  StockMovementModel({
    required this.stockMovementId,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.type,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    this.referenceType,
    this.note,
    this.userName,
    required this.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StockMovementModel(stockMovementId: 0, productId: 0, productName: '-', sku: '', type: 'IN', quantity: 0, stockBefore: 0, stockAfter: 0, createdAt: '');
    
    return StockMovementModel(
      stockMovementId: int.tryParse(json['stock_movement_id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? 'Produk',
      sku: json['sku']?.toString() ?? '',
      type: json['type']?.toString().toUpperCase() ?? 'IN',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      stockBefore: int.tryParse(json['stock_before']?.toString() ?? '0') ?? 0,
      stockAfter: int.tryParse(json['stock_after']?.toString() ?? '0') ?? 0,
      referenceType: json['reference_type']?.toString(),
      note: json['note']?.toString(),
      userName: json['user_name']?.toString() ?? 'Sistem',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
