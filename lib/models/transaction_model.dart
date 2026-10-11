class PaymentDetail {
  final String method;
  final double amount;

  PaymentDetail({required this.method, required this.amount});

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      method: json['method'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
    );
  }
}

class TransactionReport {
  final int transactionId;
  final String invoiceNumber;
  final double grandTotal;
  final String paymentStatus;
  final String transactionStatus;
  final String createdAt;
  final int itemQty;
  final String cashierName;
  final List<PaymentDetail> payments;

  TransactionReport({
    required this.transactionId,
    required this.invoiceNumber,
    required this.grandTotal,
    required this.paymentStatus,
    required this.transactionStatus,
    required this.createdAt,
    required this.itemQty,
    required this.cashierName,
    required this.payments,
  });

  factory TransactionReport.fromJson(Map<String, dynamic> json) {
    return TransactionReport(
      transactionId: int.tryParse(json['transaction_id'].toString()) ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      grandTotal: double.tryParse(json['grand_total'].toString()) ?? 0.0,
      paymentStatus: json['payment_status'] ?? '',
      transactionStatus: json['transaction_status'] ?? '',
      createdAt: json['created_at'] ?? '',
      itemQty: int.tryParse(json['item_qty'].toString()) ?? 0,
      cashierName: json['cashier_name'] ?? 'Kasir',
      payments: (json['payments'] as List?)
              ?.map((item) => PaymentDetail.fromJson(item))
              .toList() ??
          [],
    );
  }
}
