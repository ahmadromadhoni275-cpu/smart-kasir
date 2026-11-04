class ReturnItemDetail {
  final int returnItemId;
  final int returnId;
  final int transactionItemId;
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final double amount;
  final String? reason;

  ReturnItemDetail({
    required this.returnItemId,
    required this.returnId,
    required this.transactionItemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.amount,
    this.reason,
  });

  factory ReturnItemDetail.fromJson(Map<String, dynamic> json) {
    return ReturnItemDetail(
      returnItemId: int.tryParse(json['return_item_id']?.toString() ?? '0') ?? 0,
      returnId: int.tryParse(json['return_id']?.toString() ?? '0') ?? 0,
      transactionItemId: int.tryParse(json['transaction_item_id']?.toString() ?? '0') ?? 0,
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: json['product_name']?.toString() ?? 'Produk',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      reason: json['reason']?.toString(),
    );
  }
}
