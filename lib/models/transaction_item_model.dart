class TransactionItemModel {
  final int? productId; // Nullable untuk jasa manual
  final String itemType; // PRODUCT / SERVICE
  final String name;
  final double price;
  final double purchasePrice;
  int quantity;
  final int maxStock;
  String orderType; // DINE_IN / TAKEAWAY
  String? note;

  TransactionItemModel({
    this.productId,
    required this.itemType,
    required this.name,
    required this.price,
    required this.purchasePrice,
    required this.quantity,
    required this.maxStock,
    this.orderType = 'DINE_IN',
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'item_type': itemType,
      'name': name,
      'price': price,
      'purchase_price': purchasePrice,
      'quantity': quantity,
      'order_type': orderType,
      'note': note,
    };
  }
}
