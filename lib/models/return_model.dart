class ReturnItem {
  final int transactionItemId;
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final int returnableQuantity;

  ReturnItem({
    required this.transactionItemId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.returnableQuantity,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      transactionItemId: int.tryParse(json['transaction_item_id'].toString()) ?? 0,
      productId: int.tryParse(json['product_id'].toString()) ?? 0,
      productName: json['product_name'] ?? json['name'] ?? 'Produk',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      returnableQuantity: int.tryParse(json['returnable_quantity'].toString()) ?? 0,
    );
  }
}

class ReturnData {
  final int returnId;
  final int transactionId;
  final String returnNumber;
  final String invoiceNumber;
  final String cashierName;
  final double totalAmount;
  final String refundMethod;
  final String refundStatus;
  final String createdAt;
  final int itemCount;

  ReturnData({
    required this.returnId,
    required this.transactionId,
    required this.returnNumber,
    required this.invoiceNumber,
    required this.cashierName,
    required this.totalAmount,
    required this.refundMethod,
    required this.refundStatus,
    required this.createdAt,
    required this.itemCount,
  });

  factory ReturnData.fromJson(Map<String, dynamic> json) {
    return ReturnData(
      returnId: int.tryParse(json['return_id'].toString()) ?? 0,
      transactionId: int.tryParse(json['transaction_id'].toString()) ?? 0,
      returnNumber: json['return_number'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      cashierName: json['cashier_name'] ?? 'Kasir',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      refundMethod: json['refund_method'] ?? '',
      refundStatus: json['refund_status'] ?? '',
      createdAt: json['created_at'] ?? '',
      itemCount: int.tryParse(json['item_count'].toString()) ?? 0,
    );
  }
}
