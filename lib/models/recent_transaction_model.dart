class RecentTransactionModel {
  final int transactionId;
  final String invoiceNumber;
  final double grandTotal;
  final String transactionStatus;
  final String paymentStatus;
  final String createdAt;
  final String paymentMethod;

  RecentTransactionModel({
    required this.transactionId,
    required this.invoiceNumber,
    required this.grandTotal,
    required this.transactionStatus,
    required this.paymentStatus,
    required this.createdAt,
    required this.paymentMethod,
  });

  factory RecentTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecentTransactionModel(
      transactionId: int.tryParse(json['transaction_id']?.toString() ?? '0') ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '-',
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0,
      transactionStatus: json['transaction_status']?.toString() ?? 'COMPLETED',
      paymentStatus: json['payment_status']?.toString() ?? 'UNPAID',
      createdAt: json['created_at']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'CASH',
    );
  }
}
